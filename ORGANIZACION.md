# ORGANIZACIÓN.md — Cómo está estructurado el proyecto "Zafra"

Este documento explica **qué va en cada carpeta**, **cómo fluye la información** dentro del proyecto, y **cómo agregar contenido nuevo** (cartas, personajes, finales) sin tocar código Dart. Léelo antes de empezar a escribir guion o código.

---

## 1. Filosofía de la arquitectura

El principio más importante de este proyecto es:

> **El contenido narrativo (cartas, personajes, finales) es DATO, no CÓDIGO.**

Todo vive en archivos JSON dentro de `assets/cards/`. El código Dart solo sabe **leer e interpretar** ese contenido. Esto significa que:

- Un guionista puede escribir 300 cartas nuevas sin saber programar.
- Puedes rebalancear el juego editando números en JSON, sin recompilar lógica.
- El "motor de juego" (`lib/domain/game_engine/`) se puede testear con datos de prueba, sin depender del guion final.

La segunda idea importante es la **separación en capas**:

```
presentation/   → lo que el usuario ve y toca (widgets, pantallas)
        ↓ solo lee estado, solo llama funciones del controller
domain/         → las reglas del juego (motor puro, sin Flutter)
        ↓ pide datos
data/           → modelos + de dónde vienen los datos (JSON, futuro backend)
```

Una pantalla (`presentation/`) **nunca** debería calcular si una estadística colapsó, ni leer un JSON directamente. Eso es trabajo de `domain/` y `data/`. Esto permite cambiar la UI por completo (por ejemplo, rehacer todo el diseño visual) sin tocar ni una línea de la lógica del juego.

---

## 2. Mapa completo de carpetas

```
zafra/
├── lib/
│   ├── main.dart                     # Punto de entrada de la app
│   │
│   ├── core/                         # Cosas transversales, sin lógica de negocio
│   │   ├── constants/                # Valores fijos (límites, duraciones, etc.)
│   │   ├── theme/                    # Colores, tipografía, ThemeData de Flutter
│   │   └── utils/                    # Funciones auxiliares genéricas
│   │
│   ├── data/                         # Qué es un dato del juego y de dónde sale
│   │   ├── models/                   # Clases: GameCard, Character, Ending, Stat, Era
│   │   └── repositories/             # Cómo se cargan esos modelos (hoy: JSON de assets)
│   │
│   ├── domain/                       # LAS REGLAS DEL JUEGO (lo más importante)
│   │   └── game_engine/
│   │       ├── game_state.dart       # Estado inmutable de una partida
│   │       ├── card_selector.dart    # Qué carta toca mostrar ahora
│   │       ├── effect_applier.dart   # Qué pasa al elegir izq/der
│   │       ├── ending_resolver.dart  # Qué final corresponde al colapso
│   │       └── game_controller.dart  # Orquesta todo lo anterior (Riverpod)
│   │
│   ├── presentation/                 # UI — lo único que "sabe" de Flutter widgets
│   │   ├── screens/                  # Pantallas completas (GameScreen, EndingScreen)
│   │   └── widgets/                  # Piezas reutilizables (SwipeableCard, StatBar)
│   │
│   └── services/                     # Integraciones externas al dominio del juego
│       ├── persistence/              # Guardado local (Hive / SharedPreferences)
│       └── analytics/                # (futuro) métricas de juego, embudo de abandono
│
├── assets/
│   ├── cards/                        # ⭐ TODO EL CONTENIDO NARRATIVO VIVE AQUÍ
│   │   ├── characters.json           # Elenco de personajes recurrentes
│   │   ├── endings.json              # Finales narrativos
│   │   ├── era_fundacional.json      # Cartas de la Era 1 (con ejemplos ya escritos)
│   │   ├── era_consolidacion.json    # Cartas de la Era 2 (vacío, por escribir)
│   │   ├── era_crisis.json           # Cartas de la Era 3 (vacío, por escribir)
│   │   ├── era_apertura.json         # Cartas de la Era 4 (vacío, por escribir)
│   │   └── era_contemporanea.json    # Cartas de la Era 5 (vacío, por escribir)
│   │
│   ├── images/
│   │   ├── characters/               # Ilustraciones de cada personaje
│   │   ├── backgrounds/              # Fondos por era / por final
│   │   └── icons/                    # Iconos de UI (stats, botones)
│   │
│   └── fonts/                        # Tipografías custom (opcional)
│
├── test/
│   ├── domain/                       # Tests del motor de juego (SIN UI) — los más valiosos
│   └── widgets/                      # Tests de widgets (swipe, barras de stats)
│
├── docs/                             # Documentación de diseño y proceso (ver sección 6)
│
├── pubspec.yaml                      # Dependencias del proyecto
├── analysis_options.yaml             # Reglas de lint
└── ORGANIZACION.md                   # Este archivo
```

