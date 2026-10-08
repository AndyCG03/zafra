import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

import '../models/game_card.dart';
import '../models/stat.dart';

class EventDefinition {
  final String id;
  final String title;
  final String image;
  final String? bio; // <-- Agregar este campo
  final List<EventPrompt> prompts;

  const EventDefinition({
    required this.id,
    required this.title,
    required this.image,
    this.bio, // <-- Agregar este campo
    required this.prompts,
  });

  factory EventDefinition.fromJson(Map<String, dynamic> json) {
    return EventDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      image: json['image'] as String,
      bio: json['bio'] as String?, // <-- Agregar este campo
      prompts: (json['prompts'] as List)
          .map((e) => EventPrompt.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  List<GameCard> get cards {
    return List.generate(prompts.length, (i) {
      final prompt = prompts[i];
      List<ConditionalOutcome> support(EventOption option) => id != 'rebelion'
          ? const []
          : [
              if ((option.effects[StatType.pueblo] ?? 0) > 0)
                const ConditionalOutcome(
                    minTrust: {'la_lider_vecinal': 3},
                    effects: {StatType.aparatoDelEstado: 2},
                    feedback:
                        'La Líder Vecinal respalda la negociación y consigue que los barrios escuchen.'),
              if ((option.effects[StatType.aparatoDelEstado] ?? 0) > 0)
                const ConditionalOutcome(
                    maxTrust: {'el_general': -3},
                    effects: {StatType.aparatoDelEstado: -3},
                    setFlags: ['general_retiro_apoyo'],
                    feedback:
                        'El General retira su apoyo: tus órdenes encuentran una escolta dividida.'),
            ];

      return GameCard(
        id: 'event_${id}_${i + 1}',
        characterId: 'evento_$id', // ✅ ID único para el evento
        eraId: 'evento',
        text: prompt.text,
        memoryVariants: id == 'rebelion' && i == 0
            ? const [
                MemoryVariant(
                    requiresFlags: {},
                    minTrust: {'la_lider_vecinal': 3},
                    text:
                        'La protesta llega a palacio. La Líder Vecinal pone su nombre junto al tuyo y ofrece una mesa pública, pero exige que respondas a los barrios.'),
                MemoryVariant(
                    requiresFlags: {},
                    maxTrust: {'el_general': -3},
                    text:
                        'La protesta llega a palacio y el General retira su respaldo. Tendrás que responder con una escolta dividida.'),
              ]
            : const [],
        imageAsset: image,
        left: CardOption(
          text: prompt.left.text,
          effects: prompt.left.effects,
          conditionalOutcomes: support(prompt.left),
        ),
        right: CardOption(
          text: prompt.right.text,
          effects: prompt.right.effects,
          conditionalOutcomes: support(prompt.right),
        ),
        weight: 1,
        isRare: true,
      );
    });
  }

  /// Inicio y cierre fijos; dos momentos intermedios conservan su orden.
  List<String> sequence(Random random) {
    final catalog = cards;
    if (catalog.length <= 4) return catalog.map((c) => c.id).toList();
    final middle = List.generate(catalog.length - 2, (i) => i + 1)
      ..shuffle(random);
    final selected = middle.take(2).toList()..sort();
    return [
      catalog.first.id,
      ...selected.map((i) => catalog[i].id),
      catalog.last.id
    ];
  }
}

class EventPrompt {
  final String text;
  final EventOption left;
  final EventOption right;

  const EventPrompt({
    required this.text,
    required this.left,
    required this.right,
  });

  factory EventPrompt.fromJson(Map<String, dynamic> json) {
    return EventPrompt(
      text: json['text'] as String,
      left: EventOption.fromJson(json['left'] as Map<String, dynamic>),
      right: EventOption.fromJson(json['right'] as Map<String, dynamic>),
    );
  }
}

class EventOption {
  final String text;
  final Map<StatType, int> effects;

  const EventOption({
    required this.text,
    required this.effects,
  });

  factory EventOption.fromJson(Map<String, dynamic> json) {
    final rawEffects = (json['effects'] as Map<String, dynamic>? ?? {});
    final effects = <StatType, int>{};
    rawEffects.forEach((key, value) {
      final statType = _statTypeFromKey(key);
      if (statType != null) {
        effects[statType] = (value as num).toInt();
      }
    });

    return EventOption(
      text: json['text'] as String,
      effects: effects,
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

class EventRepository {
  static const _supportedEventIds = {
    'huracan',
    'rebelion',
    'corrupcion',
    'refugiados',
    'terrorismo',
    'accidente',
    'golpe_de_estado',
    'epidemia',
  };
  static List<EventDefinition> _definitions = [];
  static final Map<String, GameCard> _cardsById = {};
  static bool _loaded = false;
  static Future<void>? _loading;

  /// Carga los eventos desde el archivo JSON
  static Future<void> loadEvents() async {
    if (_loaded) return;
    if (_loading != null) return _loading;
    _loading = _load();
    try {
      await _loading;
    } finally {
      _loading = null;
    }
  }

  static Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/cards/events.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final definitions = list
        .map((e) => EventDefinition.fromJson(e as Map<String, dynamic>))
        .where((event) => _supportedEventIds.contains(event.id))
        .toList();
    if (definitions.any((event) => event.prompts.isEmpty)) {
      throw const FormatException('Un evento no tiene decisiones.');
    }
    _definitions = definitions;
    _cardsById.clear();
    for (final event in definitions) {
      for (final card in event.cards) {
        _cardsById[card.id] = card;
      }
    }
    _loaded = true;
  }

  static GameCard? cardById(String id) => _cardsById[id];

  static List<EventDefinition> get definitions =>
      List.unmodifiable(_definitions);

  static EventDefinition? byId(String id) {
    for (final event in definitions) {
      if (event.id == id) return event;
    }
    return null;
  }

  static bool get isLoaded => _loaded;
}
