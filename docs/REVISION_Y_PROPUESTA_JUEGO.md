# Zafra: revisión técnica y propuesta de juego

La propuesta de agua y puerto ya está incorporada. Consulta [la implementación narrativa y su validación](MEJORAS_NARRATIVAS_IMPLEMENTADAS.md). El diagnóstico que sigue conserva los hallazgos de la revisión inicial.

Revisión del 7 de octubre de 2026. El proyecto es Flutter/Dart, no Remotion. Se revisaron el motor, los modelos, los repositorios, persistencia, audio, pantallas, gestos, pruebas, contenido JSON, documentación y configuración de publicación. Los cambios anteriores del usuario en `character.dart`, `.gitignore` y `.metadata` se conservaron.

## Diagnóstico

Zafra tiene identidad visual, un elenco ilustrado y dilemas adecuados para partidas breves. Su principal oportunidad es convertir decisiones aisladas en una historia reconocible. Actualmente el jugador equilibra barras y recibe incidentes; pocas cosas explican cómo el país llegó a ese estado.

El inventario previo a la revisión contenía 182 entradas de cartas de era, **181 identificadores únicos**, 37 personajes, 8 eventos de 15 decisiones cada uno, 11 finales y 35 cartas de era raras. Había dos versiones de la misma carta de epidemia. Se conservó la versión que inicia el evento en ambas respuestas, porque ambas son respuestas al mismo brote. La documentación de 142 cartas y cinco eras estaba desactualizada.

| Era | Cartas únicas | Comienza en turno |
|---|---:|---:|
| Fundacional | 32 | 0 |
| Consolidación | 30 | 12 |
| Crisis | 33 | 26 |
| Apertura | 29 | 42 |
| Contemporánea | 39 | 60 |
| Futurista | 18 | 78 |

La supervivencia se resuelve ahora en el turno 96. Antes se resolvía al llegar al 78: el jugador desbloqueaba el futuro y terminaba inmediatamente.

Al comienzo de la revisión, ninguna carta de era utilizaba `nextCardId`, memoria de decisiones o condiciones por banderas. Las ilustraciones referenciadas por el contenido existen. Estos resultados describen el inventario inicial; no garantizan por sí mismos buen balance ni ausencia de errores visuales en todos los dispositivos.

## Correcciones implementadas

- Finales: se guarda y restaura su identificador. Las partidas antiguas colapsadas recuperan su final cuando no hay un rescate pendiente. Reabrir un final no vuelve a sumar el mandato al historial.
- Resolución: un final de supervivencia queda excluido de la selección por colapso. Antes, Pueblo al máximo en la era contemporánea podía producir una victoria accidental.
- Decisiones: una protección contra llamadas simultáneas evita aplicar dos veces la misma carta mientras se escribe el progreso. Una crisis pendiente bloquea nuevas decisiones.
- Rescates: recuperan 22 puntos hacia el centro; 100 baja a 78 y 0 sube a 22. Se consumen una vez, respetan otros colapsos y completan el turno y el evento sin repetir la decisión ni perder la posición de su secuencia. Rechazar un rescate también guarda el final.
- Tutorial: sus avances asincrónicos se esperan; al restaurar la visita a opciones no se introduce una carta normal. Se guardan las aperturas y los reinicios.
- Cartas: las ramificaciones respetan condiciones, eras y cartas vistas; conocer un personaje no adelanta cartas futuras. Pesos cero o negativos quedan fuera del sorteo.
- Eventos: las decisiones que indican expresamente `startsEvent` no se pierden en los primeros turnos ni repiten un evento ya visto. Una rama válida tiene prioridad frente a un incidente aleatorio. Se conserva la carta del Creador cuando se ha seleccionado su continuación.
- Carga: los archivos obligatorios ya no fallan silenciosamente. La pantalla principal de juego puede reintentar la carga. Las cargas concurrentes comparten la misma operación.
- Rendimiento: el catálogo de cartas se construye una vez, se devuelve como vista inmutable y los identificadores se buscan en un mapa. Los eventos se cargan una vez y sus cartas se indexan. Son mejoras estructurales; no se ha medido aún el rendimiento en móviles de gama baja.
- Audio: se aplican al inicio volumen, sonido y vibración guardados. La música respeta el silencio y puede iniciarse al volver a la aplicación.
- Interfaz: el texto de dilemas puede desplazarse, el encabezado tiene un alto mínimo y el menú inicial permite desplazamiento en pantallas pequeñas. Los indicadores muestran peligro y exponen nombre, valor y advertencia al lector de pantalla. Se retiró código sin uso y se sustituyeron APIs visuales obsoletas.
- Pruebas: se sustituyó el test de contador de Flutter, que apuntaba a una clase inexistente, por pruebas de componentes del juego. Se agregaron pruebas de selección, memoria, guardado, rescates, restauración y referencias del catálogo.