---

## 3. Flujo de una decisión (de principio a fin)

Para entender cómo se conecta todo, sigue el recorrido de "el usuario desliza una carta hacia la derecha":

1. **`SwipeableCard`** (presentation/widgets) detecta el gesto y determina que fue swipe derecho.
2. Llama a `onSwiped(SwipeDirection.right)`, que en `GameScreen` está conectado a:
   `ref.read(gameControllerProvider.notifier).choose(SwipeDirection.right)`.
3. **`GameController.choose()`** (domain/game_engine) toma la carta actual y llama a:
   - **`EffectApplier.applyChoice()`** → calcula el nuevo `GameState` (estadísticas actualizadas, clampeadas entre 0-100).
4. Si alguna estadística colapsó:
   - **`EndingResolver.resolve()`** busca en `endings.json` (vía `CardRepository`) el final narrativo correspondiente.
   - La UI muestra `EndingScreen`.
5. Si no colapsó:
   - **`GameController._pickNextCard()`** intenta obtener carta nueva de la era actual vía `CardSelector.selectNext()` (condiciones, pesos, ramificaciones `nextCardId`).
   - Si la era actual ya no tiene cartas nuevas, **avanza de era automáticamente**; si ya no quedan eras con contenido nuevo, **recicla** las cartas vistas y reintenta (ver sección 4.4.1 para el detalle completo de esta regla).
   - La UI vuelve a mostrar `GameScreen` con la nueva carta, y con la era actualizada si hubo avance.

Ninguna de estas piezas de `domain/` importa nada de Flutter (`package:flutter/material.dart`). Eso es intencional: así se pueden testear con `flutter_test` sin levantar ningún widget, y son candidatas perfectas para tests unitarios rápidos.

---

## 4. Cómo agregar contenido nuevo (guía para quien escribe el guion)

### 4.1 Agregar una carta nueva
Abre el archivo de la era correspondiente en `assets/cards/` (ej. `era_crisis.json`) y agrega un objeto siguiendo esta plantilla:

```json
{
  "id": "era3_012",
  "character": "la_economista",
  "era": "crisis",
  "text": "Texto del dilema que ve el jugador.",
  "left": {
    "text": "Texto de la opción izquierda",
    "effects": { "economia": -5, "pueblo": 3 }
  },
  "right": {
    "text": "Texto de la opción derecha",
    "effects": { "economia": 8, "pueblo": -4 }
  },
  "conditions": {
    "min": { "aparatoDelEstado": 20 },
    "max": { "relacionesExteriores": 70 }
  },
  "weight": 1
}
```

**Reglas de nomenclatura de IDs**: `era{número}_{correlativo}`, ej. `era3_012`. Esto evita colisiones entre archivos.

**Campos de `effects` válidos**: `pueblo`, `economia`, `relacionesExteriores`, `aparatoDelEstado`. Todos son opcionales; una carta no necesita afectar las 4.

**`conditions` es opcional**: si la carta debe poder aparecer siempre, simplemente omite el campo completo.

