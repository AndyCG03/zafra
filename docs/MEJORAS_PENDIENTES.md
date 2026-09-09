# Mejoras pendientes de Zafra

Este documento reúne mejoras recomendadas para continuar el desarrollo y estabilizar la aplicación.

## Prioridad alta

### Validar la persistencia de partidas

- Probar el cierre y reapertura de la aplicación durante una partida.
- Verificar que se restaure exactamente la carta actual, la era, los días en el poder y las estadísticas.
- Manejar datos guardados corruptos o incompatibles con una versión nueva.
- Guardar también las estadísticas históricas si deben sobrevivir a un reinicio o a varias sesiones.
- Confirmar que la operación de guardado termine antes de abandonar una pantalla o cerrar la aplicación.

### Completar las pruebas automatizadas

- Añadir pruebas para guardar y restaurar `GameState`.
- Probar los contadores de swipes y la línea de tiempo de estadísticas.
- Probar la confirmación de reinicio y la eliminación de la partida guardada.
- Añadir pruebas de interacción para el menú del footer y la pantalla de estadísticas.
- Ejecutar `flutter analyze` y `flutter test` en CI.

### Corregir y verificar el layout de las cartas

- Confirmar en dispositivos pequeños que la carta pueda desplazarse por encima del nombre, footer y demás capas sin recortes.
- Probar gestos en orientación vertical y con diferentes tamaños de pantalla.
- Evitar `RenderFlex overflow` en el header y en el área de cartas.
- Verificar que la card no bloquee accidentalmente los botones del footer cuando no está siendo arrastrada.

## Prioridad media

### Mejorar el menú de opciones

- Conectar completamente la opción de ajustes con preferencias persistentes.
- Añadir una pantalla o contenido de ayuda más completo.
- Cerrar el menú de forma consistente después de abrir otra pantalla.
- Añadir estados visuales para acciones deshabilitadas.

### Mejorar estadísticas

- Definir si los datos son por partida, por sesión o acumulados históricamente.
- Mostrar claramente eras sin turnos registrados.
- Añadir gráficos compactos para la evolución de cada estadística.
- Permitir reiniciar las estadísticas sin borrar necesariamente la partida actual.

### Completar los recursos gráficos

- Crear o incorporar los PNG faltantes de todos los personajes definidos en `assets/cards/characters.json`.
- Revisar proporciones, transparencias y resolución de cada imagen.
- Añadir una imagen de fallback visualmente coherente para recursos ausentes.
- Revisar el logo en pantallas pequeñas para evitar que desplace los botones del menú inicial.

### Revisar textos y localización

- Corregir caracteres con codificación dañada, por ejemplo `EconomÃ­a` o `DÃAS EN EL PODER`.
- Centralizar los textos visibles para facilitar traducciones.
- Mantener una ortografía consistente en nombres, roles y mensajes.

## Prioridad baja

### Arquitectura y mantenimiento

- Separar la serialización de `GameState` en un modelo o servicio dedicado.
- Considerar adaptadores tipados de Hive si el formato guardado sigue creciendo.
- Evitar lógica extensa en widgets y extraer componentes reutilizables.
- Añadir manejo explícito de errores al cargar assets y archivos JSON.
- Documentar las reglas de progresión de eras y reciclaje de cartas.

### Accesibilidad y experiencia de uso

- Añadir etiquetas semánticas a iconos y controles.
- Revisar contraste, tamaños mínimos de toque y escalado de texto.
- Añadir feedback háptico y sonoro real cuando esas preferencias estén activadas.
- Permitir navegación completa con teclado y lectores de pantalla en plataformas compatibles.

### Rendimiento

- Revisar reconstrucciones innecesarias durante el gesto de swipe.
- Precargar o cachear imágenes de personajes y fondos.
- Medir el rendimiento de la animación en dispositivos Android de gama baja.

## Checklist antes de publicar

- [ ] `flutter analyze` sin errores ni advertencias relevantes.
- [ ] `flutter test` completo y estable.
- [ ] Partida restaurada correctamente tras cerrar y abrir la aplicación.
- [ ] Reinicio confirmado y partida guardada eliminada correctamente.
- [ ] Todas las cartas tienen assets válidos o un fallback intencional.
- [ ] No hay overflow visual en tamaños de pantalla soportados.
- [ ] Textos revisados y codificación UTF-8 correcta.
- [ ] Pruebas manuales en Android y, si corresponde, iOS/web.
