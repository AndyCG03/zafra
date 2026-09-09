import '../../data/models/era.dart';
import '../../data/models/stat.dart';
import 'effect_applier.dart';

class StatChangeRecord {
  const StatChangeRecord({
    required this.turn,
    required this.era,
    required this.direction,
    required this.before,
    required this.after,
  });

  final int turn;
  final Era era;
  final SwipeDirection direction;
  final Map<StatType, int> before;
  final Map<StatType, int> after;

  int changeFor(StatType type) => after[type]! - before[type]!;
}

class GameStatistics {
  const GameStatistics({
    this.totalTurns = 0,
    this.leftSwipes = 0,
    this.rightSwipes = 0,
    this.timeline = const [],
  });

  final int totalTurns;
  final int leftSwipes;
  final int rightSwipes;
  final List<StatChangeRecord> timeline;

  GameStatistics record({
    required int turn,
    required Era era,
    required SwipeDirection direction,
    required Map<StatType, Stat> before,
    required Map<StatType, Stat> after,
  }) {
    return GameStatistics(
      totalTurns: totalTurns + 1,
      leftSwipes: leftSwipes + (direction == SwipeDirection.left ? 1 : 0),
      rightSwipes: rightSwipes + (direction == SwipeDirection.right ? 1 : 0),
      timeline: [
        ...timeline,
        StatChangeRecord(
          turn: turn,
          era: era,
          direction: direction,
          before: {for (final entry in before.entries) entry.key: entry.value.value},
          after: {for (final entry in after.entries) entry.key: entry.value.value},
        ),
      ],
    );
  }

  Map<StatType, double> averagesFor(Era era) {
    final records = timeline.where((record) => record.era == era).toList();
    if (records.isEmpty) return const {};
    return {
      for (final type in StatType.values)
        type: records.fold<int>(0, (sum, record) => sum + record.after[type]!) /
            records.length,
    };
  }
}