**`weight` es opcional** (por defecto 1): usa números más altos para cartas que deberían aparecer con más frecuencia (situaciones cotidianas) y más bajos para cartas raras/especiales.

### 4.2 Agregar una ramificación (carta que sigue a otra)
En la opción que dispara la ramificación, agrega `"nextCardId": "id_de_la_carta_hija"`. Esa carta hija debe existir en el mismo archivo de era (o en otro, el buscador revisa todas).

### 4.2.1 Asignar una imagen específica a UNA carta (no al personaje completo)
Por defecto, la imagen de una carta es la del personaje (`characters.json` → `imageAsset`). Si quieres que una carta puntual muestre una expresión o pose distinta (ej. "El General" furioso en una carta específica), agrega el campo opcional `"image"` directamente en la carta:

```json
{
  "id": "era1_009",
  "character": "el_general",
  "image": "assets/images/characters/el_general_furioso.png",
  "...": "..."
}
```

Si omites `"image"`, se usa automáticamente la imagen por defecto del personaje — no es obligatorio definirla en cada carta. La resolución de esta prioridad la hace `CardRepository.imageAssetFor(card)`, así que la UI nunca debe leer `character.imageAsset` directamente; siempre debe pasar por ese método.

### 4.3 Agregar un personaje nuevo
Edita `assets/cards/characters.json` y agrega un objeto con `id`, `name`, `role`, `imageAsset`. Luego coloca la ilustración correspondiente en `assets/images/characters/`.

### 4.4 Agregar un final narrativo
Edita `assets/cards/endings.json`. Cada final se vincula a:
- `causedBy`: qué estadística colapsó (`pueblo`, `economia`, `relacionesExteriores`, `aparatoDelEstado`).
- `wasAtMin`: `true` si colapsó por llegar a 0, `false` si fue por llegar a 100.
- `era`: en qué era ocurrió (usa `"generic"` como comodín si aplica a cualquier era y no tienes uno específico).

El motor primero busca un final específico de la era actual; si no lo encuentra, cae automáticamente al final `"generic"` de esa combinación estadística/dirección. Por eso conviene tener **al menos un final genérico por cada una de las 8 combinaciones posibles** (4 estadísticas × 2 direcciones) antes de escribir finales específicos por era.

### 4.4.1 Qué pasa cuando se acaban las cartas de una era (progresión automática)
`GameController._pickNextCard()` implementa esta regla, en este orden:

1. Busca una carta nueva (no vista, que cumpla condiciones) en la **era actual**.
2. Si no encuentra ninguna, **avanza automáticamente a la siguiente era** (según el orden del enum `Era`) y repite la búsqueda ahí.
3. Si llega a la última era (`contemporanea`) y tampoco hay cartas nuevas, **recicla**: olvida qué cartas ya se vieron (`seenCardIds` se limpia) y vuelve a intentar desde la era en la que estaba el jugador, para que el juego nunca se quede "trabado" mostrando la pantalla de "no hay más cartas" — aunque el guion todavía tenga poco contenido escrito.

**Implicación práctica para quien escribe el guion**: mientras una era tenga pocas cartas (ej. solo 8), el jugador la va a "agotar" rápido y pasará a la siguiente era (o reciclará) antes de lo previsto narrativamente. Esto es intencional como red de seguridad técnica, pero **no reemplaza** escribir suficiente contenido por era — la meta de 30-40 cartas por era (ver sección 7) sigue siendo la referencia real de "una era se siente completa".

### 4.5 Flujo de trabajo recomendado para el guion
1. Escribe primero en una hoja de cálculo (Google Sheets) con columnas: `id`, `era`, `personaje`, `texto`, `opción_izq`, `efecto_izq`, `opción_der`, `efecto_der`, `condiciones`, `peso`, `notas`.
2. Cuando una era esté lista, conviértela a JSON (a mano para pocas cartas, o con un script simple de Python/Node para volúmenes grandes) y pégala en el archivo correspondiente.
3. Corre el juego y juega esa era específica para sentir el balance antes de seguir escribiendo la siguiente era.

