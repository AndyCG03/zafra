# Enriquecer las cartas de Zafra — qué agregar + prompt de verificación

## 1. Qué le falta a tu esquema actual de carta

Hoy cada carta (`GameCard`) tiene: `id`, `character`, `era`, `text`, `left`/`right` (con `effects` y `nextCardId` opcional), `conditions` (min/max de estadísticas), `weight`, e `image` opcional. Es una base sólida, pero **no tiene memoria de nada más allá de la estadística numérica** — no sabe qué decisiones tomaste, no sabe cuánto favoreciste a un personaje, no puede disparar algo "más adelante".

Para las 4 mecánicas que pediste, necesitas agregar **4 campos nuevos** al esquema de carta, todos opcionales (no rompen las cartas que ya tienes escritas):

### 1.1 `setFlags` — para consecuencias diferidas
Lista de flags que se activan cuando el jugador elige esa opción. Ya tienes `requiresFlags`/`excludesFlags` en `conditions`, pero ninguna carta hoy **produce** un flag — solo los consumen. Esto es lo que falta para cerrar el círculo.

```json
"left": {
  "text": "Cierra el distrito",
  "effects": { "aparatoDelEstado": 7, "pueblo": -7 },
  "setFlags": ["represion_distrito"]
}
```

### 1.2 `delayTurns` (a nivel de carta "consecuencia") — para que aparezca N turnos después
En vez de intentar programar un temporizador complejo, la forma más simple y consistente con tu arquitectura actual (cartas como dato) es: la carta de consecuencia usa `requiresFlags` + un nuevo campo `minTurnsAfterFlag`, indicando cuántos turnos deben pasar desde que se activó el flag antes de que esta carta sea elegible.

```json
{
  "id": "era3_020",
  "character": "el_extranjero",
  "text": "Los exiliados de aquella represión organizan un ataque.",
  "conditions": {
    "requiresFlags": ["represion_distrito"],
    "minTurnsAfterFlag": { "represion_distrito": 8 }
  },
  "left": { "text": "...", "effects": {...} },
  "right": { "text": "...", "effects": {...} }
}
```
Esto requiere que `GameState` guarde `Map<String, int> flagSetAtTurn` (turno en que se activó cada flag) en vez de solo un `Set<String>`.

### 1.3 `characterId` + contador de apariciones — para "consejeros con agenda propia"
No necesitas un campo nuevo en la carta para esto — necesitas que `GameState` lleve un `Map<String, int> characterFavorCount` (cuántas veces el jugador eligió la opción que "favorece" a cada personaje). Lo que sí necesitas en la carta es marcar **qué opción favorece a qué personaje**, porque no siempre es intuitivo automáticamente:

```json
"right": {
  "text": "Moviliza soldados",
  "effects": { "aparatoDelEstado": 6, "pueblo": -7 },
  "favorsCharacter": "el_general"
}
```
Con eso, cartas especiales de "traición/golpe de estado" pueden usar una condición nueva: `"minFavorCount": {"el_general": 6}`.

### 1.4 `memoryVariants` — para que un personaje recuerde decisiones pasadas
En vez de reescribir el motor para generar texto dinámico (complejo y frágil), la solución que más rinde con tu arquitectura de "contenido es dato" es: **la misma carta tiene variantes de texto según flags activos**, elegidas en orden de prioridad.

```json
{
  "id": "era2_014",
  "character": "la_lider_vecinal",
  "text": "Los barrios piden más autonomía para decidir sus propias obras.",
  "memoryVariants": [
    {
      "requiresFlags": ["ignoro_tierras_era1"],
      "text": "Desde que ignoraste el reparto de tierras, los barrios ya no confían en pedirte nada directamente — pero insisten en decidir sus propias obras."
    }
  ],
  "left": {...},
  "right": {...}
}
```
Si ningún `memoryVariant` aplica, se usa el `text` normal. Esto te permite escribir 5-10 variantes de "memoria" por personaje sin tener que duplicar cartas completas.

### 1.5 Campo adicional recomendado: `rare` (ya lo estás usando)
Ya veo que tus JSON usan `"rare": true` en varias cartas (`era4_rescate_relaciones`, `era2_rescate_economia`, etc.) — pero **tu `GameCard.fromJson` actual no lee ese campo** (no está en el modelo que me compartiste). Falta conectarlo. Sugiero usarlo para dos cosas:
- Marcar visualmente la carta como especial en la UI (ej. borde distinto).
- Multiplicar su importancia narrativa, no su probabilidad — el `weight` bajo (1) ya baja su frecuencia; `rare` es más una etiqueta para la UI/analítica que para el algoritmo de selección.

---

## 2. Resumen de campos nuevos por nivel

