# Cartografía de Navarra — elección de fuente y plan de integración
Fecha de investigación: 2026-11-16.

## Hallazgo confirmado
Geofabrik ofrece un extracto OSM de Navarra (PBF) de alrededor de 35,7 MB en la consulta inicial. **Este PBF no es todavía un mapa renderizable en Flutter**: es materia prima que deberá procesarse. Fuente: https://download.geofabrik.de/europe/spain/navarra.html

IDENA/SITNA documenta mapas de fondo para descarga y modo sin conexión en su propio visor: https://idena.navarra.es/navegar/pdf/manual.pdf
No se presupone derecho a reutilizar directamente las teselas ni sus formatos hasta confirmar la licencia y el conjunto concreto.

## Estrategia técnica propuesta
1. Descargar extracto PBF reproducible, con fecha de extracción, SHA-256 y atribución OSM.
2. Construir cartografía vectorial MBTiles para toda Navarra, con estilo de alto contraste suave, zoom y nombres.
3. Evaluar `flutter_map` y `flutter_map_vector_tiles_mbtiles` para consultar MBTiles locales, sujeto a pruebas de compatibilidad Flutter/Android.
4. Validar calles, caminos rurales, lugares y orientación en Pamplona, Baztan, Ribera y zonas montañosas.
5. Preparar un paquete geográfico versionado y un motor separado de POI/servicios.
6. Medir tamaño instalado y rendimiento real, especialmente en Android de gama media.
7. Añadir cálculo de rutas peatonales en fase independiente: las teselas no proporcionan rutas por sí mismas.

## Reglas offline
- Nunca descargar teselas de la red como condición para abrir la pantalla inicial.
- Si el archivo falta, mostrar alternativa textual y teléfonos, sin mapa falso.
- La posición del usuario debe mostrar precisión y antigüedad; no sustituye al mapa.
- Nunca asumir transitabilidad o seguridad de un camino solo por existir en OpenStreetMap.

## Criterios de aceptación
- Arranque en modo avión sin pantalla vacía.
- Mapa local real visible, zoom, desplazamiento, punto GPS y último punto conocido diferenciado.
- Sin conexiones salientes necesarias para búsqueda y visualización inicial.
- Confirmar derechos y atribución; registrar versión del conjunto.
- APK y capturas reales de dispositivo; sin declarar completado hasta entonces.

## Situación actual
**Solo investigación/arquitectura. No integrado ni probado todavía.**
