# Zafra: historias que regresan

Implementación del 7 de octubre de 2026, a partir de la autorización para seguir la propuesta. Complementa la revisión técnica inicial.

Este documento describe la primera ampliación. La versión posterior añade campaña, modo ilimitado, investigación, confianza y crónica; su descripción vigente está en [CAMPANA_Y_MODO_ILIMITADO.md](CAMPANA_Y_MODO_ILIMITADO.md). El catálogo actual tiene 216 cartas principales y 16 finales.

## La nueva partida

Un ciclón dañó la acequia y el muelle. La primera decisión reparte el agua entre los barrios y el ingenio. La reconstrucción del puerto aparece después, antes de que las consecuencias del agua vuelvan a pedir una respuesta. Los dos problemas acompañan al gobierno a través de las seis eras.

| Arco | Recorrido | Decisión final |
|---|---|---|
| Agua, ocho capítulos | Reparto inicial → factura → fuga → recirculación → cosecha → sequía → administración → renovación | Red común o concesión regulada |
| Puerto, ocho capítulos | Financiación → condiciones → operador → huelga → obligaciones → consulta → licencia → automatización | Control de las claves o dependencia del proveedor |

Cada capítulo posterior tiene dos variantes que recuerdan la elección relevante anterior. Las rutas convergen en nuevos dilemas: ninguna elección inicial bloquea la partida ni obliga a repetir la misma política hasta el final. Se mantienen costes y beneficios explícitos en las cuatro estadísticas.

Los 16 capítulos y la advertencia de seguridad están en `assets/cards/arcos_narrativos.json`. Se cargan como contenido obligatorio y reutilizan el elenco y sus ilustraciones. El catálogo principal contiene 198 cartas: 181 de era, 16 capítulos y una advertencia. El tutorial y las 120 decisiones disponibles de eventos se mantienen separados.

## Consecuencias, agenda y memoria

- Una opción puede programar varias consecuencias mediante `scheduleCards`. Cada compromiso tiene un destino, un título legible y un plazo mínimo.
- Los compromisos se guardan con la partida. Mostrarlos no los elimina: responderlos sí. No se duplican ni se reprograman capítulos completados.
- Los capítulos no salen del mazo aleatorio y no reaparecen al reciclar cartas cotidianas.
- Se respeta la era mínima de cada capítulo y se dejan dos decisiones entre audiencias narrativas. Una crisis en curso termina antes de retomar la agenda.
- La agenda explica si un asunto espera su plazo, una era posterior o una audiencia. También muestra los personajes cuyas propuestas has respaldado; ese contador no afirma que exista una simulación completa de lealtad.
- Las partidas antiguas continúan con su carta actual y reciben el inicio del arco cuando haya un momento disponible.
- El epílogo describe el legado del agua y el puerto y los asuntos que quedan para el siguiente gobierno, incluso en una derrota. Los once finales existentes conservan sus identificadores y su galería.

## Crisis y peligro

Los eventos conservan su primera decisión y su cierre. Entre ambos se eligen dos momentos, ordenados como en el contenido: cuatro decisiones por aparición, frente a las cinco a ocho escenas antes barajadas. Tras cerrar un evento hay cuatro decisiones de pausa antes de otra crisis aleatoria. Los eventos pedidos explícitamente por una opción conservan su activación; una audiencia narrativa no los cancela.

La probabilidad base de una crisis aleatoria pasa a 4 %, más 3 puntos por cada indicador afectado negativamente por la opción. Los sucesos ya vistos no vuelven a dispararse en la misma partida. Las cartas de la era actual pesan tres veces su peso ordinario, para que el nuevo contenido no quede diluido entre todas las eras previas.

La segunda reducción peligrosa de la escolta ofrece una audiencia inmediata: reforzarla cuesta reservas y cancela el atentado; rechazar la advertencia mantiene el plazo anunciado. La cabecera y la agenda muestran el riesgo restante. Este estado se conserva al reabrir la aplicación.

## Balance medido

Se simularon cien semillas por política y multiplicador, con el controlador real, los eventos y los nuevos capítulos. La política estratégica elige la opción que deja los indicadores más cerca de 50, evita las trampas de escolta y usa los rescates disponibles. La política aleatoria también usa los rescates. Son políticas automatizadas; estos resultados no equivalen a una prueba de diversión con jugadores.

| Multiplicador de pérdidas | Media de decisiones, azar | Supervivencia, azar | Media, estrategia | Supervivencia, estrategia | Puerto completado, estrategia |
|---|---:|---:|---:|---:|---:|
| 1,50 | 28,79 | 0/100 | 81,17 | 44/100 | 59/100 |
| **1,45, elegido** | **33,36** | **0/100** | **93,11** | **86/100** | **92/100** |
| 1,40 | 34,95 | 0/100 | 94,67 | 92/100 | 97/100 |

Las ganancias conservan su multiplicador 1,15 y el objetivo sigue en 96 decisiones. Se probaron también pérdidas de 1,25 y 1,15; la política estratégica completó las cien partidas en ambas alternativas. Se eligió 1,45 para ampliar el espacio narrativo y mantener derrotas incluso con una estrategia sistemática.

La tabla corresponde a la implementación final, incluidos los eventos solicitados explícitamente. La prueba de simulación imprime las mediciones vigentes al ejecutarse.

## Verificación y trabajo posterior

Se añadieron pruebas de agenda, guardado compatible, plazos, eras, ambas rutas completas, ausencia de capítulos aleatorios, orden de eventos, amenaza de atentado, restauración de la advertencia y pausa entre crisis. La validación del catálogo comprueba los destinos programados y las referencias a personajes e imágenes.

Resultado: 35 pruebas aprobadas, análisis estático sin incidencias, compilación web de producción correcta y revisión de diferencias sin errores de formato.

La vista previa web se verificó a 320 × 568 y al tamaño habitual del navegador: inicio, tutorial omitido, introducción, primera decisión del agua, dos decisiones cotidianas, primera audiencia del puerto, agenda y restauración tras recargar. Se comprobaron los indicadores, los plazos y la memoria de personajes. Se corrigió el contraste de títulos de capítulo y del epílogo, se añadieron desplazamiento y reinicio del texto por carta, y el menú se hizo desplazable. No hubo errores ni advertencias en la consola durante la comprobación final. La vista previa actual queda en `http://localhost:8081/`; el guardado anterior de `127.0.0.1` se conserva separado por origen.

La siguiente mejora creativa sigue siendo probar el juego con personas y revisar qué decisiones resultan demasiado obvias. La ampliación posterior ya incorpora confianza, consecuencias cruzadas, investigación y un historial consultable; consulta el documento vigente enlazado arriba.