## Soporte narrativo listo para usar

El guion existente conserva sus textos y efectos, salvo la eliminación de la entrada duplicada. Los campos nuevos son opcionales:

| Campo | Uso |
|---|---|
| `setFlags` en una opción | Recordar una decisión |
| `clearFlags` en una opción | Resolver o revocar una promesa |
| `favorsCharacter` en una opción | Acumular concesiones a un personaje |
| `minTurnsAfterFlag` en condiciones | Habilitar una consecuencia tras una espera mínima |
| `minFavorCount` en condiciones | Habilitar una petición de un aliado fortalecido |
| `memoryVariants` en una carta | Mostrar el primer texto que coincida con los recuerdos activos |

El turno de activación se registra al terminar la decisión: una bandera activada en el turno 5 con espera 3 habilita su consecuencia desde el 8. Volver a activar una bandera existente no reinicia el reloj; borrarla y activarla de nuevo sí. Las partidas antiguas siguen cargando sin estos campos.

**Habilitar no equivale a programar:** una consecuencia habilitada entra al sorteo y puede tardar más en aparecer. Para promesas con una fecha exacta recomiendo una futura cola de consecuencias obligatorias con límite de una por turno. Ese planificador todavía no está implementado. El motor también cuenta favores, no confianza, miedo ni lealtad: esos conceptos necesitarían un modelo posterior.

## Dirección creativa recomendada: la isla recuerda

Mantendría el formato de dos decisiones y la estética actual. Añadiría una pregunta central: **¿qué estás dispuesto a sacrificar para que la próxima cosecha llegue a todos?** La zafra pasa a conectar la economía, las familias, la seguridad y las relaciones exteriores.

Inicio propuesto: un ciclón destruyó parte del puerto. En doce decisiones vence un acuerdo de suministros y debe empezar la primera cosecha. La Economista necesita divisas; la Líder Vecinal exige agua; el General quiere controlar el transporte; el Diplomático ofrece un acuerdo que compromete el puerto. Todos tienen una razón defendible y un precio.

La fecha de doce decisiones es una propuesta de guion y requiere el planificador descrito antes; no existe todavía un objetivo o reloj de cosecha en el juego.

### Cuatro arcos que atraviesan las eras

| Arco | Primera decisión | Consecuencia | Giro y cierre |
|---|---|---|---|
| El puerto hipotecado | Aceptar un adelanto extranjero o financiar reparaciones locales | Llegan suministros, pero aparece una cláusula de exclusividad; la reparación local tarda y sostiene empleo | El Diplomático ocultó una garantía. Renegociar con una cooperativa, cumplir la concesión o romper el acuerdo tiene costes distintos |
| El agua de la cosecha | Priorizar riego o barrios | Más exportaciones con malestar urbano, o mejor salud con cosecha menor | La Ingeniera descubre pérdidas de la red. Financiar una reparación evita escoger siempre entre las mismas víctimas |
| El amigo imprescindible | Delegar al General la distribución de emergencia o mantener control civil | El reparto militar es rápido y aumenta su influencia; el civil necesita apoyo vecinal | Tras varias concesiones pide poderes permanentes. Una alianza con la Jurista y el Sindicalista ofrece otra salida |
| Las cuentas del palacio | Investigar un desvío o encubrirlo para evitar una crisis | Cambia quién confía en ti y quién conserva pruebas | La Periodista descubre que una persona próxima también se benefició. Asumir responsabilidad, sacrificar al funcionario o reparar el daño produce legados diferentes |

