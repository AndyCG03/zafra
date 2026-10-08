import 'stat.dart';

class CardOption {
  final String text;
  final Map<StatType, int> effects;
  final String? nextCardId;
  final String? grantsRescue;
  final String? startsEvent;
  final List<String> setFlags;
  final List<String> clearFlags;
  final String? favorsCharacter;
  final List<ScheduledConsequence> scheduleCards;
  final bool restoresSecurity;
  final Map<String, int> trustChanges;
  final List<ConditionalOutcome> conditionalOutcomes;
  final bool endsStory;

  const CardOption({
    required this.text,
    required this.effects,
    this.nextCardId,
    this.grantsRescue,
    this.startsEvent,
    this.setFlags = const [],
    this.clearFlags = const [],
    this.favorsCharacter,
    this.scheduleCards = const [],
    this.restoresSecurity = false,
    this.trustChanges = const {},
    this.conditionalOutcomes = const [],
    this.endsStory = false,
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
      setFlags: (json['setFlags'] as List?)?.cast<String>() ?? const [],
      clearFlags: (json['clearFlags'] as List?)?.cast<String>() ?? const [],
      favorsCharacter: json['favorsCharacter'] as String?,
      scheduleCards: (json['scheduleCards'] as List? ?? const [])
          .map((e) => ScheduledConsequence.fromJson(e as Map<String, dynamic>))
          .toList(),
      restoresSecurity: json['restoresSecurity'] as bool? ?? false,
      trustChanges: _intMap(json['trustChanges']),
      conditionalOutcomes: (json['conditionalOutcomes'] as List? ?? const [])
          .map((e) => ConditionalOutcome.fromJson(e as Map<String, dynamic>))
          .toList(),
      endsStory: json['endsStory'] as bool? ?? false,
    );
  }
}

class CardCondition {
  final Map<StatType, int> minValues;
  final Map<StatType, int> maxValues;
  final Set<String> requiresFlags;
  final Set<String> excludesFlags;
  final Map<String, int> minTurnsAfterFlag;
  final Map<String, int> minFavorCount;
  final Map<String, int> minTrust;
  final Map<String, int> maxTrust;

  const CardCondition({
    this.minValues = const {},
    this.maxValues = const {},
    this.requiresFlags = const {},
    this.excludesFlags = const {},
    this.minTurnsAfterFlag = const {},
    this.minFavorCount = const {},
    this.minTrust = const {},
    this.maxTrust = const {},
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
      minTurnsAfterFlag: _intMap(json['minTurnsAfterFlag']),
      minFavorCount: _intMap(json['minFavorCount']),
      minTrust: _intMap(json['minTrust']),
      maxTrust: _intMap(json['maxTrust']),
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
  final String? storyArc;
  final String? chapter;
  final bool drawFromDeck;
  final String id;
  final String characterId;
  final String eraId;
  final String text;
  final CardOption left;
  final CardOption right;
  final CardCondition condition;
  final int weight;
  final bool isRare;
  final List<MemoryVariant> memoryVariants;

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
    this.memoryVariants = const [],
    this.imageAsset,
    this.storyArc,
    this.chapter,
    this.drawFromDeck = true,
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
      memoryVariants: (json['memoryVariants'] as List? ?? const [])
          .map((item) => MemoryVariant.fromJson(item as Map<String, dynamic>))
          .toList(),
      imageAsset: json['image'] as String?,
      storyArc: json['storyArc'] as String?,
      chapter: json['chapter'] as String?,
      drawFromDeck: json['drawFromDeck'] as bool? ?? true,
    );
  }

  String resolvedText(Set<String> activeFlags,
      {Map<String, int> trust = const {}}) {
    for (final variant in memoryVariants) {
      if (variant.matches(activeFlags, trust)) return variant.text;
    }
    return text;
  }
}

/// En una opción, afterTurns es el plazo; en la partida, dueTurn es absoluto.
class ScheduledConsequence {
  final String cardId;
  final String title;
  final int afterTurns;
  const ScheduledConsequence(
      {required this.cardId, required this.title, required this.afterTurns});
  factory ScheduledConsequence.fromJson(Map<String, dynamic> json) =>
      ScheduledConsequence(
          cardId: json['cardId'] as String,
          title: json['title'] as String,
          afterTurns: (json['afterTurns'] as num).toInt());
}

