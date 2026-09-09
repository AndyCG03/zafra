# Mensajes del creador y estadisticas globales

El juego busca los mensajes en `assets/cards/creator_messages.json`. El archivo debe ser una lista ordenada por `minGames`:

```json
[
  {
    "minGames": 0,
    "message": "Primero aprende a leer el equilibrio de la isla."
  },
  {
    "minGames": 3,
    "message": "Ya conoces el precio de improvisar. Mira qué parámetro estás sacrificando."
  },
  {
    "minGames": 6,
    "message": "Tus mandatos anteriores dejaron patrones. Usa las cartas de rescate cuando aparezcan."
  }
]
```

Al comenzar una partida nueva se muestra una conversación con el creador y se selecciona el mensaje con el mayor `minGames` que no supere la cantidad de partidas ya iniciadas. Si el JSON no existe o tiene un formato inválido, se usa un mensaje de respaldo y la partida sigue funcionando.

## Estadisticas globales persistentes

Hive guarda en `app_statistics`:

- `games`: partidas iniciadas.
- `turns`: turnos acumulados de mandatos terminados.
- `left` y `right`: decisiones acumuladas.
- `bestMandates`: las tres duraciones más largas, ordenadas de mayor a menor.

Estos datos son globales de la aplicación y no se borran al reiniciar una partida. El estado temporal de una partida continúa guardándose por separado en `game_state`.