| Nivel | Campo nuevo | Tipo | Para qué |
|---|---|---|---|
| `CardCondition` | `minTurnsAfterFlag` | `Map<String, int>` | Consecuencias diferidas |
| `CardCondition` | `minFavorCount` | `Map<String, int>` | Cartas de traición/golpe de estado por personaje favorecido |
| `CardOption` | `setFlags` | `List<String>` | Disparar flags al elegir esa opción |
| `CardOption` | `favorsCharacter` | `String?` | Registrar qué personaje se favorece con esa elección |
| `GameCard` | `memoryVariants` | `List<MemoryVariant>` | Texto alternativo si el jugador tiene ciertos flags |
| `GameCard` | `rare` | `bool` (ya usado en JSON, falta en el modelo) | Marcar visualmente cartas especiales |
| `GameState` | `flagSetAtTurn` | `Map<String, int>` | Saber CUÁNDO se activó un flag, no solo SI está activo |
| `GameState` | `characterFavorCount` | `Map<String, int>` | Saber cuánto se favoreció a cada personaje |

---

## 3. Prompt para el agente (verificación + implementación)

Copia y pega esto en tu sesión con el agente que tiene acceso a tu repo (Claude Code, Cursor, etc.):

```
Necesito que audites y, donde falte, implementes un enriquecimiento del
esquema de cartas de este juego Flutter (Reigns-like). El objetivo son
4 mecánicas: consecuencias diferidas, personajes con agenda propia
(favor/traición), eventos raros de alto impacto, y memoria narrativa
(texto que cambia según decisiones pasadas). NO modifiques el guion de
las cartas ya escritas — solo el motor y el modelo de datos, de forma
retrocompatible (las cartas actuales sin estos campos deben seguir
funcionando exactamente igual).

PASO 1 — AUDITORÍA (reporta antes de cambiar nada)
Revisa estos archivos y dime, para cada uno, si YA soporta lo listado
o si falta:
- lib/data/models/game_card.dart
  · ¿Lee el campo "rare" del JSON? (los JSON de assets/cards/ ya lo
    usan en varias cartas, ej. "era4_rescate_relaciones")
  · ¿Existe algo parecido a "setFlags" en CardOption?
  · ¿Existe algo parecido a "favorsCharacter" en CardOption?
  · ¿Existe algo parecido a "memoryVariants" a nivel de GameCard?
- lib/data/models/game_card.dart -> CardCondition
  · ¿Existe "minTurnsAfterFlag" o equivalente?
  · ¿Existe "minFavorCount" o equivalente?
- lib/domain/game_engine/game_state.dart
  · ¿El estado guarda CUÁNDO se activó cada flag (turno), o solo SI
    está activo (Set<String>)?
  · ¿Existe algún contador de "favor" por personaje?
- lib/domain/game_engine/card_selector.dart
  · ¿La lógica de elegibilidad ya contempla condiciones más allá de
    min/max de estadísticas y flags simples?
- lib/domain/game_engine/effect_applier.dart
  · ¿Aplica setFlags al elegir una opción?
  · ¿Actualiza contadores de favor por personaje?

PASO 2 — IMPLEMENTAR LO QUE FALTE (retrocompatible)
Si algo de lo anterior falta, impleméntalo así:

1. GameCard / CardOption / CardCondition (data/models/game_card.dart):
   - Agrega campo `bool rare` (default false) a GameCard, leído de
     json['rare'].
   - Agrega `List<String> setFlags` (default []) a CardOption, leído
     de json['setFlags'].
   - Agrega `String? favorsCharacter` a CardOption, leído de
     json['favorsCharacter'].
   - Agrega `List<MemoryVariant> memoryVariants` (default []) a
     GameCard. Cada MemoryVariant tiene `requiresFlags: Set<String>` y
     `text: String`. Agrega un método `GameCard.resolvedText(Set<String>
     activeFlags)` que devuelve la primera memoryVariant cuyas
     requiresFlags estén todas en activeFlags, o el `text` normal si
     ninguna aplica.
   - En CardCondition, agrega `Map<String, int> minTurnsAfterFlag` y
     `Map<String, int> minFavorCount`, ambos parseados desde JSON de
     forma opcional (default {}).

2. GameState (domain/game_engine/game_state.dart):
   - Cambia (o complementa) el registro de flags para incluir CUÁNDO
     se activaron: agrega `Map<String, int> flagSetAtTurn`.
   - Agrega `Map<String, int> characterFavorCount`.
   - Actualiza copyWith para soportar ambos campos nuevos.

3. EffectApplier (domain/game_engine/effect_applier.dart):
   - Al aplicar una opción elegida: por cada flag en
     option.setFlags que NO esté ya en el estado, agrégalo a
     seenFlags/flags Y registra el turno actual en flagSetAtTurn.
   - Si option.favorsCharacter no es null, incrementa en 1
     characterFavorCount[esa carta].

4. CardSelector (domain/game_engine/card_selector.dart):
   - En _matchesConditions, agrega la verificación de
     minTurnsAfterFlag: la carta solo es elegible si
     (turnoActual - flagSetAtTurn[flag]) >= minTurnsRequerido para
     CADA flag en ese mapa (y el flag debe existir, si no existe la
     condición falla).
   - Agrega verificación de minFavorCount: la carta solo es elegible
     si characterFavorCount[personaje] >= el mínimo requerido, para
     cada entrada del mapa.

PASO 3 — VALIDAR RETROCOMPATIBILIDAD
Corre (o simula mentalmente) los JSON ya existentes en assets/cards/
(characters.json, endings.json, era_*.json) contra el modelo
actualizado y confírmame explícitamente que:
- Ninguna carta existente se rompe por falta de estos campos nuevos
  (todos deben tener valores por defecto seguros).
- El campo "rare" que ya usan varias cartas (busca "rare": true en los
  JSON) ahora se lee correctamente en el modelo.

PASO 4 — TESTS
Agrega o actualiza tests en test/domain/ que cubran:
- Una carta con setFlags activa correctamente el flag y registra el
  turno.
- Una carta con minTurnsAfterFlag NO es elegible antes del turno
  requerido, y SÍ lo es después.
- Una carta con minFavorCount respeta el conteo de favor acumulado.
- resolvedText() devuelve la variante correcta según flags activos, y
  cae al texto normal si ninguna variante aplica.

DELIVERABLE
Al terminar, dame un resumen corto: qué ya existía, qué implementaste,
y qué archivos tocaste.
```

