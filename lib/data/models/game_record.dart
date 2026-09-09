import 'stat.dart';
import 'era.dart';

/// Snapshot de una partida terminada (colapso o supervivencia).
/// Se usa para el ranking de "mejores partidas" en Estadísticas.
class GameRecord {
  final int turns;
  final int days;
  final int eraIndex;
  final String? endingId;
  final String? endingTitle;
  final Map<StatType, int> finalStats;
  final DateTime date;

  const GameRecord({
    required this.turns,
    required this.days,
    required this.eraIndex,
    this.endingId,
    this.endingTitle,
    required this.finalStats,
    required this.date,
  });

  Era get era => Era.values[eraIndex.clamp(0, Era.values.length - 1)];

  Map<String, dynamic> toJson() => {
    'turns': turns,
    'days': days,
    'era': eraIndex,
    'endingId': endingId,
    'endingTitle': endingTitle,
    'stats': {
      for (final e in finalStats.entries) e.key.index.toString(): e.value,
    },
    'date': date.toIso8601String(),
  };

  factory GameRecord.fromJson(Map<dynamic, dynamic> json) {
    final rawStats = Map<String, dynamic>.from(json['stats'] as Map? ?? {});
    return GameRecord(
      turns: (json['turns'] as num?)?.toInt() ?? 0,
      days: (json['days'] as num?)?.toInt() ?? 0,
      eraIndex: (json['era'] as num?)?.toInt() ?? 0,
      endingId: json['endingId'] as String?,
      endingTitle: json['endingTitle'] as String?,
      finalStats: {
        for (final type in StatType.values)
          type: (rawStats[type.index.toString()] as num?)?.toInt() ?? Stat.initial,
      },
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}