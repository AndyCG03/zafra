# Zafra v1.1.0 — La isla después de ti

## Novedades

- Campaña de seis actos y 40 escenas conectadas. Las decisiones cambian las pruebas, las relaciones y los desenlaces.
- Modo ilimitado sin final automático en el turno 96. Cada modo conserva su propio guardado.
- Tres promesas de gobierno: agua común, puerto soberano y gobierno civil.
- Confianza y rivalidades con efectos reales en protestas, negociaciones y apoyo militar.
- Historias del agua y del puerto, consecuencias cruzadas e investigación «La cosecha desaparecida» con dos cadenas de pruebas.
- Seis decisiones personales sobre la Líder Vecinal, el General y la Cantinera, además de escenas de humor cotidiano.
- Mapa interactivo de cinco zonas que refleja obras, colas, control del puerto y políticas de gobierno.
- Agenda y crónica de las últimas 60 decisiones, con consulta del expediente de la cosecha.
- Cinco finales políticos con ilustraciones vectoriales originales y epílogo «Cinco años después».
- Catálogo ampliado a 222 cartas principales y 16 finales.

## Correcciones

Mejoras de guardado y restauración, protección frente a decisiones duplicadas, rescates y finales consistentes, progreso de eras, orden de crisis, preferencias de audio, accesibilidad y lectura en pantallas pequeñas. Los guardados anteriores se conservan; las campañas recuperan su escena por el identificador de la carta.

## Descargar y jugar

- **Android:** elige el APK adecuado a tu dispositivo; `app-arm64-v8a-release.apk` corresponde a teléfonos Android modernos. El AAB está destinado a distribución mediante tiendas.
- **Web:** `zafra-v1.1.0-web.zip` contiene el juego compilado. Extrae el ZIP y sírvelo por HTTP, por ejemplo con `python -m http.server 8081 --directory <carpeta-extraída>`; abre `http://localhost:8081/`.

Durante la partida, toca «Días en el poder» para abrir el menú y consultar «La isla que construyes». Al terminar, pulsa «Cinco años después» para leer el epílogo. Puedes continuar o iniciar cada modo desde «Elegir modo».

## Verificación

51 pruebas aprobadas, incluidos recorridos completos que alcanzan los cinco finales especiales, separación de guardados, migración de la campaña y revisión de mapa y epílogo a 320 × 568. Análisis estático sin incidencias y compilación web de producción comprobada.
