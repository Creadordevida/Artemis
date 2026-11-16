#!/usr/bin/env python3
"""Probe the official IDENA WFS: list layers and request ONE feature per layer.

This step avoids assuming that a WMS map layer is available as a downloadable
SHP zip or that a huge regional dataset can be consumed in one response.
No bulk extraction here; cap responses and validate provider/format.
"""
from urllib.parse import urlencode
from urllib.request import Request, urlopen
import json
import xml.etree.ElementTree as ET
from pathlib import Path

BASE = "https://idena.navarra.es/ogc/wfs"
LAYERS = [
    "CARTO1_Lin_30Calle",
    "CARTO1_Lin_33Camino",
    "CARTO1_Txt_30Calle",
]
MAX_RESPONSE = 2 * 1024 * 1024
OUT = Path("build/wfs-probe")


def request(params):
    url = BASE + "?" + urlencode(params)
    headers = {"User-Agent": "Artemis-OffGrid-Research/0.1", "Accept": "application/json,application/xml,text/xml,*/*"}
    with urlopen(Request(url, headers=headers), timeout=35) as response:
        data = response.read(MAX_RESPONSE + 1)
        status = response.status
        content_type = response.headers.get("Content-Type", "")
    if len(data) > MAX_RESPONSE:
        raise ValueError("WFS response exceeds safety limit")
    return data, status, content_type, url


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    report = {"service": BASE, "checked_layers": [], "max_download_bytes": MAX_RESPONSE}
    capabilities, status, mime, url = request({
        "service": "WFS", "version": "2.0.0", "request": "GetCapabilities"
    })
    root = ET.fromstring(capabilities)
    if not root.tag.endswith("WFS_Capabilities"):
        raise ValueError("Not a WFS capabilities document")
    named_types = {
        element.text.strip()
        for element in root.iter()
        if element.tag.endswith("Name") and element.text
    }
    report["capabilities"] = {"http_status": status, "size_bytes": len(capabilities),
                              "mime": mime, "requested_url": url}
    for layer in LAYERS:
        match = layer in named_types or any(
            name.endswith(":" + layer) for name in named_types
        )
        entry = {"name": layer, "advertised_in_capabilities": match}
        if not match:
            report["checked_layers"].append(entry)
            continue
        data, status, mime, request_url = request({
            "service": "WFS", "version": "2.0.0", "request": "GetFeature",
            "typeNames": layer, "count": "1", "outputFormat": "application/json",
            "srsName": "EPSG:4326",
        })
        entry["http_status"] = status
        entry["response_mime"] = mime
        entry["sample_bytes"] = len(data)
        try:
            obj = json.loads(data)
        except (ValueError, UnicodeError):
            obj = {"type": "NotJSON", "snippet": data[:300].decode("utf-8", "replace")}
        entry["response_type"] = obj.get("type")
        entry["feature_count_returned"] = len(obj.get("features", []))
        entry["reported_total"] = obj.get("totalFeatures") or obj.get("numberMatched")
        if obj.get("features"):
            one = obj["features"][0]
            entry["geometry_type"] = (one.get("geometry") or {}).get("type")
            entry["fields"] = sorted((one.get("properties") or {}).keys())
        report["checked_layers"].append(entry)
    (OUT / "idena_wfs_capabilities_audit.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
