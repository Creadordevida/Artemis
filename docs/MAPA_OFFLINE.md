# Cartografía offline: Navarra — contrato de importación (16/11/2026)

## Fuente comprobada
Geofabrik publica un extracto de Navarra de OpenStreetMap en `https://download.geofabrik.de/europe/spain/navarra.html`.
El `navarra-latest.osm.pbf` ronda 36 MB en noviembre de 2026; **NO es un mapa representable directamente**. Contiene datos OSM que deben convertirse a teselas vectoriales y a un grafo de rutas. No suponer que el paquete final ocupe lo mismo.

Geoportal Navarra / SITNA / IDENA ofrece capas oficiales con licencia CC BY 4.0: `https://geoportal.navarra.es/es/idena/descargar`.

## Pipeline aceptado
1. Descargar extracción OSM y guardar fecha, origen, sha256, licencia y atribución.
2. Generar teselas vectoriales con configuración de estilo, metadatos y recursos tipográficos offline.
3. Generar el índice de nombres/direcciones y un grafo de rutas peatonales por separado.
4. Empaquetar por región versionada; exportar tamaño comprimido/instalado y cobertura (zoom, caminos, pueblos).
5. Probar con la radio del teléfono apagada: no permitir solicitudes de red para renderizar mapas básicos.
6. Mostrar posición GPS solo si se confirma y mantener últimos valores etiquetados como históricos.
7. Verificar iconos de recursos contra directorios oficiales, no trasladar sin más etiquetas de OpenStreetMap como servicios abiertos.
8. Añadir atribución visible de OpenStreetMap y, si corresponde, del Geoportal de Navarra; revisar obligaciones ODbL y licencias de cualquier capa mezclada.
9. Aceptación: mapa real, zoom y desplazamiento completamente offline en móvil físico, municipios rurales incluidos; sin pantalla blanca ante ausencia de red.

## Evaluación técnica
- Candidato MapLibre Flutter: renderizado vectorial y documentación de mapas offline.
- Alternativa FlutterMap + MBTiles (raster), pero los raster a mucho zoom pueden exceder el presupuesto 200–300 MB.
- Elegir tras una prueba **con paquete real**, no solo por documentación.
- Prohibido el uso de teselas de servidores públicos de OSM para descargas masivas; el extracto Geofabrik es la base de procesamiento.

## Estado
**Pipeline especificado, extracción y renderizado todavía NO integrados.** El PR #7 solo prepara el directorio de recursos offline y su validación.

## Prueba experimental de integración — 16/11/2026
- Rama `feat/navarra-vector-map`, PR #8.
- Archivo `navarra-shortbread-1.0.mbtiles` de Geofabrik (~75 MB) descargado por GitHub Actions durante la compilación; no se sube al repositorio.
- Flutter empaqueta el archivo y lo copia a almacenamiento interno en la primera apertura del mapa.
- MapLibre 0.4 pre muestra capas locales básicas (tierra, agua, calles, edificios). No se requieren peticiones HTTP de teselas.
- El marcador azul solo se dibuja cuando existe una coordenada recibida del dispositivo; se avisa si es histórica.
- El 112 permanece accesible durante y después de abrir el mapa.
- **Pendientes de QA:** compatibilidad Android nativa, legibilidad y nombres de pueblos, rendimiento/copia del paquete, verificaciones en modo avión, y rutas. No confundir compilación con pruebas de campo.
