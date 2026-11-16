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

## APK debug con linterna verificada en CI — 2026-11-16
- Run GitHub Actions **43880681600**: análisis, tests y compilación debug Android **correctos**. Artefacto `artemis-debug-prototype`, ID `14232331780`.
- APK extraída del artefacto GitHub: `app-debug.apk` de **150.156.848 bytes** (APK debug, no versión de distribución optimizada). SHA-256: `70224ceacfd2d7cb4c490b0bb28728a10e79b7198eb591f45fdfe93d30ec972c`.
- La compresión del artefacto ocupa 71.455.144 bytes.
- `test/flashlight_control_test.dart` supera casos con hardware simulado (encendido/apagado, cámara sin flash, error nativo); faltan pruebas reales en Android.
- Cartografía offline sigue pendiente y **no forma parte de esta APK**.
- **Advertencia imprescindible**: prototipo de desarrollo para pruebas técnicas, no usar como herramienta principal ante emergencias reales. Mantener 112 como referencia directa.

## Mapa online y fuentes offline alternativas — 16/11/2026
- PR borrador #10 desde `feat/mapa-online-recursos` sobre `feat/datos-oficiales-navarra`; NO está fusionado en `develop` ni en `main`.
- Código `lib/navarra_map.dart`: primera pantalla de mapa online de Navarra con teselas OSM, cache nativa de `flutter_map`, atribución visible y marcador GPS actual (sin utilizar posición anterior). Cuando falla la red, el directorio local y los puntos están disponibles. No equivale a que todo el fondo esté garantizado offline.
- **399 puntos públicos geográficos**: 63 dependencias policiales y 336 puntos sanitarios de fuentes IDENA. GIS sanitario: 299 primaria + 18 salud mental + 19 salud sexual/reproductiva. Son una capa geográfica independiente de las 304 fichas sanitarias del CSV original; falta conciliar identidades. No se presume horario, urgencias ni acceso físico verificado.
- Marcadores agrupados por proximidad (clustering) para evitar solapamiento a escala regional. Filtros por salud, Policía Foral y Guardia Civil.
- Pantalla de inicio enlazada al nuevo mapa. Internet declarado en AndroidManifest; proveedor de teselas puede conocer zona de visualización, requiere transparencia de privacidad para menores.
- **CI de fuente sin APK**: run 43886962854, análisis Flutter y tests **correctos**. El job verifica explícitamente que no se generó APK. Sin capturas de un móvil Android ni validación de teselas en conexión real.
- **Ruta alternativa offline verificada**: capa IDENA `INFRAE_Lin_CtraEje.zip`, CC BY 4.0, disponible desde GitHub Actions. Auditoría: 3.443.729 bytes ZIP, 17.479 trazados de carretera y 247.976 vértices. Es útil para un primer fondo vectorial offline, pero NO contiene la red completa peatonal ni los rótulos necesarios.
- Detalles técnicos, requisitos OSM y dos vías MBTiles documentados en `docs/MAPA_ONLINE_OFFLINE_PLAN.md`.
- **Pendiente**: probar teselas en dispositivo real, consolidar datos y ubicaciones, seleccionar proveedor de mapas online apto para producción, obtener o construir el paquete MBTiles offline completo, rutas peatonales. Sin generar APK hasta orden del usuario.

## Nuevo hito: vista básica de carreteras SIN INTERNET — 2026-11-16
- Generado con éxito desde **IDENA / Gobierno de Navarra** el paquete oficial `assets/offline/navarra_road_lines.json` con **17.479 ejes de carretera**, en coordenadas WGS84, simplificación 15 m. Tamaño del JSON: **998.869 bytes**; manifest con SHA-256 y CC BY 4.0 en `assets/offline/navarra_road_manifest.json`.
- Se incorpora `lib/offline_roads.dart` que carga y valida las geometrías del paquete local, sin conexiones de red.
- `lib/navarra_map.dart` ofrece selector **Online / Sin Internet**. Online: calles de OpenStreetMap y recursos públicos. Sin Internet: ejes de carreteras IDENA, 399 puntos públicos y acceso a directorio y 112. No hay rutas offline ni callejero urbano completo.
- En modo offline se muestra advertencia explícita «no todas las calles ni caminos»; atribución a Gobierno de Navarra. La vista online mantiene atribución © OpenStreetMap.
- Prueba `test/offline_roads_test.dart`: valida número esperado, vértices y límites geográficos. **CI de código (sin APK) run 43888506015: análisis y tests correctos**. No hay capturas ni prueba en teléfono físico.
- Investigado cruce entre **304 fichas sanitarias** del registro y **336 puntos oficiales IDENA**: códigos `Código Centro` e `IDCENSAN` no tienen coincidencias exactas, según `tools/audit_health_identity.py`; **ninguna identidad se ha asignado automáticamente**. Requiere cruce por nombres y localidades con revisión humana antes de asociar teléfonos.
- Revisado workflow: las importaciones GIS y auditorías oficiales ya no se ejecutarán en cada commit de código de la rama; quedan separadas por cambios de fuente. La compilación de APK sigue excluida por instrucción del usuario.
- **No apto para uso público/emergencias**. Pendientes calles urbanas, senderos, etiquetas, rutas peatonales verificadas, disponibilidad de datos públicos, privacidad de proveedor de teselas, QA GPS/cámara y prueba en dispositivos.


