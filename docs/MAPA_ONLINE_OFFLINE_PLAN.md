# Mapa Artemis — online operativo en código / offline planificado
Estado: 2026-11-16. Rama `feat/mapa-online-recursos`; **no crear APK hasta solicitud expresa**.

## 1. Primera capa online
- Dependencia Flutter `flutter_map ^8.3.2` (BSD), `latlong2`.
- Entrada en inicio: «Abrir mapa de Navarra».
- Fondo cartográfico: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`; carga interactiva **únicamente** las teselas visibles. Acceso sujeto a términos y capacidad del servidor OSM; no usarlo para un lanzamiento a escala sin seleccionar un proveedor con SLA.
- Identificación del cliente `org.artemis.help`, atribución «© OpenStreetMap contributors» **siempre visible**, caché en disco incorporada en flutter_map 8.2+ y sin descarga masiva.
- Protección de privacidad: el proveedor de teselas puede conocer la zona y el momento en que se consulta el mapa; Artemis no le envía coordenadas personales a una API de geolocalización, pero un mapa centrado en GPS **revela aproximadamente la zona visitada** por la petición de teselas. Esto exige aviso y política de privacidad revisada para menores.
- Los recursos del directorio se guardan en JSON **dentro de la app**; no se consulta servidor de POI.
- Fallo de conexión: fondo incompleto o vacío con aviso; los puntos, teléfonos y el listado permanecen accesibles offline.

## 2. Ubicación de recursos reales y públicos
- Directorio general: `assets/offline/navarra_frontline.json` con 367 registros (63 policiales, 304 sanitarios de titularidad pública).
- Puntos policiales: geometrías aproximadas oficiales (9 PF, 54 GC) del GIS de Navarra.
- Salud: **capa independiente** `assets/offline/navarra_sns_geo.json`, generada de fuentes IDENA CC BY 4.0, con 336 puntos públicos comprobados: 299 atención primaria, 18 salud mental y 19 salud sexual y reproductiva. Fuentes y hashes en `assets/offline/geo_manifest.json`.
- Total visible sobre mapa en esta fase: **399 ubicaciones públicas** (336 SNS-O + 63 policía). No equivale a 399 recursos únicos conciliados con el directorio. Puede haber centros compartiendo edificio; no inventar unicidad ni identidad.
- Distinción importante: puntos aproximados de instalación ≠ entrada peatonal. No hay información suficiente para confirmar horario, servicio de urgencias, disponibilidad inmediata ni accesibilidad.
- Los 304 registros sanitarios del CSV general siguen en el directorio; no se asignan automáticamente las coordenadas del GIS por similitud de nombre. Pendiente de reconciliación conservadora por códigos oficiales (`IDCENSAN` / `Código Centro`).

## 3. Camino offline garantizado
El caché de teselas **no es** un mapa offline de toda Navarra: solo conserva algunas zonas visitadas. Hay que distribuir un archivo de mapas preparado para uso local.

### Ruta A: MBTiles vectoriales (preferida)
- Archivo ya existente en catálogo Geofabrik: `navarra-shortbread-1.0.mbtiles` (~72 MiB en su índice).
- Primer intento desde GitHub Actions: conexión rechazada a `download.geofabrik.de` (curl 7); segundo espejo `download-ext2.geofabrik.de`: DNS fallido (curl 6). No asumir que el archivo se ha descargado; seguir buscando origen autorizado y fiable.
- Si se obtiene: validar SQLite, `tiles`/metadata, zoom, capas, geometría con `tools/inspect_navarra_tiles.py`. Comprobar origen, fecha y SHA-256.
- Reutilizar `flutter_map` y añadir `flutter_map_vector_tiles ^2.6.0` + `flutter_map_vector_tiles_mbtiles ^1.0.0` que aceptan MBTiles locales en Android, según documentación oficial de los paquetes. Crear estilo Shortbread local con tipografías/sprites integrados, sin peticiones externas.
- El mapa offline tendrá **prioridad**; si archivo falta o está dañado, el usuario verá una advertencia y podrá usar la capa online solo si ha elegido el modo con red. No mostrar fondo ficticio.
- Realizar pruebas de modo avión y de renderizado en Android físico antes de declarar la función lista.

### Ruta B: construir MBTiles desde fuentes que sí están accesibles
- Los conjuntos GIS oficiales de Navarra de IDENA son descargables desde GitHub Actions, ya comprobado durante la importación de localizaciones.
- Investigar y seleccionar capas vectoriales legales de **red viaria, caminos, hidrografía, áreas pobladas y límites** (los tres SHP sanitarios no bastan para un mapa navegable).
- Convertir EPSG:25830 → EPSG:4326, generar MBTiles vectoriales con herramienta reproducible (tippecanoe o Planetiler si fuente adecuada), verificar atribución CC BY y tamaño; probar calidad visual rural y urbana.
- Esta vía exige trabajo de normalización, nivel de detalle y etiquetado, pero elimina la dependencia del host Geofabrik para compilar paquetes.
- No generar cartografía offline a partir de **descargas masivas del servidor público de teselas de OSM**: está prohibido por su política de uso.

## 4. Rutas offline
Ni el mapa raster ni MBTiles garantizan enrutamiento. Se requiere un **grafo peatonal** separado, basado en red de caminos y restricciones verificadas, más motor de búsqueda local y comprobación de que los datos cubren la ruta.
Hasta entonces NO mostrar «Cómo llegar» como función autónoma offline ni presentar distancia recta como trayecto seguro.

## 5. Próximas puertas
1. Flutter analyze/test sin generar APK; revisión del PR borrador.
2. Auditar las fichas y puntos de salud, cruces por identificadores y deduplicación.
3. Asegurar servicio de teselas online adecuado a uso real de menores (términos, privacidad, disponibilidad).
4. Obtener/generar MBTiles regional real, comprobar tamaño, integrar estilo y mapa sin red.
5. Validar en terminal Android físico, permisos GPS/flash, modo avión, falta de datos, fallos de llamada y accesibilidad.
6. Solo tras estas fases y autorización explícita: generar APK.

Referencias:
- https://operations.osmfoundation.org/policies/tiles/
- https://docs.fleaflet.dev/tile-servers/offline-mapping
- https://pub.dev/packages/flutter_map
- https://pub.dev/packages/flutter_map_vector_tiles_mbtiles
- https://geoportal.navarra.es/es/idena/descargar
- https://datosabiertos.navarra.es/dataset/centros-sanitarios