---

## 5. Cómo agregar código nuevo (guía para quien programa)

| Quiero... | Dónde lo hago |
|---|---|
| Agregar una estadística nueva (poco probable, pero por si acaso) | `data/models/stat.dart` (enum `StatType`) |
| Cambiar cómo se elige la siguiente carta (ej. evitar repetir personaje consecutivo) | `domain/game_engine/card_selector.dart` |
| Cambiar la regla de progresión de era o de reciclaje de cartas | `domain/game_engine/game_controller.dart` (método `_pickNextCard`) |
| Cambiar qué imagen se resuelve para una carta (por personaje o por carta específica) | `data/repositories/card_repository.dart` (método `imageAssetFor`) |
| Cambiar qué pasa al aplicar una decisión (ej. efectos aleatorios) | `domain/game_engine/effect_applier.dart` |
| Agregar una pantalla nueva (menú, configuración, galería de finales) | `presentation/screens/` |
| Agregar un widget visual reutilizable | `presentation/widgets/` |
| Cambiar de dónde se cargan las cartas (ej. desde una API en vez de assets) | `data/repositories/card_repository.dart` — el resto del código no debería enterarse del cambio |
| Guardar un dato nuevo de progreso (ej. racha de días jugados) | `services/persistence/progress_service.dart` |
| Agregar un test de balance del juego | `test/domain/` |

**Regla de oro**: si estás escribiendo `import 'package:flutter/material.dart';` dentro de algo en `domain/`, algo está mal — esa carpeta debe permanecer pura y testeable sin UI.

---

## 6. Carpeta `docs/` — documentación de diseño

Se recomienda mantener aquí (fuera de `lib/`, ya que no es código):

- `DISEÑO_JUEGO.md` — el GDD: estadísticas, eras, tono, personajes, tabla de finales.
- `GUION_MASTER.xlsx` o link a Google Sheets — fuente de verdad del contenido antes de pasar a JSON.
- `REFERENCIAS.md` — investigación histórica/temática usada como inspiración (separada del guion final, para no mezclar research con contenido pulido).
- `DECISIONES_TECNICAS.md` — un registro corto de decisiones de arquitectura relevantes (ej. "por qué Riverpod y no BLoC", "por qué Hive y no sqflite") para que futuras personas en el proyecto entiendan el porqué.

---

## 7. Próximos pasos técnicos sugeridos (en orden)

1. `flutter pub get` para instalar dependencias.
2. `flutter run` — el proyecto ya es jugable con las 8 cartas de ejemplo de la Era Fundacional.
3. `flutter test` — correr el test de ejemplo en `test/domain/game_engine_test.dart`.
4. Completar `era_fundacional.json` hasta 30-40 cartas antes de pasar a la siguiente era.
5. Reemplazar `SwipeableCard` (implementación básica con `GestureDetector`) por una versión pulida con animaciones más suaves, o por el paquete `flutter_card_swiper` si se prefiere no mantener la física del swipe a mano.
6. Agregar ilustraciones reales en `assets/images/` (hoy el juego corre sin ellas, mostrando solo texto).
7. Conectar `ProgressService` a una pantalla de "Finales desbloqueados" (nueva screen en `presentation/screens/`).

---

## 8. Resumen de una línea por carpeta (para memorizar rápido)

- `core/` → cosas transversales sin lógica de negocio (tema, constantes, utils).
- `data/` → qué es un dato del juego y de dónde sale.
- `domain/` → las reglas del juego, puras, testeables, sin Flutter.
- `presentation/` → todo lo visual, lo único que sabe de widgets.
- `services/` → integraciones externas (guardado, analíticas).
- `assets/cards/` → el guion completo del juego, en JSON, editable sin programar.
- `docs/` → diseño y decisiones, no código.