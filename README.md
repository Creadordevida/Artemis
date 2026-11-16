# Artemis
**Ayuda cuando la necesitas.** Aplicación Android enfocada inicialmente en adolescentes en Navarra.

> ⚠️ Estado: **prototipo de desarrollo, no apto aún como herramienta de emergencias**. No sustituye al 112 ni a los servicios oficiales. Los datos y rutas offline deben verificarse antes de cualquier prueba pública.

## Principios
1. Ayuda en primer plano, sin menús de entrada.
2. Cada pantalla ofrece un siguiente paso seguro; los estados de error no son callejones sin salida.
3. No se inventan ubicaciones, recursos, horarios, aperturas ni avisos.
4. Con conexión se actualizan fuentes oficiales; sin ella se muestra información local con su fecha.
5. Privacidad por defecto: sin cuentas, analítica de ubicación ni almacenamiento remoto de posición.
6. Revisión de seguridad y lenguaje para menores antes de publicar.

## Alcance
- Navarra, expandible mediante paquetes territoriales.
- GPS cuando disponible; última localización señalada como histórica y selección manual.
- Mapa vectorial y búsqueda de recursos offline (pendiente).
- Directorio verificado de sanidad, seguridad, farmacias y ayuda al menor (pendiente).
- Rutas peatonales offline (pendiente).
- Guías oficiales, alertas con caducidad y linterna (pendientes).
- Objetivo: **200–300 MB instalados**, por medir con cartografía real.

## Estructura
- `lib/main.dart`: interfaz inicial y estado de ubicación.
- `docs/PRODUCTO.md`: producto, prioridades y criterios.
- `docs/SEGURIDAD.md`: reglas de seguridad y verificación.
- `docs/METODO.md`: flujo de entregas y pruebas.
- `docs/ESTADO.md`: fuente de verdad sobre avances.
- `docs/DATOS.md`: contrato de fuentes, licencias, caducidad.
- `.github/workflows/android.yml`: validación Android cuando exista estructura Flutter completa.

## Preparación local
Ejecutar `flutter create --platforms android .` si aún falta el directorio `android/`, luego `flutter pub get`, `flutter analyze`, `flutter test`. La interfaz es preliminar; las dependencias nativas todavía necesitan una compilación real.

La integración de cartografía, geolocalización y repositorios oficiales se realizará en entregas pequeñas y contrastadas.
