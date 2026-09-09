import 'stat.dart';

class CardOption {
  final String text;
  final Map<StatType, int> effects;
  final String? nextCardId;
  final String? grantsRescue;
  final String? startsEvent;

  const CardOption({
    required this.text,
    required this.effects,
    this.nextCardId, this.grantsRescue, this.startsEvent,
  });

  factory CardOption.fromJson(Map<String, dynamic> json) {
    final rawEffects = (json['effects'] as Map<String, dynamic>? ?? {});
    final effects = <StatType, int>{};
    rawEffects.forEach((key, value) {
      final statType = _statTypeFromKey(key);
      if (statType != null) {
        effects[statType] = (value as num).toInt();
      }
    });

    return CardOption(
      text: json['text'] as String,
      effects: effects,
      nextCardId: json['nextCardId'] as String?,
      grantsRescue: json['grantsRescue'] as String?,
      startsEvent: json['startsEvent'] as String?,
    );
  }
}

class CardCondition {
  final Map<StatType, int> minValues;
  final Map<StatType, int> maxValues;
  final Set<String> requiresFlags;
  final Set<String> excludesFlags;

  const CardCondition({
    this.minValues = const {},
    this.maxValues = const {},
    this.requiresFlags = const {},
    this.excludesFlags = const {},
  });

  factory CardCondition.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CardCondition();

    final min = <StatType, int>{};
    final max = <StatType, int>{};

    (json['min'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      final t = _statTypeFromKey(k);
      if (t != null) min[t] = (v as num).toInt();
    });
    (json['max'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      final t = _statTypeFromKey(k);
      if (t != null) max[t] = (v as num).toInt();
    });

    return CardCondition(
      minValues: min,
      maxValues: max,
      requiresFlags: {
        ...((json['requiresFlags'] as List?)?.cast<String>() ?? [])
      },
      excludesFlags: {
        ...((json['excludesFlags'] as List?)?.cast<String>() ?? [])
      },
    );
  }
}

class GameCard {
  final String id;
  final String characterId;
  final String eraId;
  final String text;
  final CardOption left;
  final CardOption right;
  final CardCondition condition;
  final int weight;
  final bool isRare;

  /// NUEVO: imagen específica de ESTA carta (opcional).
  /// Si es null, la UI debe usar la imagen por defecto del personaje
  /// (characters.json -> imageAsset). Útil para dar una expresión o
  /// pose distinta sin crear un personaje nuevo.
  /// En el JSON de la carta: campo "image" (opcional).
  final String? imageAsset;

  const GameCard({
    required this.id,
    required this.characterId,
    required this.eraId,
    required this.text,
    required this.left,
    required this.right,
    this.condition = const CardCondition(),
    this.weight = 1,
    this.isRare = false,
    this.imageAsset,
  });

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] as String,
      characterId: json['character'] as String,
      eraId: json['era'] as String,
      text: json['text'] as String,
      left: CardOption.fromJson(json['left'] as Map<String, dynamic>),
      right: CardOption.fromJson(json['right'] as Map<String, dynamic>),
      condition: CardCondition.fromJson(
        json['conditions'] as Map<String, dynamic>?,
      ),
      weight: (json['weight'] as num?)?.toInt() ?? 1,
      isRare: json['rare'] as bool? ?? false,
      imageAsset: json['image'] as String?,
    );
  }
}

StatType? _statTypeFromKey(String key) {
  switch (key) {
    case 'pueblo':
      return StatType.pueblo;
    case 'economia':
      return StatType.economia;
    case 'relacionesExteriores':
      return StatType.relacionesExteriores;
    case 'aparatoDelEstado':
      return StatType.aparatoDelEstado;
    default:
      return null;
  }
}
