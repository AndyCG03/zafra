import '../../data/models/era.dart';
import '../../data/models/stat.dart';
import '../../data/models/game_card.dart';
import '../../data/models/game_mode.dart';
import '../../data/models/decision_record.dart';
import 'game_state.dart';
import 'island_chronicle.dart';
import '../../data/models/game_difficulty.dart';

/// Formato compatible con partidas anteriores, sin depender de Hive ni de UI.
class GameStateCodec {
  static Map<String, dynamic> encode(GameState state) => {
        'mode': state.mode.name,
        'difficulty': state.difficulty.name,
        'newspaperAct': state.newspaperAct,
        'project': state.project?.name,
        'projectProgress': state.projectProgress,
        'projectDeadline': state.projectDeadline,
        'nextProjectTurn': state.nextProjectTurn,
        'projectsCompleted': state.projectsCompleted,
        'promise': state.promise?.name,
        'campaignIndex': state.campaignIndex,
        'characterTrust': state.characterTrust,
        'history': state.history.map((e) => e.toJson()).toList(),
        'definingDecisions':
            state.definingDecisions.map((e) => e.toJson()).toList(),
        'stats': {
          for (final e in state.stats.entries)
            e.key.index.toString(): e.value.value
        },
        'era': state.currentEra.index,
        'turn': state.turn,
        'days': state.daysInPower,
        'seen': state.seenCardIds.toList(),
        'flags': state.flags.toList(),
        'flagSetAtTurn': state.flagSetAtTurn,
        'characterFavorCount': state.characterFavorCount,
        'pendingConsequences':
            state.pendingConsequences.map((e) => e.toJson()).toList(),
        'lastNarrativeTurn': state.lastNarrativeTurn,
        'lastEventEndedTurn': state.lastEventEndedTurn,
        'unlocked': state.unlockedCharacterIds.toList(),
        'rescue': state.usedRescuePowers.map((e) => e.index).toList(),
        'availableRescue':
            state.availableRescuePowers.map((e) => e.index).toList(),
        'pending': state.pendingNextCardId,
        'activeEvent': state.activeEventId,
        'eventPlayed': state.eventCardsPlayed,
        'eventCards': state.activeEventCardIds,
        'securityCompromises': state.securityCompromises,
        'assassinationCountdown': state.assassinationCountdown,
      };

  static GameState decode(Map<String, dynamic> data) {
    final stats = data['stats'] as Map? ?? const {};
    final eraIndex = _number(data['era'], 0).clamp(0, Era.values.length - 1);
    return GameState(
      difficulty: GameDifficulty.values
              .where((d) => d.name == data['difficulty'])
              .firstOrNull ??
          GameDifficulty.normal,
      newspaperAct: _number(data['newspaperAct'], 0),
      project: IslandProject.values
          .where((p) => p.name == data['project'])
          .firstOrNull,
      projectProgress: _number(data['projectProgress'], 0).clamp(0, 4),
      projectDeadline: _number(data['projectDeadline'], 0),
      nextProjectTurn: _number(data['nextProjectTurn'], 12),
      projectsCompleted: _number(data['projectsCompleted'], 0),
      mode: GameMode.values.where((m) => m.name == data['mode']).firstOrNull ??
          GameMode.endless,
      promise: GovernmentPromise.values
          .where((p) => p.name == data['promise'])
          .firstOrNull,
      campaignIndex: _number(data['campaignIndex'], 0).clamp(0, 1 << 30),
      characterTrust:
          (_counts(data['characterTrust'] ?? data['characterFavorCount']))
              .map((key, value) => MapEntry(key, value.clamp(-5, 5))),
      history: (data['history'] as List? ?? const [])
          .map((e) =>
              DecisionRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      definingDecisions: (data['definingDecisions'] as List? ?? const [])
          .map((e) =>
              DecisionRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .take(3)
          .toList(),
      stats: {
        for (final type in StatType.values)
          type: Stat(type,
              _number(stats[type.index.toString()], Stat.initial).clamp(0, 100))
      },
      currentEra: Era.values[eraIndex],
      turn: _number(data['turn'], 0).clamp(0, 1 << 30),
      daysInPower: _number(data['days'], 1).clamp(1, 1 << 30),
      seenCardIds: _strings(data['seen']).toSet(),
      flags: _strings(data['flags']).toSet(),
      flagSetAtTurn: _counts(data['flagSetAtTurn']),
      characterFavorCount: _counts(data['characterFavorCount']),
      pendingConsequences: (data['pendingConsequences'] as List? ?? const [])
          .map((e) =>
              PendingConsequence.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      lastNarrativeTurn: _number(data['lastNarrativeTurn'], -3),
      lastEventEndedTurn: _number(data['lastEventEndedTurn'], -4),
      unlockedCharacterIds: _strings(data['unlocked']).toSet(),
      usedRescuePowers: _powers(data['rescue']),
      availableRescuePowers: _powers(data['availableRescue']),
      pendingNextCardId: data['pending'] as String?,
      activeEventId: data['activeEvent'] as String?,
      eventCardsPlayed: _number(data['eventPlayed'], 0),
      activeEventCardIds: _strings(data['eventCards']),
      securityCompromises: _number(data['securityCompromises'], 0),
      assassinationCountdown: (data['assassinationCountdown'] as num?)?.toInt(),
    );
  }

  static int _number(dynamic value, int fallback) =>
      value is num ? value.toInt() : fallback;
  static List<String> _strings(dynamic raw) =>
      (raw as List? ?? const []).whereType<String>().toList();
  static Map<String, int> _counts(dynamic raw) => {
        for (final entry in (raw as Map? ?? const {}).entries)
          if (entry.key is String && entry.value is num)
            entry.key as String: (entry.value as num).toInt(),
      };
  static Set<StatType> _powers(dynamic raw) => {
        for (final index in (raw as List? ?? const [])
            .whereType<num>()
            .map((e) => e.toInt()))
          if (index >= 0 && index < StatType.values.length)
            StatType.values[index],
      };
}
