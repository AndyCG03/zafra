import '../../data/models/era.dart';
import '../../data/models/game_difficulty.dart';
import 'island_chronicle.dart';
import '../../data/models/stat.dart';
import '../../data/models/game_card.dart';
import '../../data/models/game_mode.dart';
import '../../data/models/decision_record.dart';

class GameState {
  final GameMode mode;
  final GameDifficulty difficulty;
  final int newspaperAct;
  final IslandProject? project;
  final int projectProgress;
  final int projectDeadline;
  final int nextProjectTurn;
  final int projectsCompleted;
  final GovernmentPromise? promise;
  final int campaignIndex;
  final Map<String, int> characterTrust;
  final List<DecisionRecord> history;
  final List<DecisionRecord> definingDecisions;
  PromiseStatus? get promiseStatus => promise?.status(flags);
  final List<PendingConsequence> pendingConsequences;
  final int lastNarrativeTurn;
  final int lastEventEndedTurn;
  final Map<StatType, Stat> stats;
  final Era currentEra;
  final int turn;
  final int daysInPower;
  final Set<String> seenCardIds;
  final Set<String> flags;
  final Map<String, int> flagSetAtTurn;
  final Map<String, int> characterFavorCount;
  final Set<String> unlockedCharacterIds;
  final Set<StatType> availableRescuePowers;
  final Set<StatType> usedRescuePowers;
  final String? pendingNextCardId;
  final String? activeEventId;
  final int eventCardsPlayed;
  final List<String> activeEventCardIds;
  final int securityCompromises;
  final int? assassinationCountdown;

  GameState({
    this.mode = GameMode.endless,
    this.difficulty = GameDifficulty.normal,
    this.newspaperAct = 0,
    this.project,
    this.projectProgress = 0,
    this.projectDeadline = 0,
    this.nextProjectTurn = 12,
    this.projectsCompleted = 0,
    this.promise,
    this.campaignIndex = 0,
    this.characterTrust = const {},
    this.history = const [],
    this.definingDecisions = const [],
    this.pendingConsequences = const [],
    this.lastNarrativeTurn = -3,
    this.lastEventEndedTurn = -4,
    required this.stats,
    required this.currentEra,
    required this.turn,
    required this.daysInPower,
    required this.seenCardIds,
    required this.flags,
    this.flagSetAtTurn = const {},
    this.characterFavorCount = const {},
    required this.unlockedCharacterIds,
    this.availableRescuePowers = const {},
    required this.usedRescuePowers,
    this.pendingNextCardId,
    this.activeEventId,
    this.eventCardsPlayed = 0,
    this.activeEventCardIds = const [],
    this.securityCompromises = 0,
    this.assassinationCountdown,
  });

  factory GameState.initial(
          {GameMode mode = GameMode.endless,
          GovernmentPromise? promise,
          GameDifficulty difficulty = GameDifficulty.normal}) =>
      GameState(
        mode: mode,
        difficulty: difficulty,
        promise: promise,
        stats: {
          for (final type in StatType.values) type: Stat(type, Stat.initial)
        },
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
    GameMode? mode,
    GameDifficulty? difficulty,
    int? newspaperAct,
    IslandProject? project,
    bool clearProject = false,
    int? projectProgress,
    int? projectDeadline,
    int? nextProjectTurn,
    int? projectsCompleted,
    GovernmentPromise? promise,
    int? campaignIndex,
    Map<String, int>? characterTrust,
    List<DecisionRecord>? history,
    List<DecisionRecord>? definingDecisions,
    List<PendingConsequence>? pendingConsequences,
    int? lastNarrativeTurn,
    int? lastEventEndedTurn,
    Map<StatType, Stat>? stats,
    Era? currentEra,
    int? turn,
    int? daysInPower,
    Set<String>? seenCardIds,
    Set<String>? flags,
    Map<String, int>? flagSetAtTurn,
    Map<String, int>? characterFavorCount,
    Set<String>? unlockedCharacterIds,
    Set<StatType>? availableRescuePowers,
    Set<StatType>? usedRescuePowers,
    String? pendingNextCardId,
    bool clearPendingNextCardId = false,
    String? activeEventId,
    bool clearActiveEvent = false,
    int? eventCardsPlayed,
    List<String>? activeEventCardIds,
    int? securityCompromises,
    int? assassinationCountdown,
    bool clearAssassinationCountdown = false,
  }) =>
      GameState(
        mode: mode ?? this.mode,
        difficulty: difficulty ?? this.difficulty,
        newspaperAct: newspaperAct ?? this.newspaperAct,
        project: clearProject ? null : project ?? this.project,
        projectProgress: projectProgress ?? this.projectProgress,
        projectDeadline: projectDeadline ?? this.projectDeadline,
        nextProjectTurn: nextProjectTurn ?? this.nextProjectTurn,
        projectsCompleted: projectsCompleted ?? this.projectsCompleted,
        promise: promise ?? this.promise,
        campaignIndex: campaignIndex ?? this.campaignIndex,
        characterTrust: characterTrust ?? this.characterTrust,
        history: history ?? this.history,
        definingDecisions: definingDecisions ?? this.definingDecisions,
        pendingConsequences: pendingConsequences ?? this.pendingConsequences,
        lastNarrativeTurn: lastNarrativeTurn ?? this.lastNarrativeTurn,
        lastEventEndedTurn: lastEventEndedTurn ?? this.lastEventEndedTurn,
        stats: stats ?? this.stats,
        currentEra: currentEra ?? this.currentEra,
        turn: turn ?? this.turn,
        daysInPower: daysInPower ?? this.daysInPower,
        seenCardIds: seenCardIds ?? this.seenCardIds,
        flags: flags ?? this.flags,
        flagSetAtTurn: flagSetAtTurn ?? this.flagSetAtTurn,
        characterFavorCount: characterFavorCount ?? this.characterFavorCount,
        unlockedCharacterIds: unlockedCharacterIds ?? this.unlockedCharacterIds,
        availableRescuePowers:
            availableRescuePowers ?? this.availableRescuePowers,
        usedRescuePowers: usedRescuePowers ?? this.usedRescuePowers,
        pendingNextCardId: clearPendingNextCardId
            ? null
            : (pendingNextCardId ?? this.pendingNextCardId),
        activeEventId:
            clearActiveEvent ? null : (activeEventId ?? this.activeEventId),
        eventCardsPlayed:
            clearActiveEvent ? 0 : (eventCardsPlayed ?? this.eventCardsPlayed),
        activeEventCardIds: clearActiveEvent
            ? const []
            : (activeEventCardIds ?? this.activeEventCardIds),
        securityCompromises: securityCompromises ?? this.securityCompromises,
        assassinationCountdown: clearAssassinationCountdown
            ? null
            : (assassinationCountdown ?? this.assassinationCountdown),
      );
}
