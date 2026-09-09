<p align="center">
  <img src="assets/images/logo/horizontal%20dorado.png" alt="Zafra" height="96">
</p>

<p align="center"><strong>Un juego narrativo de decisiones sobre gobernar una isla caribeña ficticia.</strong></p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-0F1720?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.3.0-0F1720?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Plataformas-6-BC8A3D" alt="Seis plataformas">
  <a href="../../releases/latest"><img src="https://img.shields.io/badge/latest_release-Releases-BC8A3D?logo=github" alt="Latest release"></a>
</p>

## Zafra, en una decisión

**Zafra** es un juego narrativo de decisiones para Flutter, inspirado en *Reigns* y *Lapse*. El jugador gobierna una isla caribeña ficticia y debe equilibrar las tensiones entre el pueblo, la economía, las relaciones exteriores y el aparato del Estado.

Cada carta presenta un dilema. Las decisiones modifican las estadísticas del gobierno, desbloquean personajes y pueden abrir caminos narrativos distintos. El objetivo es atravesar todas las eras sin permitir que ninguna estadística llegue a un extremo crítico.

## Estado actual del contenido

<table>
  <tr>
    <td align="center"><strong>31</strong><br>personajes</td>
    <td align="center"><strong>142</strong><br>cartas de era</td>
    <td align="center"><strong>6</strong><br>eventos</td>
    <td align="center"><strong>10</strong><br>finales narrativos</td>
  </tr>
</table>

- **31 personajes** con nombre, rol, biografía e ilustración asociada.
- **142 cartas de era** distribuidas entre cinco etapas históricas.
- **6 cartas de eventos** para situaciones especiales.
- **10 finales narrativos**, incluido 1 final de supervivencia.
- Recursos gráficos y música incluidos en `assets/`.
- Guardado local del progreso, finales descubiertos y estadísticas globales.

### Eras

| Era | Cartas | Personajes que se incorporan |
| :--- | ---: | ---: |
| Fundacional | 26 | 12 |
| Consolidación | 27 | 7 |
| Crisis | 28 | 5 |
| Apertura | 25 | 3 |
| Contemporánea | 36 | 3 |

El Creador funciona como personaje especial y puede aparecer en cualquier era.

## Cómo se juega

1. Lee el dilema de la carta actual.
2. Desliza la carta o elige una de las dos opciones.
3. Observa cómo cambia el equilibrio de las cuatro estadísticas: **Pueblo**, **Economía**, **Relaciones Exteriores** y **Aparato del Estado**.
4. Continúa gobernando, desbloquea nuevas eras y procura que ninguna estadística colapse.

Las cartas pueden tener condiciones, pesos de aparición, ramificaciones y efectos distintos según la opción elegida. Si una estadística llega a 0 o 100, el motor resuelve el final correspondiente. Si se atraviesan todas las eras sin colapso, se obtiene **La isla resiste**.

## Requisitos

- Flutter estable con Dart `>=3.3.0 <4.0.0`.
- Un dispositivo o emulador configurado para la plataforma elegida.

## Ejecutar el proyecto

Desde la raíz del repositorio:

```bash
flutter pub get
flutter run
```

Para elegir un dispositivo concreto:

```bash
flutter devices
flutter run -d <id-del-dispositivo>
```

La aplicación incluye configuraciones para Android, iOS, Linux, macOS, Windows y Web, siempre que el entorno local tenga instalado el SDK correspondiente.

## Ejecutar las pruebas

```bash
flutter analyze
flutter test
```

La lógica principal del juego está separada de la interfaz y se prueba en `test/domain/`.

## Estructura del proyecto

```text
lib/
├── core/                 # Tema y utilidades comunes
├── data/                 # Modelos y repositorios de contenido JSON
├── domain/game_engine/   # Reglas, selección de cartas y finales
├── presentation/         # Pantallas y widgets de Flutter
└── services/             # Persistencia local y audio

assets/
├── cards/                # Contenido narrativo en JSON
├── images/               # Personajes, fondos, iconos, logos y finales
└── music/                # Música y efectos de sonido

test/                     # Pruebas unitarias y de widgets
docs/                     # Diseño, guion y tareas pendientes
```

El contenido narrativo es dato, no código: las cartas, personajes y finales se editan en `assets/cards/` sin modificar el motor Dart. Consulta [ORGANIZACION.md](ORGANIZACION.md) para conocer el flujo completo de una decisión y las convenciones para agregar contenido.

## Archivos de contenido principales

- `assets/cards/characters.json`: elenco, roles, biografías e imágenes.
- `assets/cards/endings.json`: condiciones y textos de los finales.
- `assets/cards/era_*.json`: cartas de cada era.
- `assets/cards/events.json`: eventos especiales.
- `assets/cards/el_creador.json`: mensajes del Creador.

Las rutas de estos recursos están declaradas en `pubspec.yaml`. Las imágenes y los sonidos deben conservar sus rutas para que Flutter pueda empaquetarlos correctamente.

## Documentación adicional

- [ORGANIZACION.md](ORGANIZACION.md): arquitectura, flujo de datos y guía para escribir cartas.
- [docs/MEJORAS_PENDIENTES.md](docs/MEJORAS_PENDIENTES.md): tareas técnicas y de contenido conocidas.
- [docs/FINALES_IMAGENES.md](docs/FINALES_IMAGENES.md): especificaciones visuales de los finales.
- [docs/PERSONAJES_A_GENERAR.md](docs/PERSONAJES_A_GENERAR.md): referencias para ilustraciones de personajes.

## Licencia

El proyecto no declara todavía una licencia de distribución.
