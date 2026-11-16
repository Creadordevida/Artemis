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

## Continuación — directorio telefónico offline — 2026-11-16
- Comprobada compilación debug previa: run 43867269437, análisis, tests y APK correctos (artefacto de pruebas disponible, no apto para emergencias).
- Añadido `lib/help_contacts.dart`: seis contactos guardados localmente y metadatos de procedencia, con fecha de verificación. 112, ANAR 116111, consejo sanitario Navarra, farmacias de guardia, Guardia Civil y carreteras.
- Añadido acceso `Teléfonos` en pantalla principal con fichas y apertura del marcador.
- Añadido test de estructura de datos; nueva compilación todavía por confirmar.
- **Advertencia:** estos contactos no constituyen directorio físico geolocalizado. No se han incorporado mapas, horarios presenciales ni rutas; no distribuir como herramienta operativa.

## Continuación — contactos y coordenadas — 2026-11-16
- Directorio local de seis teléfonos oficiales con fuente y fecha en `lib/help_contacts.dart`.
- Pantalla «Teléfonos» con apertura de marcador; el funcionamiento en dispositivo no está todavía validado.
- Copia de coordenadas al portapapeles indicando expresamente si son una posición anterior.
- Registro documental de cada fuente en `docs/TELEFONOS_NAVARRA.md`.
- Se mantiene pendiente la verificación CI para estos cambios; no confundir con el éxito de la APK anterior.


## Cambio aprobado: solo lugares públicos y Enfermería (16/11/2026)
- Pantalla inicial: incorporada acción de llamada a Enfermería del Consejo Sanitario de Navarra (948 290 290); marcado desde el dispositivo, no llamada integrada.
- Fuente: https://portalsalud.navarra.es/es/ciudadania/atencion-pacientes/contacto/consejo-sanitario; horario publicado contradictorio entre fuentes oficiales, NO marcar «abierto ahora».
- Auditado `Dependencia funcional` en el CSV oficial. Filtro por titularidad pública implementado con lista cerrada y bloqueo adicional en cliente.
- Se excluyen entidades privadas y no clasificadas, incluida la opción de farmacia comercial en el inicio.
- Datos geográficos sanitarios siguen SIN coordenadas. Emergencia hospitalaria y horarios no se infieren de la categoría.
- Pendiente confirmar el paquete regenerado, prueba Android y verificación de contenidos con centros.

## Importación pública validada — 2026-11-16
- Importador oficial `tools/build_offline_navarra.py` auditado con el campo real `Dependencia funcional` (CSV Navarra).
- Paquete generado: 367 recursos **exclusivamente públicos**: 304 sanitarios y 63 policiales (9 Policía Foral + 54 Guardia Civil). Titularidad privada en paquete: 0.
- Sanitarios: 212 consultorios de atención primaria municipales, 61 centros de salud, 17 centros de atención a la salud sexual y reproductiva, 11 centros de salud mental y 3 hospitales generales públicos.
- `assets/offline/navarra_frontline.json` contiene el paquete; el cliente rechaza registros sanitarios sin `public_ownership_verified`.
- Acceso destacado de Enfermería de Consejo Sanitario 948 290 290 en inicio, sin promesa de disponibilidad horaria; 112 permanente.
- Fuentes/hashes y hora de extracción en `assets/offline/manifest.json`.
- **Pendiente:** comprobación final de CI Android después de la incorporación del paquete; verificar teléfonos, fachadas/entradas, horarios y navegación en dispositivo; no declarar apto para emergencias.

## Orientación sin conexión — 2026-11-16
- Creado `lib/help_orientation.dart`: árbol determinista de 6 situaciones. No usa Internet ni IA, no diagnostica ni recopila respuestas.
- Cada situación tiene un primer paso concreto y alternativa de ayuda humana. Acceso permanente a 112; ANAR 116111 o Enfermería Consejo Sanitario 948 290 290 cuando corresponde.
- Pantalla inicial «No sé qué hacer» enlazada al nuevo recorrido.
- Creado `test/help_orientation_test.dart` para comprobar contenido, regreso, contacto y botón de emergencias.
- **Pendiente:** confirmar CI, revisar contenido con profesionales competentes, comprobar accesibilidad y funcionamiento en Android físico; no ofrecer aún como servicio de emergencias al público.

## Verificación de ayuda guiada y mapa — 16/11/2026
- **Confirmado CI verde:** GitHub Actions run 43875274207 (analizador, tests y APK debug) tras integrar el recorrido de seis situaciones de ayuda offline. No validado aún en móvil físico.
- Botón 112 en todas las pantallas de orientación, con enlaces telefónicos a ANAR 116111 y Enfermería 948290290 cuando corresponde.
- Cartografía: localizada fuente MBTiles Shortbread de Navarra (~76,8 MB) y creado un validador de capas y metadatos. La primera descarga desde GitHub Actions falló por conexión al servidor Geofabrik principal (curl error 7). Se ha configurado el espejo público `download-ext2.geofabrik.de`; **la disponibilidad y decodificación no están confirmadas aún**.
- **No hay mapa offline integrado**: los recursos siguen disponibles en un listado local con distancias solo para dependencias policiales con geometría; no se asignan coordenadas a centros sanitarios a partir de direcciones.
- Próximas puertas: recuperar/validar MBTiles, construir estilo Shortbread con fuentes y recursos locales, incluir en APK, probar mapa realmente en modo avión, medir tamaño instalado y QA de rutas.

## Linterna y control del pipeline — 16/11/2026 (continuación)
- Añadido botón de linterna en la barra de ARTEMIS (`lib/flashlight_control.dart`) y dependencia nativa `torch_light ^2.0.0`.
- Funciones: pulsar para encender/apagar flash, alternativa de pantalla blanca con salida visible si falla o no existe flash, intento de apagado al salir de la app; la luz puede permanecer encendida mientras se consultan otras pantallas internas.
- Pruebas automatizadas con hardware simulado: encendido/apagado, sin cámara y error de cámara. **El funcionamiento físico todavía requiere prueba en un dispositivo Android**.
- `.github/workflows/android.yml` reducido a análisis, tests y compilación Android. Importación de datos oficiales y pruebas MBTiles se ejecutan en workflows independientes, solo por cambios relevantes o bajo activación explícita.
- Fallo real del mapa: Geofabrik principal cerró conexión (curl 7); espejo `download-ext2.geofabrik.de` no resuelve DNS (curl 6) desde runners GitHub. No hay MBTiles validado ni mapa offline en la app.
- Fuentes cartográficas: MBTiles Navarra Shortbread anunciado por Geofabrik en su índice, pendiente de obtención/inspección. No presentar como integrado hasta obtener muestra y renderizar en Android sin conexión.
- CI con linterna: verificar resultado del run 43880681600 antes de declararla compilada; la ausencia de pruebas físicas impide darla como validada para usuario final.
