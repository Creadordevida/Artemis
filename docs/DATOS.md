# Fuentes de datos y contrato offline
## Diseño
Cada paquete regional será autónomo, versionado y con hash, licencia y fecha. Navarra es la primera región. Base local con: id estable, nombre, categoría, lat/lon, dirección, teléfono, horario estructurado, función (urgencias / consulta ordinaria), URL fuente, fecha verificación, validez y estado. Prohibido inventar coordenadas, aperturas o horarios.

## Fuentes candidatas, NO integradas todavía
- SITNA/IDENA y OpenStreetMap: cartografía; verificar cobertura, atribución y condiciones de redistribución concretas.
- Gobierno de Navarra datos abiertos y directorios de Salud: centros y servicios.
- Autoridades competentes: policía, Guardia Civil, servicios para menores, farmacias y guardias.
- AEMET OpenData y DGT: alertas públicas donde las licencias y formatos permitan integración.
- Protección Civil Navarra: información oficial disponible; My112 no implica API pública.

## Actualización
Descarga validada, normalización, deduplicación, control de fuentes, transacción atómica del paquete y rollback si falla. Siempre mantener datos locales previos, distinguir caducado de actualizado. No rastreo continuo ni envío de ubicación de menores por defecto.

## Riesgos por resolver
Cobertura y vigencia de horarios, atención pediátrica, farmacias de guardia, trazado rural, difusión de datos no oficiales, derechos de uso, coste de cartografía y modo avión.

## Fuentes sanitarias oficiales concretas confirmadas — 16/11/2026
1. Directorio de centros sanitarios del Gobierno de Navarra: https://datosabiertos.navarra.es/dataset/centros-sanitarios (CC BY 4.0, frecuencia semestral). CSV: https://datosabiertos.navarra.es/dataset/c87d1546-0396-4e17-8b99-762d77d28503/resource/f1fc5b52-be72-4088-8cb1-772076e2071c/download/centrossanitarios.csv . Incluye direcciones y teléfonos; no asumir que tiene coordenadas u horarios de urgencias.
2. Datos geográficos de Atención Primaria de IDENA: https://idena.navarra.es/descargas/DOTACI_Sym_SNSPrimaria.zip ; capa de puntos, coordenadas en sistema de referencia oficial que requiere conversión y cotejo con directorio.
3. La unión de directorio y geometrías se hará por identificadores verificados o revisión manual; **nunca por coincidencias ambiguas de nombres**.
4. Importación versionada: fecha, checksum, mapa de campos, errores y licencia. Horarios de guardia y atención urgente deberán proceder de registros separados y verificables.
Estado: URLs documentadas; ETL y puntos de atención todavía NO integrados.