class PendingConsequence {
  final String cardId;
  final String title;
  final int dueTurn;
  const PendingConsequence(
      {required this.cardId, required this.title, required this.dueTurn});
  Map<String, dynamic> toJson() =>
      {'cardId': cardId, 'title': title, 'dueTurn': dueTurn};
  factory PendingConsequence.fromJson(Map<String, dynamic> json) =>
      PendingConsequence(
          cardId: json['cardId'] as String,
          title: json['title'] as String,
          dueTurn: (json['dueTurn'] as num).toInt());
}

class MemoryVariant {
  final Set<String> requiresFlags;
  final Set<String> excludesFlags;
  final Map<String, int> minTrust;
  final Map<String, int> maxTrust;
  final String text;

  const MemoryVariant(
      {required this.requiresFlags,
      required this.text,
      this.excludesFlags = const {},
      this.minTrust = const {},
      this.maxTrust = const {}});

  bool matches(Set<String> flags, Map<String, int> trust) => narrativeMatches(
      flags: flags,
      trust: trust,
      requiresFlags: requiresFlags,
      excludesFlags: excludesFlags,
      minTrust: minTrust,
      maxTrust: maxTrust);

  factory MemoryVariant.fromJson(Map<String, dynamic> json) => MemoryVariant(
        requiresFlags:
            (json['requiresFlags'] as List? ?? const []).cast<String>().toSet(),
        text: json['text'] as String,
        excludesFlags:
            (json['excludesFlags'] as List? ?? const []).cast<String>().toSet(),
        minTrust: _intMap(json['minTrust']),
        maxTrust: _intMap(json['maxTrust']),
      );
}

class ConditionalOutcome {
  final Set<String> requiresFlags;
  final Set<String> excludesFlags;
  final Map<String, int> minTrust;
  final Map<String, int> maxTrust;
  final Map<StatType, int> effects;
  final List<String> setFlags;
  final String? feedback;
  const ConditionalOutcome(
      {this.requiresFlags = const {},
      this.excludesFlags = const {},
      this.minTrust = const {},
      this.maxTrust = const {},
      this.effects = const {},
      this.setFlags = const [],
      this.feedback});
  bool matches(Set<String> flags, Map<String, int> trust) => narrativeMatches(
      flags: flags,
      trust: trust,
      requiresFlags: requiresFlags,
      excludesFlags: excludesFlags,
      minTrust: minTrust,
      maxTrust: maxTrust);
  factory ConditionalOutcome.fromJson(Map<String, dynamic> json) =>
      ConditionalOutcome(
        requiresFlags:
            (json['requiresFlags'] as List? ?? const []).cast<String>().toSet(),
        excludesFlags:
            (json['excludesFlags'] as List? ?? const []).cast<String>().toSet(),
        minTrust: _intMap(json['minTrust']),
        maxTrust: _intMap(json['maxTrust']),
        effects: CardOption.fromJson({'text': '', 'effects': json['effects']})
            .effects,
        setFlags: (json['setFlags'] as List? ?? const []).cast<String>(),
        feedback: json['feedback'] as String?,
      );
}

bool narrativeMatches(
        {required Set<String> flags,
        required Map<String, int> trust,
        Set<String> requiresFlags = const {},
        Set<String> excludesFlags = const {},
        Map<String, int> minTrust = const {},
        Map<String, int> maxTrust = const {}}) =>
    flags.containsAll(requiresFlags) &&
    !excludesFlags.any(flags.contains) &&
    minTrust.entries.every((e) => (trust[e.key] ?? 0) >= e.value) &&
    maxTrust.entries.every((e) => (trust[e.key] ?? 0) <= e.value);

Map<String, int> _intMap(dynamic raw) => {
      for (final entry in (raw as Map? ?? const {}).entries)
        entry.key as String: (entry.value as num).toInt(),
    };

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
