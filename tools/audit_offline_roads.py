#!/usr/bin/env python3
"""Audit the official Navarra road-axis vectors for an offline basemap pipeline.

No mass downloading of tile.openstreetmap.org, no routing promise, no GPS.
The full source is official Navarra public geodata CC BY 4.0.
"""
import hashlib
import io
import json
import zipfile

import shapefile
from pyproj import CRS, Transformer

from build_offline_navarra import fetch

URL = "https://idena.navarra.es/descargas/INFRAE_Lin_CtraEje.zip"


def main():
    raw = fetch(URL)
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        entries = z.namelist()
        shp = next((name for name in entries if name.lower().endswith(".shp")), None)
        if shp is None:
            raise ValueError("No vector road shapefile")
        stem = shp[:-4]

        def part(ext):
            name = next((n for n in entries if n.lower() == (stem + ext).lower()), None)
            if name is None:
                raise ValueError(f"Missing {ext}")
            return io.BytesIO(z.read(name))

        crs = CRS.from_wkt(part(".prj").read().decode("utf-8-sig", errors="replace"))
        to_wgs = Transformer.from_crs(crs, CRS.from_epsg(4326), always_xy=True)
        cpg = next((n for n in entries if n.lower() == (stem + ".cpg").lower()), None)
        enc = z.read(cpg).decode("ascii", "ignore").strip() if cpg else "cp1252"
        if enc.upper() in ("ANSI 1252", "WINDOWS-1252"):
            enc = "cp1252"
        reader = shapefile.Reader(shp=part(".shp"), shx=part(".shx"), dbf=part(".dbf"),
                                  encoding=enc)
        count = 0
        vertices = 0
        bounds = []
        types = set()
        for shape in reader.iterShapes():
            count += 1
            vertices += len(shape.points)
            types.add(shape.shapeTypeName)
            if not shape.points:
                continue
            bounds.append(to_wgs.transform(shape.points[0][0], shape.points[0][1]))
        if count < 50:
            raise ValueError("Road dataset suspiciously small")
        report = {
            "source": URL,
            "license": "CC BY 4.0",
            "sha256": hashlib.sha256(raw).hexdigest(),
            "zip_bytes": len(raw),
            "shape_types": sorted(types),
            "segments": count,
            "vertices": vertices,
            "fields": [f[0] for f in reader.fields[1:]],
            "sample_first_coordinates": bounds[:3],
            "status": "road_axis_audited_not_navigable_or_rendered",
        }
        print(json.dumps(report, ensure_ascii=False, indent=2))
        with open("build/official_roads_audit.json", "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    from pathlib import Path
    Path("build").mkdir(exist_ok=True)
    main()