## Callejero IDENA 1:1.000 completo como capa de origen — 2026-11-16
- Dos importaciones WFS oficiales: run 43892119758 generó correctamente el archivo, pero falló la publicación por una carrera de commits de Git. Run 43892856656 completó la publicación en `assets/offline/navarra_streets_paths.json`.
- Manifest `assets/offline/navarra_streets_manifest.json`: 7.562 entidades de calle, 12.737 caminos/sendas, 6.276 etiquetas. Geometrías convertidas: 7.749 líneas de calle, 12.683 líneas de camino, 6.274 rótulos; archivo de 1.582.508 bytes; SHA-256 `75f787802f035d631c8a2d23dd1d4273bc18fa85affd6a55c071c143e54ed92d`.
- Asset incluido en pubspec. Superposición opcional de calles desde zoom 11 y caminos desde zoom 12, conservando carreteras si falla la lectura. Añadido test sobre datos reales; **resultado de CI de esta integración pendiente de comprobación**.
- Auditoría espacial independiente: existen trazados cerca de Pamplona, Tudela, Estella y Sangüesa, pero las capas `CARTO1_` no muestran cobertura equivalente en Elizondo (Baztan). No describirlas como «callejero completo de Navarra». «Completa» significa que se descargaron TODOS los registros anunciados por estas capas concretas.
- Se ha localizado una alternativa del Catastro de Navarra, `CATAST_Lin_CalleEje` y `CATAST_Txt_Calle`, para cubrir núcleos no cartografiados a 1:1.000; se está comprobando su estructura mediante WFS. Fuente https://datos.gob.es/es/catalogo/a15002917-callejero-catastral-ejes-de-las-calles1 .
- Sigue pendiente validar en Android real la representación y fluidez de todas las capas y nombres. **No se ha generado APK**.

## Cartografía catastral integral y QA Android — 16/11/2026
- Detectada falta de cobertura espacial de las capas 1:1.000 en Elizondo/Baztan. Evitado declarar «mapa completo de Navarra» con esas capas parciales.
- Fuente catastral verificada: `CATAST_Lin_CalleEje.zip` y `CATAST_Txt_Calle.zip`, directorio público de Navarra `filescartografia.navarra.es/2_CARTOGRAFIA_TEMATICA/2_7_CATASTRO/2_7_1_SHAPEFILE/`, licencia CC BY 4.0.
- Importador `tools/build_cadastral_navarra.py`: **64.893 polilíneas de calles** y **21.472 etiquetas de calle**, EPSG 25830 → WGS84, simplificación 6m, validación de límites, fuentes SHA-256 y asset de 4.237.415 bytes en `assets/offline/navarra_cadastral_streets.json`; manifiesto independiente.
- El modo offline del mapa elige ejes catastrales y rótulos; si falla, vuelve a `CARTO1` y conserva la capa de carreteras. Los caminos permanecen de `CARTO1`. Rótulos solo a zoom >=15, max 70 etiquetas dentro de la ventana; calles solo a zoom >=12.
- CI Flutter: fallo inicial por límites antiguos del parser para 50k líneas/10k rótulos; se corrigieron a topes de 130k/60k, y el análisis y tests terminaron **correctos** (run 43897902610).
- **Prueba de cobertura Elizondo/Baztan** en `test/offline_streets_test.dart`: superada por el nuevo dataset catastral.
- Workflow de rutina de Flutter sin descargas GIS ni generación de APK; importadores por cambios de fuente únicamente.
- Autorización del usuario: APK solo por razones técnicas. Se ha creado `.github/workflows/map-android-qa.yml` para una **única compilación debug de QA cartográfico**: validar rendimientos, memoria, visualización en móvil y modo avión. Aún no constituye validación física ni versión pública apta para emergencias.
- **Pendientes:** confirmar build del APK QA, probar Android físico y capturas REALES, analizar FPS/tiempos y memoria, mejorar red viaria peatonal y conectividad de caminos, topónimos, alertas y horarios oficiales. No se generan rutas a pie todavía.


