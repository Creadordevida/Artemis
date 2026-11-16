# Estado real de Artemis — 2026-11-16
## Confirmado
- Repositorio público `Creadordevida/Artemis` creado por el propietario.
- Acceso de escritura confirmado.
- Rama `develop` abierta.
- Prototipo de interfaz inicial Flutter en `lib/main.dart`.
- Acceso mediante intento de abrir marcador telefónico 112 (no se ha probado en Android).
- Intento GPS con permiso, reserva de última posición etiquetada y referencia manual textual (NO geocodificada).
- Documentación de producto, seguridad, método y datos.

## Sin validar
- Compilación Android: pendiente CI y prueba.
- GPS real, permiso y retorno de marcador telefónico.
- Diseño en pantalla real, accesibilidad y textos con menores.

## Pendiente (no operativo)
- Mapa offline, calles, caminos y recursos geolocalizados.
- Buscador y direcciones offline; rutas.
- Horarios de centros, farmacias, directorios oficiales y validación.
- Alertas online verificadas.
- Linterna, identidad gráfica incorporada en assets nativos.
- APK de prueba y tests físicos.

## Próximo hito
CI Android; estructurar plataforma; mapa local básico con paquete real y medición; directorio oficial local. Ninguna prueba pública antes de seguridad y QA.

## Continuación — 2026-11-16
- Detectado y corregido en CI: Flutter generaba `test/widget_test.dart` con el contador de demostración, incompatible con `ArtemisApp`; se elimina en la preparación.
- Análisis estático: superado en una ejecución de CI (solo advertencia informativa deprecación `material.dart` en Flutter 3.50).
- Detectado por test de interfaz: botón 112 fuera de la ventana en pantalla pequeña. Corregido con botón fijo inferior persistente.
- Manifest Android incorporado con permisos de ubicación foreground y consulta del marcador telefónico.
- Test actualizado para comprobar visibilidad de 112 incluso después de hacer scroll.
- **Pendiente:** confirmar nueva ejecución completa de CI y prueba de APK; no declarar compilado hasta resultado correcto.

## Continuación: catálogo local y mapa vectorial — 16/11/2026
- GitHub Actions de la rama develop: compilación Android completada con éxito (run 43867269437); aún sin pruebas en dispositivo.
- PR #7: directorio territorial en assets, validador de procedencia/fecha/coordenadas, pruebas unitarias y listado local de teléfonos; el único dato público incorporado por ahora es 112, sin geolocalización.
- PR #8 (experimental): MapLibre con teselas vectoriales reales de Navarra (Geofabrik Shortbread ~75 MB); el CI descarga el paquete, lo empaqueta y la app lo copiará al almacenamiento interno para consulta sin red.
- Primera ejecución experimental: extracción de Geofabrik conseguida, análisis rechazó sintaxis Dart no habilitada por SDK mínimo 3.5; corregido a Dart >=3.13. Nueva validación pendiente.
- Se dibujan agua, calles, edificios y un marcador diferente para ubicación actual o histórica. Etiquetas de localidades, POI oficiales y rutas todavía pendientes.
- Las ramas de mapa y datos siguen sin fusionar hasta confirmación de compilación y prueba física; uso en emergencias no autorizado.
