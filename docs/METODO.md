# Método de trabajo Artemis
## Ramas
- main: base estable y documentada; nunca prometer funcionalidades no validadas.
- develop: integración incremental.
- feat/*: una capacidad por rama y PR hacia develop.
- release/*: congelación para QA y candidato APK.

## Ciclo de microfase
1. Definir necesidad del adolescente y el fallo peligroso a evitar.
2. Redactar criterios de aceptación y alternativas cuando falten datos.
3. Implementar módulo mínimo con interfaces claras y datos de prueba identificados.
4. Probar unitariamente, estática, accesibilidad y simulación sin red.
5. Probar en dispositivo Android real: permisos, GPS, modo avión, consumo y latencia.
6. Recoger captura REAL y trazabilidad de los datos.
7. Documentar resultados, limitaciones, siguiente tarea y SHA.
8. Fusionar solo cuando la fase supera sus pruebas.

## Política de progreso
`docs/ESTADO.md` = fuente de verdad. Estados: planeado / iniciado / implementado no verificado / validado en dispositivo / publicado. Cada entrada indica evidencia y bloqueos.

## Métricas (objetivos, no hechos)
- Mostrar interfaz útil casi inmediatamente; mapa visible en 1–2 s en dispositivo objetivo.
- Buscar datos locales en menos de 1 s.
- Llegar a teléfono o ficha de ayuda desde inicio con una o dos acciones.
- Paquete completo Navarra 200–300 MB medido después de generar mapas y rutas.
- 0 estados sin alternativa útil.

## Fuentes
Registro de fuente/licencia/update por recurso. Descargas oficiales normalizadas mediante scripts reproducibles, sin mezclar datos reales con inventados. Verificar condiciones de uso, calidad espacial y periodicidad.

## No hacer
No vender prototipo como app de emergencia; no habilitar alerts de apariencia oficial inventadas; no medir APK en capturas generadas; no meter secretos en GitHub público.
