import '../../data/models/era.dart';
import '../../data/models/stat.dart';

class GameState {
  final Map<StatType, Stat> stats;
  final Era currentEra;
  final int turn;
  final int daysInPower;
  final Set<String> seenCardIds;
  final Set<String> flags;
  final Set<String> unlockedCharacterIds;
  final Set<StatType> availableRescuePowers;
  final Set<StatType> usedRescuePowers;
  final String? pendingNextCardId;
  final String? activeEventId;
  final int eventCardsPlayed;
  final List<String> activeEventCardIds;

  GameState({
    required this.stats,
    required this.currentEra,
    required this.turn,
    required this.daysInPower,
    required this.seenCardIds,
    required this.flags,
    required this.unlockedCharacterIds,
    this.availableRescuePowers = const {},
    required this.usedRescuePowers,
    this.pendingNextCardId,
    this.activeEventId,
    this.eventCardsPlayed = 0,
    this.activeEventCardIds = const [],
  });

  factory GameState.initial() => GameState(
        stats: {for (final type in StatType.values) type: Stat(type, Stat.initial)},
        currentEra: Era.fundacional,
        turn: 0,
        daysInPower: 1,
        seenCardIds: {},
        flags: {},
        unlockedCharacterIds: {},
        usedRescuePowers: {},
      );

  Stat statOf(StatType type) => stats[type]!;
  bool get hasCollapsed => stats.values.any((s) => s.isCollapsed);
  StatType? get collapsedStat {
    for (final stat in stats.values) {
      if (stat.isCollapsed) return stat.type;
    }
    return null;
  }

  GameState copyWith({
    Map<StatType, Stat>? stats,
    Era? currentEra,
    int? turn,
    int? daysInPower,
    Set<String>? seenCardIds,
    Set<String>? flags,
    Set<String>? unlockedCharacterIds,
    Set<StatType>? availableRescuePowers,
    Set<StatType>? usedRescuePowers,
    String? pendingNextCardId,
    bool clearPendingNextCardId = false,
    String? activeEventId,
    bool clearActiveEvent = false,
    int? eventCardsPlayed,
    List<String>? activeEventCardIds,
  }) => GameState(
        stats: stats ?? this.stats,
        currentEra: currentEra ?? this.currentEra,
        turn: turn ?? this.turn,
        daysInPower: daysInPower ?? this.daysInPower,
        seenCardIds: seenCardIds ?? this.seenCardIds,
        flags: flags ?? this.flags,
        unlockedCharacterIds: unlockedCharacterIds ?? this.unlockedCharacterIds,
        availableRescuePowers: availableRescuePowers ?? this.availableRescuePowers,
        usedRescuePowers: usedRescuePowers ?? this.usedRescuePowers,
        pendingNextCardId: clearPendingNextCardId ? null : (pendingNextCardId ?? this.pendingNextCardId),
        activeEventId: clearActiveEvent ? null : (activeEventId ?? this.activeEventId),
        eventCardsPlayed: clearActiveEvent ? 0 : (eventCardsPlayed ?? this.eventCardsPlayed),
        activeEventCardIds: clearActiveEvent ? const [] : (activeEventCardIds ?? this.activeEventCardIds),
      );
}
