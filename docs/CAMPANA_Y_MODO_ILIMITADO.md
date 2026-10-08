# La isla después de ti

## Cómo jugar

En las partidas nuevas puedes elegir Historia, Normal o Desafío. Normal conserva el balance anterior. Historia reduce la presión de las pérdidas y de las subidas hacia el máximo; Desafío aumenta las pérdidas y modera las ganancias. La dificultad se guarda con cada partida, se conserva al reiniciar y no cambia al continuar un guardado. Los guardados anteriores usan Normal.

La campaña mantiene 40 decisiones por recorrido. Cuatro encuentros exclusivos sustituyen audiencias cotidianas: apertura del muelle cooperativo o cena del operador exclusivo, declaración de un oficial si el General es rival y protección de un testigo si encontraste pruebas del desvío. Sus respuestas cambian recursos, confianza y los titulares posteriores. Al pasar de acto se abre «El Faro de la Isla», con noticias de tus decisiones, rumores de la Cantinera y vida cotidiana. Leerlo no consume decisiones; una edición pendiente se conserva al cerrar el juego.

«Relaciones», en el menú y en la agenda, permite abrir fichas de los personajes conocidos: confianza, intereses, acuerdos registrados y decisiones recientes. Los compromisos del agua, del gobierno civil y del puerto muestran su cumplimiento o ruptura junto al interlocutor correspondiente.

En ilimitado, desde la decisión 12, la agenda ofrece proyectos de barrios, ingenio o sucesión civil. Elegir uno no consume un turno. Hay diez decisiones para lograr cuatro avances: mejoras al Pueblo, mejoras a la Economía o mejoras al Pueblo sin aumentar el aparato del Estado, respectivamente. Los efectos condicionales también cuentan. Completarlo acerca cada indicador hasta tres puntos al equilibrio; no rescata una barra que ya haya colapsado. Vencer el plazo no elimina el gobierno. Tras terminar, seis decisiones de descanso preceden a una nueva convocatoria. Plazo, progreso y número de proyectos completados se guardan.

El cierre destaca hasta tres decisiones del mandato, según sus consecuencias, cambios de confianza, promesas y desenlace. Se conservan fuera de la crónica de 60 entradas para no perderlas en gobiernos largos. Los guardados antiguos recuperan las que aún estén en su crónica. Las pistas del cierre orientan hacia otras decisiones sin revelar una receta completa para cada final.

En «Elegir modo» puedes iniciar o continuar una campaña o un gobierno ilimitado. Cada modo tiene un guardado independiente. Iniciar otra partida del mismo modo pide confirmar el reemplazo. Las partidas antiguas se recuperan como ilimitadas; mantienen sus decisiones y los finales que ya hubieran alcanzado.

Al empezar eliges una promesa: agua común, soberanía del puerto o gobierno civil. Su cumplimiento aparece en la agenda y en el legado final. La promesa civil exige consejos locales, consulta del puerto y un pacto público con los barrios; militarizar estos servicios o dar privilegios al General la rompe.

## Campaña

40 decisiones enlazadas, en seis actos. La historia conserva un orden común, pero cada opción modifica indicadores, relaciones, textos posteriores y evidencias. No introduce crisis aleatorias entre escenas. Puedes caer antes del desenlace si un indicador alcanza 0 o 100; las pérdidas de la campaña son más suaves que las del modo ilimitado.

1. **La promesa y la marea:** repartir el agua y reconstruir el muelle.
2. **La cosecha que no llegó:** elegir operador y afrontar la carga perdida.
3. **El precio de la confianza:** auditar al General y proteger al testigo.
4. **Quién puede preguntar:** inspección, rumores y negociación pública.
5. **Lo que puede probarse:** contrastar documentos y muestras, publicar o reservar.
6. **La isla después de ti:** claves del puerto, reparación y sucesión.

## Investigación

