#!/usr/bin/env python3
"""Report only column names and aggregated ownership for public health filters."""
import csv
import io
from collections import Counter
from urllib.request import Request, urlopen

URL = "https://datosabiertos.navarra.es/dataset/c87d1546-0396-4e17-8b99-762d77d28503/resource/f1fc5b52-be72-4088-8cb1-772076e2071c/download/centrossanitarios.csv"
with urlopen(Request(URL, headers={"User-Agent":"Artemis-Data-Audit/0.1"}), timeout=45) as response:
    content = response.read(10_000_000).decode("utf-8-sig")
first = content.splitlines()[0]
delimiter = ";" if first.count(";") > first.count(",") else ","
rows = list(csv.DictReader(io.StringIO(content), delimiter=delimiter))
print("HEADERS:", rows[0].keys() if rows else "NO ROWS")
fields = {key: key.lower() for key in (rows[0].keys() if rows else [])}
for key, lower in fields.items():
    if any(term in lower for term in ("dependencia", "titularidad", "publico", "público", "privado", "gestion", "gestión")):
        print("OWNERSHIP COLUMN:", key, Counter((r.get(key) or "").strip() for r in rows).most_common(30))
for key, lower in fields.items():
    if "tipo de centro" in lower:
        print("TYPE COLUMN:", key, Counter((r.get(key) or "").strip() for r in rows).most_common(45))
