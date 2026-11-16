#!/usr/bin/env bash
# Fetch a reproducible source extract, NOT the final offline map.
set -euo pipefail
OUT="${1:-build/geodata/navarra}"
mkdir -p "$OUT"
URL="https://download.geofabrik.de/europe/spain/navarra-latest.osm.pbf"
echo "Downloading OpenStreetMap Navarra source extract..."
curl --fail --location --retry 3 --connect-timeout 20 "$URL" -o "$OUT/navarra.osm.pbf.part"
test -s "$OUT/navarra.osm.pbf.part"
mv "$OUT/navarra.osm.pbf.part" "$OUT/navarra.osm.pbf"
sha256sum "$OUT/navarra.osm.pbf" > "$OUT/navarra.osm.pbf.sha256"
printf '%s\n' "$URL" > "$OUT/SOURCE.txt"
date -u +'%Y-%m-%dT%H:%M:%SZ' > "$OUT/DOWNLOADED_AT.txt"
echo "Source saved to $OUT. Convert to tiles and routing graph before integrating."