«La cosecha desaparecida» tiene ocho escenas. Con una cooperativa, el rastro lleva a una autorización de la escolta; con un operador exclusivo, a una cláusula de compensación. Copiar libros o negociar su acceso recupera documentos. El barco identificado por la Cantinera permite contrastarlos con muestras. Publicar sin completar esa cadena crea una acusación incierta, con un coste propio; publicar pruebas verificadas revela el desvío. También puedes reservar el expediente o abrir un archivo reparador.

## Confianza, memoria y humor

La confianza va de −5 a +5. Desde +3 hay confianza; desde −3, rivalidad. Las propuestas de los principales representantes también cambian sus relaciones en las cartas cotidianas. La Líder Vecinal puede ayudar durante protestas y negociaciones; su pacto necesita presupuesto y reuniones públicas. El General puede retirar escoltas cuando desconfía o exigir excepciones a las auditorías a cambio de apoyar al gobierno.

Reservar agua a los barrios reaparece en el contrato de exportación. La radio de la Cantinera y la ventanilla del Vagabundo regresan transformadas en escenas posteriores. La crónica conserva el texto que viste, tu elección y las consecuencias condicionales; muestra además el expediente de la cosecha. Se limita a 60 decisiones para mantener pequeño el guardado ilimitado.

## Ilimitado y desenlaces

El turno 96 ya no termina un gobierno. Los compromisos narrativos llegan con sus plazos y eras, intercalados con asuntos cotidianos y crisis. Las crisis vuelven a estar disponibles tras completar su ciclo. Los capítulos cerrados no se repiten. Al resolver agua, puerto e investigación puedes entregar el gobierno voluntariamente o seguir jugando.

Cinco desenlaces especiales reflejan el legado: transición pactada, comunidad autónoma, dependencia de acreedores, cosecha encubierta y continuidad del gobernante. Permanecer en palacio cierra la campaña con ese desenlace; en ilimitado mantiene el gobierno activo. Los finales por colapso siguen disponibles en ambos modos.

## Mantenimiento

`python tool/write_campaign_content.py` regenera los tres archivos narrativos a partir del guion. El generador antiguo delega en este para conservar las ampliaciones. No ejecutar el generador después de editar directamente sus JSON sin trasladar esos cambios al guion.

Pruebas en `test/domain/campaign_test.dart`: campaña completa, continuidad y separación de guardados, investigación por ambos operadores, respaldo y retirada de aliados, consecuencias cruzadas, promesas, desenlaces y migración. El catálogo también valida personajes, imágenes y referencias de consecuencias.

Los cinco finales tienen ilustraciones vectoriales propias, dibujadas por `EndingArt` y compartidas por el desenlace, la galería y el epílogo. Los archivos JSON conservan una imagen de respaldo para herramientas que solo lean el catálogo.

## La isla y sus habitantes

«La isla que construyes» está en el menú del gobierno y en la agenda. El mapa permite tocar cinco zonas: acequia, barrios, ingenio, puerto y plaza. Cambian el canal, los depósitos, las colas, las brigadas, los talleres, los barcos, la biblioteca o la estatua según tus decisiones. Consultarlo no consume turnos ni recursos.

Seis interludios explican la inundación que marcó a la Líder Vecinal, la brigada que reconstruye la casa de la madre del General y la salida de la hija de la Cantinera. Ambas respuestas tienen una continuación; no existe una opción que cierre el contenido personal. El apoyo a aprendices reduce una compensación posterior y la mediación facilita proteger una audiencia pública. Sus costes moderados mantienen jugables los cinco finales.

«Cinco años después» se abre desde el desenlace. Cuenta qué pasó con los barrios y esos tres personajes a partir de las decisiones guardadas. Reconoce también las caídas tempranas y no inventa acuerdos que no se jugaron. Las campañas guardadas con el guion anterior recuperan su posición por el identificador estable de la carta, aunque ahora haya más escenas antes de ella.
