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
