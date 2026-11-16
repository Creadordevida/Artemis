# Producto Artemis — 2026-11-16
## Objetivo
Adolescentes en Navarra: saber dónde están, encontrar ayuda física y telefónica, entender qué hacer cuando no pueden definir su problema. La app debe servir tanto en la vida diaria como en emergencias.

## Principio UX
Abrir → ubicación/mapa → ayuda y contactos → ruta o llamada. El mapa se dibuja con datos locales sin bloqueo por red. Si la posición no se obtiene, nunca fingir que se conoce. El teléfono debe ser accesible siempre.

## Diseño aprobado
Escudo blanco con localizador y estrella de cuatro puntas en fondo casi negro/azul noche, sin trazos verdes. Estética sobria, elegante, de contraste alto, tipografía grande, iconos con etiquetas, acciones previsibles, pantalla central con mapa e iconos. Nombre ARTEMIS; lema «Ayuda cuando la necesitas».

## Alcance primera fase (orden)
1. UI útil, permisos de ubicación y mensajes seguros.
2. Motor de mapa vectorial offline y paquete Navarra; validar tamaño real.
3. Índice local de recursos oficiales (sanidad, urgencias, policía foral, nacional, local, Guardia Civil, farmacias, atención a menores), horarios separados por tipo y fecha.
4. Ranking según servicio prestado y disponibilidad documentada, nunca solo distancia euclidiana.
5. Rutas peatonales offline con detección de rutas no verificadas.
6. Guías breves revisadas contra fuentes oficiales y rutas de «No sé qué hacer».
7. Actualizaciones de datos públicos y alertas de AEMET/DGT/protección civil cuando existan fuentes autorizadas; sin prometer cobertura completa.
8. Linterna con cámara/flash si hardware compatible, pantalla iluminada como reserva.
9. Validación externa de seguridad, privacidad y accesibilidad antes de lanzamiento.

## Requisitos no funcionales
- Objetivo 200–300 MB instalados (a medir con datos cartográficos concretos).
- Arranque y ayuda inmediata, mapas base y recursos locales sin Internet.
- ES / EU desde un diseño localizable, sin contenido inventado.
- Ningún mensaje final sin acción alternativa.
- No requiere registro; ubicación local por defecto.
- Emergencias 112 visibles, llamadas condicionadas a red telefónica.
- No recoger ni compartir datos de menores sin base, consentimiento adecuado y revisión legal.

## Fuera de alcance al principio
Diagnóstico médico; predicción de incidentes; avisos policiales no públicos; promesas de recursos abiertos en directo; IA generativa determinando urgencias; navegación segura garantizada en rutas no validadas.


## Regla de directorio público (16/11/2026)
Mostrar únicamente puntos físicos de gestión pública verificada: centros de SNS-O, municipal y otras administraciones públicas, Policía Foral y Guardia Civil. Nunca incluir centros sanitarios privados por el mero hecho de figurar en datos abiertos. Excluir farmacias privadas del directorio físico mientras rija esta regla.
La enfermera del Consejo Sanitario (948 290 290) tiene acceso destacado en la pantalla principal, como alternativa para dudas sanitarias no urgentes. No sustituye al 112.
