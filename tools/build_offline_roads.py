#!/usr/bin/env python3
"""Build a lightweight OFFLINE road overview from Navarra's official GIS.

Source: IDENA road axis shapefile (CC BY 4.0), EPSG:25830.
Output is line geometry ONLY: it neither supports walking directions nor
contains rural footpaths, all urban streets, safe crossings or live closures.
Do not infer accessibility, connectivity or navigability.
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

URL = "https://idena.navarra.es/descargas/INFRAE_Lin_CtraEje.zip"
OUT = Path("build/offline-roads")
# 15 m simplification for map overview at regional / town scale; never routes.
SIMPLIFY_METERS = 15
MAX_LINES = 30000
MAX_JSON_BYTES = 7000000


def build():
    raw = fetch(URL)
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        files = z.namelist()
        shp_path = next((n for n in files if n.lower().endswith(".shp")), None)
        if shp_path is None:
            raise ValueError("Source lacks .shp")
        stem = shp_path[:-4]
        def read_part(extension):
            name = next((n for n in files if n.lower() == (stem + extension).lower()), None)
            if name is None:
                raise ValueError(f"Missing {extension}")
            return io.BytesIO(z.read(name))
        crs = CRS.from_wkt(read_part(".prj").read().decode("utf-8-sig", errors="replace"))
        if crs.to_epsg() != 25830:
            raise ValueError(f"Unexpected CRS: {crs}")
        transformer = Transformer.from_crs(crs, CRS.from_epsg(4326), always_xy=True)
        cpg = next((n for n in files if n.lower() == (stem + ".cpg").lower()), None)
        enc = z.read(cpg).decode("ascii", "ignore").strip() if cpg else "cp1252"
        if enc.upper() in ("ANSI 1252", "WINDOWS-1252"):
            enc = "cp1252"
        r = shapefile.Reader(
            shp=read_part(".shp"), shx=read_part(".shx"), dbf=read_part(".dbf"),
            encoding=enc,
        )
        features = []
        count_in = 0
        count_out = 0
        for item in r.iterShapeRecords():
            shape = item.shape
            count_in += 1
            if len(shape.points) < 2:
                continue
            parts = list(shape.parts) + [len(shape.points)]
            for i in range(len(parts) - 1):
                pts = shape.points[parts[i]:parts[i + 1]]
                if len(pts) < 2:
                    continue
                simplified = LineString(pts).simplify(SIMPLIFY_METERS, preserve_topology=False)
                if simplified.is_empty or simplified.geom_type != "LineString":
                    continue
                converted = []
                for x, y in simplified.coords:
                    lon, lat = transformer.transform(x, y)
                    if not (BOUNDS[0] <= lon <= BOUNDS[2] and BOUNDS[1] <= lat <= BOUNDS[3]):
                        raise ValueError(f"Out-of-area road vertex: {lat},{lon}")
                    value = [round(lat, 5), round(lon, 5)]
                    if not converted or converted[-1] != value:
                        converted.append(value)
                if len(converted) >= 2:
                    features.append(converted)
                    count_out += 1
                if count_out > MAX_LINES:
                    raise ValueError("Road feature count above limit")
        if len(features) < 1000:
            raise ValueError("Too few roads; check source mapping")
        payload = json.dumps(features, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        if len(payload) > MAX_JSON_BYTES:
            raise ValueError(f"Road package exceeds {MAX_JSON_BYTES} bytes")
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / "navarra_road_lines.json").write_bytes(payload)
        metadata = {
            "source": URL,
            "provider": "SITNA / IDENA - Gobierno de Navarra",
            "license": "CC BY 4.0",
            "sha256_raw_source": hashlib.sha256(raw).hexdigest(),
            "sha256_pack": hashlib.sha256(payload).hexdigest(),
            "created_utc": datetime.now(timezone.utc).isoformat(),
            "source_features": count_in,
            "output_lines": count_out,
            "simplification_meters": SIMPLIFY_METERS,
            "output_bytes": len(payload),
            "coordinates": "[latitude,longitude] WGS84",
            "limitations": "road axes only; no footpaths, no all streets, no routes, no accessibility",
        }
        (OUT / "navarra_road_manifest.json").write_text(
            json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8",
        )
        print(json.dumps(metadata, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    build()
