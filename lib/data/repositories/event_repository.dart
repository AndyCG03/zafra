import 'dart:convert';
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

      return GameCard(
        id: 'event_${id}_${i + 1}',
        characterId: 'evento_$id', // ✅ ID único para el evento
        eraId: 'evento',
        text: prompt.text,
        imageAsset: image,
        left: CardOption(
          text: prompt.left.text,
          effects: prompt.left.effects,
        ),
        right: CardOption(
          text: prompt.right.text,
          effects: prompt.right.effects,
        ),
        weight: 1,
        isRare: true,
      );
    });
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
  };
  static List<EventDefinition> _definitions = [];

  /// Carga los eventos desde el archivo JSON
  static Future<void> loadEvents() async {
    try {
      String raw;
      try {
        raw = await rootBundle.loadString('assets/cards/events.json');
      } catch (_) {
        raw = await rootBundle.loadString('assets/cards/events/json/events.json');
      }
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      _definitions = list
          .map((e) => EventDefinition.fromJson(e as Map<String, dynamic>))
          .where((event) => _supportedEventIds.contains(event.id))
          .where((event) => event.prompts.length >= 15)
          .toList();
    } catch (e) {
      _definitions = [];
    }
  }

  static List<EventDefinition> get definitions => List.unmodifiable(_definitions);

  static EventDefinition? byId(String id) {
    for (final event in definitions) {
      if (event.id == id) return event;
    }
    return null;
  }

  static bool get isLoaded => _definitions.isNotEmpty;
}
