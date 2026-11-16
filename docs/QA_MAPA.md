# Puertas de calidad del mapa Artemis
Estado: 2026-11-16. Esta documentación NO certifica uso en emergencias.

## Logros reproducibles
- Prototipo en `flutter_map` con mapa online, caché de teselas, licencia y filtro de recursos oficiales.
- Mapa básico offline: IDENA `INFRAE_Lin_CtraEje`, 17.479 trazados, aprox. 1 MB. No permite rutas.
- Puntos públicos: 399 ubicaciones GIS sin emparejamiento automático con el directorio (336 salud SNS-O + 63 policiales).
- IDENA WFS confirmado: `CARTO1_Lin_30Calle`, `CARTO1_Lin_33Camino` y `CARTO1_Txt_30Calle`.
- Piloto de 500 elementos por capa pasado. Extracción completa iniciada como proceso de CI con validaciones de paginación y tamaño.
- Parser `lib/offline_streets.dart` con comprobación de límites y número de elementos; integración como detalle opcional, visible solamente a zoom útil (calles >=11, caminos >=12), manteniendo carreteras si el recurso falla.
- **No se ha generado APK en esta fase.**

## Validaciones pendientes antes de permitir prueba externa
1. El manifiesto del paquete de calles debe registrar totales descargados que coincidan con WFS y SHA-256.
2. Comprobar si el servicio WFS cubre toda Navarra o solo áreas cartografiadas a escala 1:1.000; nunca prometer cobertura total basándose solo en éxito HTTP.
3. Añadir asset y probar que Flutter puede leer todos sus bytes localmente tras reiniciar sin conexión.
4. Comprobar presencia de carreteras y calles en Pamplona, Tudela, Estella-Lizarra, Baztan, Sangüesa-Zangoza y áreas rurales.
5. Revisar que los caminos WFS no se ofrecen como rutas transitables o seguras.
6. Exponer nombres de calles solo cuando su cobertura y legibilidad estén comprobadas, filtrando etiquetas de la zona visible.
7. Medir el renderizado en móvil Android real (FPS, congelaciones, memoria, arranque) con el mapa offline, zoom y desplazamientos rápidos.
8. Probar modo avión, permisos GPS denegados, GPS impreciso, falta de almacenamiento, archivo corrupto y restauración de la app.
9. Comprobar que la vista offline no realiza solicitudes de red para dibujar calles ni POI.
10. Mantener acceso al 112, a Enfermería y a los teléfonos de ayuda aunque la cartografía falle.
11. Aplicar atribución Gobierno de Navarra / SITNA / IDENA CC BY 4.0 y OSM solo cuando se use OSM; revisar licencias específicas de los conjuntos.
12. Validar que no se publican secretos, identificadores de menores ni registros de localización.

## Criterio para generar APK
Solamente para una prueba que no pueda verificarse en tests de código, como rendimiento gráfico, modo avión y representación real en el dispositivo. Documentar antes hipótesis, modelo Android y casos de prueba; no enviar una APK como producto terminado.

## Duplicidad de tareas
La extracción completa debe realizarse en una tarea dedicada y solo al variar la fuente o el importador; nunca en cada commit de UI. Los pipelines de verificación de código deben limitarse a análisis y tests.
