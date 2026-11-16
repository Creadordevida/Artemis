#!/usr/bin/env python3
"""Prepare auditable offline data packs from official Navarra datasets.

This is a build-time tool, NOT a live emergency feed. Geometry is only an
approximate facility point until a human verifies the public entrance.
"""
import argparse
import csv
import hashlib
import io
import json
import re
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path

import shapefile
from pyproj import CRS, Transformer

SOURCES = {
    "policia_foral": "https://idena.navarra.es/descargas/DOTACI_Sym_PFOficinas.zip",
    "guardia_civil": "https://idena.navarra.es/descargas/DOTACI_Sym_GCivil.zip",
    "centros_sanitarios": "https://datosabiertos.navarra.es/dataset/c87d1546-0396-4e17-8b99-762d77d28503/resource/f1fc5b52-be72-4088-8cb1-772076e2071c/download/centrossanitarios.csv",
}
LICENSE = "CC BY 4.0; verificar atribución concreta del conjunto antes de distribuir"
BOUNDS = (-2.8, 41.6, -0.55, 43.5)  # only sanity checks, not Navarra boundary
MAX_BYTES = 30 * 1024 * 1024


def fetch(url: str) -> bytes:
    with urllib.request.urlopen(
        urllib.request.Request(url, headers={"User-Agent": "Artemis-Data-Importer/0.1"}),
        timeout=45,
    ) as response:
        data = response.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise ValueError("Data resource exceeds maximum allowed size")
    if not data:
        raise ValueError("Empty source file")
    return data


def normalized(value):
    if value is None:
        return ""
    return str(value).strip()


def label_from_properties(properties: dict) -> str:
    fields = ("NOMBRE", "DENOMINACI", "DENOMINACION", "NOM", "NAME",
              "DESCRIPCIO", "DESCRIPCION", "ROTULO", "ETIQUETA")
    lookup = {str(k).upper(): normalized(v) for k, v in properties.items()}
    for key in fields:
        if lookup.get(key):
            return lookup[key]
    for key, value in lookup.items():
        if (key.startswith("NOM") or key.startswith("DENOM")) and value:
            return value
    # Absence of a human-readable name is a blocker, not a license to invent one.
    raise ValueError("No usable name field found in official geodata")


def spatial_points(data: bytes, category: str, source: str):
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        names = z.namelist()
        shp = next((n for n in names if n.lower().endswith(".shp")), None)
        if not shp:
            raise ValueError("No .shp file in official ZIP")
        stem = shp[:-4]
        def part(ext):
            match = next((n for n in names if n.lower() == (stem + ext).lower()), None)
            if match is None:
                raise ValueError(f"Missing {ext}")
            return io.BytesIO(z.read(match))
        prj = next((n for n in names if n.lower() == (stem + ".prj").lower()), None)
        if prj is None:
            raise ValueError("Source lacks CRS .prj; cannot georeference safely")
        crs = CRS.from_wkt(z.read(prj).decode("utf-8-sig", errors="replace"))
        convert = Transformer.from_crs(crs, CRS.from_epsg(4326), always_xy=True)
        reader = shapefile.Reader(shp=part(".shp"), shx=part(".shx"), dbf=part(".dbf"))
        result = []
        for index, item in enumerate(reader.iterShapeRecords()):
            props = item.record.as_dict()
            shape = item.shape
            if not shape.points:
                continue
            # Point location or bounding-box centre. Not necessarily an entrance.
            left, bottom, right, top = shape.bbox if hasattr(shape, "bbox") and shape.bbox else (
                shape.points[0][0], shape.points[0][1],
                shape.points[0][0], shape.points[0][1]
            )
            lon, lat = convert.transform((left + right) / 2, (bottom + top) / 2)
            if not (BOUNDS[0] <= lon <= BOUNDS[2] and BOUNDS[1] <= lat <= BOUNDS[3]):
                raise ValueError(f"Point outside Navarra vicinity: {lon}, {lat}")
            title = label_from_properties(props)
            result.append({
                "id": f"{category}-{index + 1}",
                "name": title,
                "category": category,
                "lat": round(lat, 6),
                "lon": round(lon, 6),
                "location_quality": "approximate_facility_geometry",
                "validated_entrance": False,
                "hours": None,
                "phone": None,
                "source": source,
            })
        if not result:
            raise ValueError(f"Empty feature set: {category}")
        return result


def health_rows(data: bytes, source: str):
    decoded = data.decode("utf-8-sig")
    reader = csv.DictReader(io.StringIO(decoded), delimiter=";") if decoded.splitlines()[0].count(";") > decoded.splitlines()[0].count(",") else csv.DictReader(io.StringIO(decoded))
    rows = []
    for index, raw in enumerate(reader):
        fields = {re.sub(r"\\s+", " ", k or "").strip().lower(): normalized(v) for k, v in raw.items()}
        def pick(*candidates):
            for k, v in fields.items():
                if any(c in k for c in candidates) and v:
                    return v
            return ""
        name = pick("nombre centro", "nombre del centro")
        if not name:
            continue
        rows.append({
            "id": pick("codigo centro") or f"sanitario-{index + 1}",
            "name": name,
            "category": "centro_sanitario",
            "address": pick("domicilio", "dirección", "direccion"),
            "municipality": pick("localidad"),
            "postal_code": pick("codigo postal"),
            "phone": pick("telefono", "teléfono") or None,
            "type": pick("tipo de centro"),
            "lat": None,
            "lon": None,
            "location_quality": "not_geocoded",
            "validated_entrance": False,
            "hours": None,
            "source": source,
        })
    if not rows:
        raise ValueError("Health data schema unrecognized: no rows produced")
    return rows


def build(out: Path, downloader=fetch):
    out.mkdir(parents=True, exist_ok=True)
    manifest = {
        "schema": 1, "region": "Navarra",
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "license_notice": LICENSE, "sources": [],
    }
    combined = []
    for category, url in SOURCES.items():
        raw = downloader(url)
        rows = health_rows(raw, url) if category == "centros_sanitarios" else spatial_points(raw, category, url)
        combined.extend(rows)
        manifest["sources"].append({
            "category": category, "url": url,
            "sha256": hashlib.sha256(raw).hexdigest(), "record_count": len(rows)
        })
    (out / "navarra_resources.json").write_text(
        json.dumps(combined, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )
    (out / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps({"total": len(combined), "sources": manifest["sources"]}, ensure_ascii=False))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="build/offline-data")
    args = parser.parse_args()
    build(Path(args.output))