Cada arco necesita aproximadamente 6–8 cartas: presentación, compromiso, dos consecuencias, giro y dos cierres posibles. Empezaría con **el puerto y el agua**, entre 12 y 16 cartas nuevas, y variantes en unas ocho cartas existentes. Probaría ese bloque antes de escribir los otros dos arcos. Más personajes o más cartas sueltas no son la primera prioridad.

### Personajes con deseo, límite y contradicción

- La Economista quiere evitar el hambre; acepta medidas impopulares, pero no vender reservas esenciales. Puede reconocer que su primer plan falló.
- El General quiere un país estable; teme volver al caos y confunde eficacia con derecho a mandar. Debe existir una relación de cooperación sana, además de una ruta autoritaria.
- La Líder Vecinal exige dignidad para su barrio; también debe responder cuando protegerlo perjudica a otra comunidad.
- El Diplomático quiere abrir la isla; busca prestigio internacional y puede ocultar condiciones para cerrar un acuerdo.
- La Periodista quiere pruebas y reparación; puede publicar contra tu voluntad o reconocer una respuesta transparente.
- La Ingeniera propone soluciones prácticas; necesita recursos, tiempo y permiso para contradecir a quienes financian las obras.

Elegir la izquierda o la derecha no debe significar siempre rechazar o apoyar al interlocutor. `favorsCharacter` permite marcar la concesión explícitamente. No convertiría automáticamente una cifra de favor en traición: fortalecer a alguien debe abrir oportunidades, obligaciones y riesgos previsibles.

### Ejemplo de secuencia

1. La Economista: «El ingenio puede arrancar esta semana, pero necesita el agua de dos barrios. Si espera, perderemos el barco de exportación». Elegir riego activa `agua_para_ingenio`; elegir barrios activa `agua_para_barrios`.
2. Tres turnos después puede aparecer la Líder Vecinal: «El barco zarpó lleno. En mi calle llevamos tres días sin agua». Reparar tuberías cuesta dinero y resuelve el conflicto; enviar cisternas alivia a corto plazo y deja una obligación futura.
3. En Consolidación, la Ingeniera recuerda la decisión y ofrece recircular agua industrial. Invertir cuesta ahora, pero habilita una cosecha menos dependiente del racionamiento.
4. En Crisis, la cooperación previa permite coordinar depósitos vecinales. Si se abandonó el compromiso, la petición comienza con desconfianza y ofrece salidas más costosas.

El efecto divertido es reconocer «esto ocurrió por lo que hice» y descubrir que una decisión dolorosa puede abrir una solución mejor. Se incluye una muestra de tres cartas en `PROPUESTA_CARTAS_AGUA.json`, fuera del catálogo publicado, para revisar tono, campos y costes. Las cifras son una primera hipótesis editorial, no un balance validado.

### Ritmo y dificultad

Los eventos actuales encadenan 5–8 decisiones elegidas al azar entre quince. Esa mezcla puede interrumpir una promesa o presentar fases fuera de orden. Propongo eventos de 3–4 cartas con apertura, respuesta y cierre, y variantes internas según decisiones; dos crisis obligatorias no deberían ocurrir consecutivamente.

Mantendría alrededor de dos decisiones cotidianas por cada decisión de arco principal. El humor debe surgir del carácter de la isla y del elenco, con pequeñas victorias entre los problemas. Una petición doméstica también puede recordar una promesa importante.

