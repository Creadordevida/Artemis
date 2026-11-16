#!/usr/bin/env python3
"""Validate Geofabrik Navarra Shortbread MBTiles for future offline renderer.

Never treat a successful download as proof that this map is fully readable
in Android. This probes metadata, SQLite structure, zoom coverage and layers.
"""
import gzip
import hashlib
import json
import sqlite3
import sys
from pathlib import Path

import mapbox_vector_tile

p = Path(sys.argv[1])
if not p.is_file() or p.stat().st_size < 1_000_000:
    raise SystemExit("Tile archive missing or unexpectedly small")
sha = hashlib.sha256(p.read_bytes()).hexdigest()
connection = sqlite3.connect(f"file:{p}?mode=ro", uri=True)
tables = {row[0] for row in connection.execute("SELECT name FROM sqlite_master WHERE type IN ('table','view')")}
if "metadata" not in tables or "tiles" not in tables:
    raise SystemExit(f"Invalid MBTiles tables/views: {sorted(tables)}")
metadata = dict(connection.execute("SELECT name, value FROM metadata"))
count, minimum, maximum = connection.execute(
    "SELECT COUNT(*), MIN(zoom_level), MAX(zoom_level) FROM tiles"
).fetchone()
if count < 100 or minimum is None or maximum is None:
    raise SystemExit(f"Suspicious tile count: {count}")
names = set()
layers_examples = {}
formats = set()
for (blob,) in connection.execute("SELECT tile_data FROM tiles ORDER BY zoom_level DESC LIMIT 50"):
    try:
        if blob[:2] == b"\x1f\x8b":
            raw = gzip.decompress(blob)
        else:
            raw = blob
        decoded = mapbox_vector_tile.decode(raw)
    except Exception as exc:
        raise SystemExit(f"Tile decoding failed: {exc}")
    for name, layer in decoded.items():
        names.add(name)
        if name not in layers_examples:
            features = layer.get("features", [])
            if features:
                layers_examples[name] = {
                    "feature_type": features[0].get("geometry", {}).get("type"),
                    "property_keys": sorted(features[0].get("properties", {}).keys())[:35],
                }
if not names:
    raise SystemExit("No decodable vector layers in sample")
result = {
    "source": "https://download.geofabrik.de/europe/spain/navarra-shortbread-1.0.mbtiles",
    "attribution": "© OpenStreetMap contributors / Geofabrik, ODbL",
    "file_size_bytes": p.stat().st_size,
    "sha256": sha,
    "tile_count": count,
    "minzoom": minimum,
    "maxzoom": maximum,
    "metadata": metadata,
    "layers_sample": sorted(names),
    "layer_examples": layers_examples,
    "sampled_tiles": 50,
    "status": "sampled_only_not_android_verified",
}
print(json.dumps(result, ensure_ascii=False, indent=2))
Path("build").mkdir(exist_ok=True)
Path("build/navarra_mbtiles_probe.json").write_text(
    json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8"
)