---

## 4. Ejemplo concreto aplicado a TUS cartas actuales

Para que veas cómo se vería con tu contenido real (usando `era3_002` de `era_crisis.json`, que ya trata sobre saqueos):

```json
{
  "id": "era3_002",
  "character": "el_general",
  "era": "crisis",
  "text": "Hay saqueos en un depósito de combustible.",
  "left": {
    "text": "Envía mediadores",
    "effects": { "pueblo": 4, "aparatoDelEstado": -5 }
  },
  "right": {
    "text": "Cierra el distrito",
    "effects": { "aparatoDelEstado": 7, "pueblo": -7 },
    "setFlags": ["represion_distrito"],
    "favorsCharacter": "el_general"
  },
  "weight": 3
}
```

Y la carta de consecuencia (nueva, la escribes tú en `era_crisis.json` o `era_contemporanea.json`):

```json
{
  "id": "era3_020",
  "character": "el_extranjero",
  "era": "crisis",
  "text": "Antiguos vecinos del distrito cerrado piden ayuda para reorganizarse en el exilio.",
  "conditions": {
    "requiresFlags": ["represion_distrito"],
    "minTurnsAfterFlag": { "represion_distrito": 8 }
  },
  "left": { "text": "Ofrece amnistía", "effects": { "pueblo": 8, "aparatoDelEstado": -5 } },
  "right": { "text": "Ignora la petición", "effects": { "aparatoDelEstado": 4, "pueblo": -6 } },
  "weight": 2
}
```

Y una variante de memoria en OTRA carta de La Líder Vecinal, más adelante:

```json
{
  "id": "era4_020",
  "character": "la_lider_vecinal",
  "era": "apertura",
  "text": "El barrio pide reconstruir su centro comunitario.",
  "memoryVariants": [
    {
      "requiresFlags": ["represion_distrito"],
      "text": "Nadie olvida el distrito que cerraste durante la crisis. Aun así, el barrio pide reconstruir su centro comunitario."
    }
  ],
  "left": {...},
  "right": {...}
}
```

---

## 5. Prioridad recomendada de implementación

1. **`setFlags` + `minTurnsAfterFlag`** (consecuencias diferidas) — el mayor impacto narrativo por menor esfuerzo técnico, y ya tienes la base de `flags`/`requiresFlags` construida.
2. **`memoryVariants`** — reutiliza cartas que ya vas a escribir de todos modos, solo les agregas una variante de texto.
3. **`favorsCharacter` + `minFavorCount`** (agenda de personajes) — el más interesante narrativamente, pero el que más cartas nuevas de "traición" necesita para sentirse completo (recomiendo 1 por personaje principal como mínimo: General, Economista, Diplomático, Líder Vecinal).
4. **`rare`** — es el más barato (solo conectar un campo que ya usas en el JSON), hazlo primero aunque sea rápido, de paso que estás en el modelo.