Las pérdidas se multiplican hoy por 1,50 y las ganancias por 1,15. Además, una opción con efectos negativos puede iniciar otra crisis aleatoria. Esa combinación puede castigar incluso decisiones razonables. No cambié los multiplicadores sin una medición de balance: propongo comparar políticas aleatorias, decisiones que evitan extremos y partidas humanas. El objetivo inicial sería un primer mandato de 12–20 decisiones para jugadores nuevos y una llegada al futuro alcanzable con aprendizaje. Es una meta de diseño pendiente de validación.

Antes de un asesinato deberían aparecer una advertencia del Guardaespaldas y una opción de reparación. La regla actual de dos reducciones de seguridad y cuatro decisiones de espera es demasiado difícil de deducir. Del mismo modo, la interfaz debe explicar por qué el máximo de una barra es peligroso: hay que distinguir bienestar de concentración de poder.

### Eras y desenlaces

Cada era necesita una pregunta reconocible: fundar instituciones, repartir prosperidad, superar una escasez, abrirse al exterior, revisar el legado y decidir quién controla el futuro. Las cartas antiguas pueden volver como asuntos pendientes; después de un cambio de era conviene dar mayor presencia al contenido nuevo.

Hay una incoherencia temporal: los días avanzan de uno a seis por decisión mientras las eras saltan de fundación a inteligencia artificial. Propongo presentar capítulos de una historia nacional y sucesión de gobiernos, o redefinir las eras como etapas del mandato. La elección debe hacerse antes de ampliar el guion.

Mantendría los finales de derrota y añadiría un epílogo de tres frases que mencione dos decisiones y una persona afectada. Un final puede mostrar un país mejor aunque el protagonista pierda el cargo. La supervivencia debería variar por legado —autonomía, prosperidad compartida, dependencia o vigilancia—, para que repetir tenga un propósito más allá de durar más. Este epílogo y sus rutas todavía son propuestas.

## Orden de la siguiente versión

1. Revisar la muestra del agua y escribir los arcos de agua y puerto. Añadir señales previas para seguridad y barras extremas.
2. Implementar un registro visible de promesas y una cola limitada para consecuencias con fecha. Requiere nuevos widgets y nuevas reglas, todavía no incluidos.
3. Ordenar y acortar los eventos; medir balance antes de modificar dificultad o frecuencia.
4. Escribir epílogos y cierres alternativos; después ampliar relaciones de personajes.
5. Añadir análisis y tests al flujo de publicación. Actualmente el flujo compila y publica, pero no exige estas pruebas. No se sobrescribieron configuraciones de CI ni dependencias.

## Verificación y límites

Resultados: `flutter analyze --no-pub` sin incidencias, `flutter test --no-pub` con 26 pruebas aprobadas, `flutter build web --no-pub` completado y `git diff --check` sin problemas de espacios. La batería cubre catálogo, selección, memoria, serialización retrocompatible, doble decisión, finales restaurados, rescate superior, dos colapsos simultáneos, rechazo de rescate, continuidad de eventos y acceso a la era futurista.

Se comprobó la aplicación compilada en navegador con vistas de 360×640 y 320×568: menú, tutorial, omisión del tutorial, introducción, desbloqueo de personaje, dilema, deslizamiento y restauración. Después de comprar vacunas, se conservó al recargar el turno 1, día 5, Pueblo 58, Economía 42 y la misma carta de la Líder Vecinal. No se observaron errores o advertencias de consola en ese recorrido. La vista previa local queda disponible en `http://127.0.0.1:8081` mientras siga ejecutándose el servidor.

Queda pendiente una sesión humana en Android/iOS para validar sonido real, vibración, gestos, textos grandes, rendimiento, diversión y balance. Las mejoras de disposición reducen problemas conocidos, pero no sustituyen esa revisión. Las otras cinco plataformas no se han compilado en esta revisión.
