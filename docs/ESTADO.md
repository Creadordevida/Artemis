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
