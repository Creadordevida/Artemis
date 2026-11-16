#!/usr/bin/env python3
"""Extract public SNS-O point geometries from IDENA into a review-only dataset.

The source is an official public-health layer. No private clinics, third-party
geocoding, fabricated coordinates, inferred entrances or verified opening hours.
"""
import hashlib
import io
import json
import zipfile
from pathlib import Path

import shapefile
from pyproj import CRS, Transformer

from build_offline_navarra import fetch, label_from_properties, normalized, BOUNDS

PUBLIC_LAYERS = {
    "primary": "https://idena.navarra.es/descargas/DOTACI_Sym_SNSPrimaria.zip",
    "mental_health": "https://idena.navarra.es/descargas/DOTACI_Sym_SNSMental.zip",
    "sexual_health": "https://idena.navarra.es/descargas/DOTACI_Sym_SNSMujer.zip",
}


def read_points(data: bytes, kind: str, source: str):
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        names = z.namelist()
        shp = next((x for x in names if x.lower().endswith(".shp")), None)
        if shp is None:
            raise ValueError(f"{kind}: no shapefile found")
        stem = shp[:-4]

        def part(suffix):
            path = next((n for n in names if n.casefold() == (stem + suffix).casefold()), None)
            if path is None:
                raise ValueError(f"{kind}: missing {suffix}")
            return io.BytesIO(z.read(path))

        crs = CRS.from_wkt(part(".prj").read().decode("utf-8-sig", errors="replace"))
        transformer = Transformer.from_crs(crs, CRS.from_epsg(4326), always_xy=True)
        cpg = next((n for n in names if n.casefold() == (stem + ".cpg").casefold()), None)
        enc = z.read(cpg).decode("ascii", "ignore").strip() if cpg else "cp1252"
        if enc.upper() in ("ANSI 1252", "WINDOWS-1252"):
            enc = "cp1252"
        reader = shapefile.Reader(
            shp=part(".shp"), shx=part(".shx"), dbf=part(".dbf"), encoding=enc
        )
        rows = []
        fields = [f[0] for f in reader.fields[1:]]
        print(f"Layer {kind} official fields: {fields}")
        for index, item in enumerate(reader.iterShapeRecords()):
            if not item.shape.points:
                continue
            p = item.record.as_dict()
            name = label_from_properties(p)
            if item.shape.shapeType not in (1, 11, 21):  # only actual point geometries
                raise ValueError(f"{kind}: expected point, got type {item.shape.shapeType}")
            x, y = item.shape.points[0]
            lon, lat = transformer.transform(x, y)
            if not (BOUNDS[0] <= lon <= BOUNDS[2] and BOUNDS[1] <= lat <= BOUNDS[3]):
                raise ValueError(f"{kind}: outside Navarra bounds")
            fields_upper = {k.upper(): normalized(v) for k, v in p.items()}
            rows.append({
                "id": f"sns-idena-{kind}-{index + 1}",
                "name": name,
                "category": "centro_sanitario",
                "type": {
                    "primary": "Atención primaria pública",
                    "mental_health": "Salud mental pública",
                    "sexual_health": "Atención sexual y reproductiva pública",
                }[kind],
                "lat": round(lat, 6),
                "lon": round(lon, 6),
                "location_quality": "official_idena_facility_point_not_entrance",
                "public_ownership_verified": True,
                "address": fields_upper.get("DIRECCION", ""),
                "municipality": fields_upper.get("LOCALIDAD", fields_upper.get("POBLACION", "")),
                "phone": fields_upper.get("TELEFONO") or None,
                "source": source,
                "hours": None,
                "emergency_service_confirmed": False,
            })
        if not rows:
            raise ValueError(f"{kind}: no usable public points")
        return rows


def main():
    out = Path("build/official-health-points")
    out.mkdir(parents=True, exist_ok=True)
    all_points = []
    manifest = {"data_class": "official_sns_location_points", "sources": []}
    for kind, url in PUBLIC_LAYERS.items():
        data = fetch(url)
        rows = read_points(data, kind, url)
        all_points.extend(rows)
        manifest["sources"].append({
            "type": kind,
            "url": url,
            "sha256": hashlib.sha256(data).hexdigest(),
            "count": len(rows),
        })
    (out / "navarra_sns_geo.json").write_text(
        json.dumps(all_points, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    (out / "geo_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("OFFICIAL PUBLIC SNS POINTS:", len(all_points))
    print(json.dumps(manifest, ensure_ascii=False))


if __name__ == "__main__":
    main()
