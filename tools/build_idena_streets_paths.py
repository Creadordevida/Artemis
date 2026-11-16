#!/usr/bin/env python3
"""Convert IDENA WFS streets, paths, and street-name labels into offline files.

NOT a navigation graph; road connectivity, sidewalk availability and safe
walkability are unverified. Official WFS data under Navarra Open Data CC BY 4.0.
The producer fails closed on inconsistent totals, duplicate IDs, malformed
geometries or abnormal file sizes. It never scrapes OSM map tiles.
"""
import argparse
import hashlib
import json
import math
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from pyproj import Transformer
from shapely.geometry import LineString

WFS = "https://idena.navarra.es/ogc/wfs"
LAYERS = {
    "street": "CARTO1_Lin_30Calle",
    "path": "CARTO1_Lin_33Camino",
    "street_name": "CARTO1_Txt_30Calle",
}
EXPECTED_BOUNDS = (-2.8, 41.6, -0.55, 43.5)
PAGE_SIZE = 500
MAX_PAGE_BYTES = 4_000_000
MAX_TOTAL_BYTES = 110_000_000
MAX_OUTPUT_BYTES = 16_000_000
MAX_FEATURES = 50000
SAMPLE_METERS = 6  # display simplification; not suitable for routing
TO_UTM = Transformer.from_crs("EPSG:4326", "EPSG:25830", always_xy=True)
TO_GPS = Transformer.from_crs("EPSG:25830", "EPSG:4326", always_xy=True)


def fetch(layer, index, page_size):
    qs = urlencode({
        "service": "WFS", "version": "2.0.0", "request": "GetFeature",
        "typeNames": layer, "startIndex": index, "count": page_size,
        "outputFormat": "application/json", "srsName": "EPSG:4326",
    })
    url = WFS + "?" + qs
    with urlopen(Request(url, headers={"User-Agent": "Artemis-Navarra-OffGrid/0.2"}),
                 timeout=45) as response:
        data = response.read(MAX_PAGE_BYTES + 1)
    if len(data) > MAX_PAGE_BYTES:
        raise ValueError(f"WFS page exceeds size budget: {layer} at {index}")
    payload = json.loads(data)
    if payload.get("type") != "FeatureCollection":
        raise ValueError(f"Invalid WFS response: {layer} offset {index}")
    return payload, len(data)


def check_point(coords):
    if len(coords) < 2:
        raise ValueError("Invalid coordinate")
    lon, lat = float(coords[0]), float(coords[1])
    xmin, ymin, xmax, ymax = EXPECTED_BOUNDS
    if not (math.isfinite(lon) and math.isfinite(lat) and
            xmin <= lon <= xmax and ymin <= lat <= ymax):
        raise ValueError(f"WFS point outside Navarra area: {lon},{lat}")
    return (lon, lat)


def line_coords(feature):
    geom = feature.get("geometry") or {}
    kind = geom.get("type")
    if kind == "LineString":
        segments = [geom.get("coordinates", [])]
    elif kind == "MultiLineString":
        segments = geom.get("coordinates", [])
    else:
        raise ValueError(f"Expected lines, got {kind}")
    for segment in segments:
        points = [check_point(c) for c in segment]
        if len(points) < 2:
            continue
        projected = LineString([TO_UTM.transform(*point) for point in points])
        reduced = projected.simplify(SAMPLE_METERS, preserve_topology=False)
        if reduced.is_empty or reduced.geom_type != "LineString":
            continue
        output = []
        for x, y in reduced.coords:
            lon, lat = TO_GPS.transform(x, y)
            pair = [round(lat, 5), round(lon, 5)]
            if not output or output[-1] != pair:
                output.append(pair)
        if len(output) >= 2:
            yield output


def load_layer(layer, limit=None):
    first = None
    unique = set()
    result = []
    source_bytes = 0
    start = 0
    while True:
        requested = PAGE_SIZE if limit is None else min(PAGE_SIZE, limit - start)
        if requested <= 0:
            break
        data, downloaded = fetch(layer, start, requested)
        source_bytes += downloaded
        if source_bytes > MAX_TOTAL_BYTES:
            raise ValueError("Source download byte limit exceeded")
        raw_total = data.get("numberMatched", data.get("totalFeatures"))
        if isinstance(raw_total, int) and raw_total > MAX_FEATURES:
            raise ValueError(f"Abnormally large feature count for {layer}")
        if first is None:
            first = raw_total
        if raw_total != first:
            raise ValueError("WFS changed numberMatched during import")
        items = data.get("features", [])
        if not items:
            break
        for feature in items:
            identifier = feature.get("id")
            if not identifier:
                raise ValueError("Missing stable WFS feature ID")
            if identifier in unique:
                raise ValueError(f"Duplicate WFS feature ID {identifier}")
            unique.add(identifier)
            result.append(feature)
        start += len(items)
        if len(items) < requested or (isinstance(first, int) and start >= first):
            break
        # Be polite to the public data service.
        time.sleep(0.12)
    if limit is None and isinstance(first, int) and len(result) != first:
        raise ValueError(f"Incomplete WFS layer {layer}: {len(result)} of {first}")
    return result, source_bytes, first


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="build/street-paths")
    ap.add_argument("--limit", type=int, default=None,
                    help="Per-layer pilot size; omit for complete official layer")
    args = ap.parse_args()
    output = Path(args.out)
    output.mkdir(parents=True, exist_ok=True)
    streets, paths, names = [], [], []
    metadata = {"source": WFS, "provider": "Gobierno de Navarra / SITNA / IDENA",
                "license": "CC BY 4.0", "extraction_utc": datetime.now(timezone.utc).isoformat(),
                "sample_simplification_meters": SAMPLE_METERS,
                "is_complete": args.limit is None,
                "layer_counts": {}}
    for category, layer in LAYERS.items():
        rows, bytes_used, reported = load_layer(layer, limit=args.limit)
        metadata["layer_counts"][category] = {
            "wfs_type": layer, "features_downloaded": len(rows),
            "features_reported": reported, "source_bytes": bytes_used,
        }
        if category != "street_name":
            target = streets if category == "street" else paths
            for row in rows:
                target.extend(line_coords(row))
        else:
            for row in rows:
                props = row.get("properties") or {}
                value = str(props.get("CADTEXT") or props.get("ETIQUETA") or "").strip()
                if not value or len(value) > 100:
                    continue
                geom = row.get("geometry") or {}
                if geom.get("type") != "Point":
                    continue
                lon, lat = check_point(geom.get("coordinates", []))
                names.append({"text": value, "lat": round(lat, 5), "lon": round(lon, 5)})
        print(f"{category}: {len(rows)} features, {bytes_used} source bytes")
    if not streets or not paths:
        raise ValueError("Empty streets or paths")
    records = {"streets": streets, "paths": paths, "labels": names}
    data = json.dumps(records, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    if len(data) > MAX_OUTPUT_BYTES:
        raise ValueError(f"Offline cartography size over {MAX_OUTPUT_BYTES} bytes")
    (output / "navarra_streets_paths.json").write_bytes(data)
    metadata["output_bytes"] = len(data)
    metadata["line_counts"] = {"streets": len(streets), "paths": len(paths),
                               "labels": len(names)}
    metadata["sha256_output"] = hashlib.sha256(data).hexdigest()
    metadata["limitations"] = (
        "Official streets and paths only; no walkable routes or safety guarantees; "
        "not necessarily complete for all towns"
    )
    (output / "navarra_streets_manifest.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(metadata, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