## Primer APK de QA cartográfico, no release — 2026-11-16
- **Decisión justificada**: validar en Android real renderizado de ~65k ejes catastrales, 21k etiquetas, modo avión y FPS/memoria. Solo las pruebas de código no permiten observar esto.
- Workflow `map-android-qa.yml`: GitHub Actions run **43901299785** completado correctamente; artefacto `artemis-offline-navarra-map-qa` ID `14240614316`, ZIP ~77,7 MB, APK debug ~150 MB. SHA-256 APK: `6462203fc433d8fd197041f0d594389eb0e9ad36b1e53fcbc7a537c5c042f3cb`.
- **Advertencia**: compila, pero NO consta instalación o captura en terminal real; no se ha validado fluidez, renderizado ni fiabilidad ante emergencias. Este QA procede de un commit anterior a los dos ajustes recientes de UX (offline por defecto y botón de retorno offline al fallar online). Es exclusivamente diagnóstico.
- Antes de compilar, se añadieron filtrado de geometría por ventana visible y prueba de líneas que cruzan la pantalla (para mitigar coste de 64.893 trazados).
- Cambios posteriores al artefacto QA: (a) arranque del mapa por defecto offline, sin solicitar teselas por defecto a un proveedor externo; (b) opción «Ver offline» cuando falla el mapa online. Estos cambios requieren nuevas pruebas de fuente; NO están en el artefacto de QA anterior.
- Corregida duplicación de workflows: `map-android-qa.yml` es **solo manual (`workflow_dispatch`)** y se eliminó el segundo job APK del validador ordinario. Algunas compilaciones anteriores ya lanzadas siguieron ejecutándose; no se programarán automáticamente más APK.
- Mantener PR #10 en borrador, separado de `develop` hasta verificar mapa offline en dispositivo, privacidad, fuentes y accesibilidad.


## APK móvil de prueba validada por CI — 2026-11-16
- Usuario ha autorizado obtener una versión instalable para comprobar Artemis en móvil.
- **Compilación exacta**: GitHub Actions run [43903503335](https://github.com/Creadordevida/Artemis/actions/runs/43903503335), PR #10, rama `feat/mapa-online-recursos`. Job `compile-and-verify`: **success**.
- Pasó `flutter analyze --no-fatal-infos`, `flutter test`, compilación `flutter build apk --debug`, comprobación de ZIP/APK y presencia física de los assets `navarra_cadastral_streets.json`, `navarra_road_lines.json`, `navarra_streets_paths.json` y `navarra_sns_geo.json` dentro del paquete Android.
- Artefacto: `ARTEMIS-NAVARRA-MOVIL-PRUEBA`, ID **14245850269**. APK debug de **156.574.247 bytes**, SHA256 `e2897cff561ed7ded1fe281dcacda97c8546c66596009be829a727f21ea8c1c1`.
- Archivo exportado para el usuario tras verificar la coincidencia del SHA-256 con el compilado de GitHub. No se trata de APK firmado de distribución.
- Privacidad de esta versión: no solicita GPS al entrar; botón «Obtener mi ubicación» voluntario. Pantalla de mapa inicia en modo offline; pasar a online es una decisión explícita y envía consultas de teselas al proveedor.
- **No se afirma validación física**: pendiente instalar en Android, observar trazados y marcadores y registrar captura/vídeo real. No se deben invocar 112 ni otros números de emergencia para pruebas de marcado. Probar que el marcador abre el teléfono y cancelar sin llamar.
- Secuencia de QA propuesta: abrir en modo avión, mapa sin Internet, zoom y desplazamiento en Pamplona/Tudela/Elizondo, iconos públicos, listado offline; volver a red, habilitar mapa online y verificar calles, permisos GPS a petición y linterna. Informar de cualquier pantalla en blanco, bloqueo, sobrecalentamiento, retraso y captura real.
- APK para prueba técnica por adulto responsable, **no apta todavía para uso real por menores ni emergencias**. Quedan rutas peatonales, cobertura de centros y verificación de horarios.
