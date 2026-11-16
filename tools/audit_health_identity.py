#!/usr/bin/env python3
"""Audit exact official identifiers linking public SNS directory to GIS points.

Conservative JOIN ONLY: same official code, one-to-one uniqueness, same
municipality (when present) and sufficiently similar names. Ambiguous
matches are reported, never silently merged into the app.
"""
import csv
import difflib
import io
import json
import re
import unicodedata
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

import shapefile

from build_offline_navarra import fetch, SOURCES
from build_health_geopoints import PUBLIC_LAYERS

OUT = Path("build/public-health-match-report")
PUBLIC = {
    "Municipal", "SNS-O", "Otros del Gobierno de Navarra",
    "Otras entidades u organismos públicos", "Otros Públicos",
}
TYPES = {
    "Centros de salud", "Consultorios de atención primaria", "Hospitales generales",
    "Centros de salud mental", "Centros de atencion a la salud sexual y reproductiva",
}


def norm(value):
    raw = unicodedata.normalize("NFD", str(value or "").strip().casefold())
    ascii_text = "".join(c for c in raw if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", " ", ascii_text).strip()


def raw_id(v):
    return str(v or "").strip()


def load_csv():
    raw = fetch(SOURCES["centros_sanitarios"]).decode("utf-8-sig")
    first = raw.splitlines()[0]
    delim = ";" if first.count(";") > first.count(",") else ","
    result = []
    for row in csv.DictReader(io.StringIO(raw), delimiter=delim):
        if row.get("Dependencia funcional", "").strip() not in PUBLIC:
            continue
        if row.get("Tipo de Centro", "").strip() not in TYPES:
            continue
        result.append({
            "code": raw_id(row.get("Código Centro")),
            "name": row.get("Nombre Centro", "").strip(),
            "municipality": row.get("Localidad", "").strip(),
            "type": row.get("Tipo de Centro", "").strip(),
        })
    return result


def load_gis():
    result = []
    for layer, url in PUBLIC_LAYERS.items():
        raw = fetch(url)
        with zipfile.ZipFile(io.BytesIO(raw)) as z:
            paths = z.namelist()
            base = next(n[:-4] for n in paths if n.lower().endswith(".shp"))
            def part(ext):
                path = next(n for n in paths if n.lower() == (base + ext).lower())
                return io.BytesIO(z.read(path))
            reader = shapefile.Reader(shp=part(".shp"), shx=part(".shx"),
                                      dbf=part(".dbf"), encoding="cp1252")
            for item in reader.iterRecords():
                row = item.as_dict()
                result.append({
                    "code": raw_id(row.get("IDCENSAN")),
                    "name": str(row.get("CENSAN") or "").strip(),
                    "municipality": str(row.get("POBLACION") or "").strip(),
                    "layer": layer,
                })
    return result


def main():
    directory, gis = load_csv(), load_gis()
    left = defaultdict(list)
    right = defaultdict(list)
    for row in directory:
        if row["code"]:
            left[row["code"]].append(row)
    for row in gis:
        if row["code"]:
            right[row["code"]].append(row)
    exact_ids = sorted(set(left) & set(right))
    approved = []
    ambiguous = []
    for code in exact_ids:
        l, r = left[code], right[code]
        if len(l) != 1 or len(r) != 1:
            ambiguous.append({"code": code, "reason": "non_unique_identifier",
                              "csv_count": len(l), "gis_count": len(r)})
            continue
        a, b = l[0], r[0]
        similar = difflib.SequenceMatcher(None, norm(a["name"]), norm(b["name"])).ratio()
        municipality_ok = not a["municipality"] or not b["municipality"] or (
            norm(a["municipality"]) == norm(b["municipality"])
        )
        if similar < 0.75 or not municipality_ok:
            ambiguous.append({"code": code, "reason": "name_or_municipality_discordance",
                              "name_similarity": round(similar, 3),
                              "csv_name": a["name"], "gis_name": b["name"]})
            continue
        approved.append({"code": code, "csv_name": a["name"], "gis_name": b["name"],
                         "municipality": a["municipality"], "gis_layer": b["layer"],
                         "similarity": round(similar, 3)})
    OUT.mkdir(parents=True, exist_ok=True)
    report = {
        "csv_public_records": len(directory),
        "gis_public_points": len(gis),
        "csv_unique_codes": len(left),
        "gis_unique_codes": len(right),
        "exact_code_matches": len(exact_ids),
        "strict_approved_identity_pairs": len(approved),
        "manual_review": len(ambiguous),
        "automatically_attached_to_app": 0,
        "warning": "This is a QA report; no coordinates have been assigned to CSV records.",
    }
    (OUT / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    (OUT / "strict_matches.json").write_text(
        json.dumps(approved, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (OUT / "ambiguous.json").write_text(
        json.dumps(ambiguous, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
