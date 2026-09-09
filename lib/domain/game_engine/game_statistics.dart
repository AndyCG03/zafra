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

  Map<String, dynamic> toJson() => {
        'totalTurns': totalTurns,
        'leftSwipes': leftSwipes,
        'rightSwipes': rightSwipes,
        'timeline': timeline
            .map((record) => {
                  'turn': record.turn,
                  'era': record.era.index,
                  'direction': record.direction.name,
                  'before': {
                    for (final entry in record.before.entries)
                      entry.key.index.toString(): entry.value,
                  },
                  'after': {
                    for (final entry in record.after.entries)
                      entry.key.index.toString(): entry.value,
                  },
                })
            .toList(),
      };

  factory GameStatistics.fromJson(Map<dynamic, dynamic>? raw) {
    if (raw == null) return const GameStatistics();
    final records = <StatChangeRecord>[];
    for (final item in (raw['timeline'] as List? ?? const [])) {
      if (item is! Map) continue;
      final beforeRaw = Map<dynamic, dynamic>.from(item['before'] as Map? ?? {});
      final afterRaw = Map<dynamic, dynamic>.from(item['after'] as Map? ?? {});
      final eraIndex = (item['era'] as num?)?.toInt() ?? 0;
      final era = eraIndex >= 0 && eraIndex < Era.values.length
          ? Era.values[eraIndex]
          : Era.fundacional;
      records.add(StatChangeRecord(
        turn: (item['turn'] as num?)?.toInt() ?? 0,
        era: era,
        direction: item['direction'] == 'right'
            ? SwipeDirection.right
            : SwipeDirection.left,
        before: _decodeStats(beforeRaw),
        after: _decodeStats(afterRaw),
      ));
    }
    return GameStatistics(
      totalTurns: (raw['totalTurns'] as num?)?.toInt() ?? records.length,
      leftSwipes: (raw['leftSwipes'] as num?)?.toInt() ??
          records.where((r) => r.direction == SwipeDirection.left).length,
      rightSwipes: (raw['rightSwipes'] as num?)?.toInt() ??
          records.where((r) => r.direction == SwipeDirection.right).length,
      timeline: records,
    );
  }

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

Map<StatType, int> _decodeStats(Map<dynamic, dynamic> raw) => {
      for (final entry in raw.entries)
        if (int.tryParse(entry.key.toString()) != null)
          StatType.values[int.parse(entry.key.toString())]:
              (entry.value as num).toInt(),
    };
