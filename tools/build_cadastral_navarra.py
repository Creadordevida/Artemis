#!/usr/bin/env python3
"""Build a Navarra-wide cadastral street overview without WFS pagination.

Official CC BY 4.0 shapefiles, explicitly NOT a pedestrian routing graph.
Only source-published street axes and labels; no fabricated paths or addresses.
"""
import hashlib
import io
import json
import zipfile
from datetime import datetime, timezone
from pathlib import Path

import shapefile
from pyproj import CRS, Transformer
from shapely.geometry import LineString

from build_offline_navarra import fetch, BOUNDS

BASE = "https://filescartografia.navarra.es/2_CARTOGRAFIA_TEMATICA/2_7_CATASTRO/2_7_1_SHAPEFILE/"
SOURCES = {
    "cadastral_streets": BASE + "CATAST_Lin_CalleEje.zip",
    "cadastral_labels": BASE + "CATAST_Txt_Calle.zip",
}
OUT = Path("build/cadastral-streets")
MAX_LINES = 130_000
MAX_LABELS = 60_000
MAX_OUTPUT_BYTES = 20_000_000
SIMPLIFICATION_METERS = 6
TO_GPS = Transformer.from_crs("EPSG:25830", "EPSG:4326", always_xy=True)


def reader_from_zip(data: bytes):
    package = zipfile.ZipFile(io.BytesIO(data))
    names = package.namelist()
    shp = next((n for n in names if n.lower().endswith(".shp")), None)
    if not shp:
        raise ValueError("Official ZIP contains no SHP")
    stem = shp[:-4]

    def part(suffix):
        path = next((n for n in names if n.lower() == (stem + suffix).lower()), None)
        if path is None:
            raise ValueError(f"Missing {suffix} in source ZIP")
        return io.BytesIO(package.read(path))

    prj = CRS.from_wkt(part(".prj").read().decode("utf-8-sig", "replace"))
    if prj.to_epsg() != 25830:
        raise ValueError(f"Unexpected source CRS: {prj}")
    cpg = next((n for n in names if n.lower() == (stem + ".cpg").lower()), None)
    encoding = package.read(cpg).decode("ascii", "ignore").strip() if cpg else "cp1252"
    if encoding.upper() in ("ANSI 1252", "WINDOWS-1252"):
        encoding = "cp1252"
    reader = shapefile.Reader(shp=part(".shp"), shx=part(".shx"), dbf=part(".dbf"),
                             encoding=encoding)
    return package, reader


def gps(x, y):
    lon, lat = TO_GPS.transform(x, y)
    if not (BOUNDS[0] <= lon <= BOUNDS[2] and BOUNDS[1] <= lat <= BOUNDS[3]):
        raise ValueError(f"Out-of-area cadastral coordinate {lat}, {lon}")
    return [round(lat, 5), round(lon, 5)]


def convert_lines(reader):
    lines = []
    for shape in reader.iterShapes():
        if shape.shapeType not in (3, 13, 23):  # polylines, optionally Z/M
            raise ValueError(f"Unexpected cadastral street geometry: {shape.shapeType}")
        parts = list(shape.parts) + [len(shape.points)]
        for i in range(len(parts) - 1):
            vertices = shape.points[parts[i]:parts[i+1]]
            if len(vertices) < 2:
                continue
            geom = LineString(vertices).simplify(SIMPLIFICATION_METERS, preserve_topology=False)
            if geom.is_empty or geom.geom_type != "LineString":
                continue
            converted = []
            for x, y in geom.coords:
                point = gps(x, y)
                if not converted or converted[-1] != point:
                    converted.append(point)
            if len(converted) >= 2:
                lines.append(converted)
            if len(lines) > MAX_LINES:
                raise ValueError("Source line count exceeds reviewed threshold")
    if len(lines) < 20000:
        raise ValueError("Cadastral street dataset unexpectedly small")
    return lines


def convert_labels(reader):
    labels = []
    available_fields = [item[0] for item in reader.fields[1:]]
    print("Cadastral label source fields:", available_fields)
    for item in reader.iterShapeRecords():
        shape = item.shape
        if shape.shapeType not in (1, 11, 21):
            raise ValueError(f"Unexpected label geometry: {shape.shapeType}")
        if not shape.points:
            continue
        properties = item.record.as_dict()
        name = str(properties.get("CADTEXT") or properties.get("VIA")
                   or properties.get("ETIQUETA") or "").strip()
        if not name or len(name) > 100:
            continue
        lat, lon = gps(*shape.points[0])
        labels.append({"text": name, "lat": lat, "lon": lon})
        if len(labels) > MAX_LABELS:
            raise ValueError("Source label count exceeds reviewed threshold")
    if len(labels) < 5000:
        raise ValueError("Official label data empty or source schema changed")
    return labels


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    records = {}
    provenance = []
    for kind, url in SOURCES.items():
        raw = fetch(url)
        package, reader = reader_from_zip(raw)
        try:
            records[kind] = (convert_lines(reader) if kind == "cadastral_streets"
                             else convert_labels(reader))
        finally:
            package.close()
        provenance.append({
            "category": kind, "url": url,
            "bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest(),
            "output_records": len(records[kind]),
        })
    obj = {
        "streets": records["cadastral_streets"],
        "paths": [],
        "labels": records["cadastral_labels"],
    }
    encoded = json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    if len(encoded) > MAX_OUTPUT_BYTES:
        raise ValueError("Cadastral map data exceeds size budget")
    (OUT / "navarra_cadastral_streets.json").write_bytes(encoded)
    meta = {
        "source": "Gobierno de Navarra / Catastro / IDENA",
        "license": "CC BY 4.0",
        "retrieved_utc": datetime.now(timezone.utc).isoformat(),
        "coverage": "cadastral street axes, not walking routes",
        "crs": "EPSG:25830 transformed to WGS84",
        "simplification_meters": SIMPLIFICATION_METERS,
        "sources": provenance,
        "output_bytes": len(encoded),
        "sha256_output": hashlib.sha256(encoded).hexdigest(),
        "limitations": "not navigation; entrances, walkability, street accessibility unknown",
    }
    (OUT / "navarra_cadastral_manifest.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(meta, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
