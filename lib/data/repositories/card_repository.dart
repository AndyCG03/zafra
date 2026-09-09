import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/era.dart';
import '../models/game_card.dart';
import '../models/character.dart';
import '../models/ending.dart';

/// NOTA DE ESTE CAMBIO: se agregó `allCards`. Ya no se filtra por era
/// para elegir la siguiente carta — todas las cartas de todos los
/// archivos JSON de assets/cards/ entran al mismo mazo aleatorio.
/// Los archivos por era siguen existiendo solo como forma de ORGANIZAR
/// el guion (para que no tengas un solo JSON gigante), pero el juego
/// ya no restringe qué se muestra según en qué "era" narrativa estás.
class CardRepository {
  final Map<String, List<GameCard>> _cardsByEra = {};
  final Map<String, Character> _characters = {};
  final List<Ending> _endings = [];
  final List<GameCard> _creatorCards = [];

  static const String fallbackImage = 'assets/images/logo/icon card.png';

  bool _loaded = false;

  Future<void> loadAll() async {
    if (_loaded) return;

    await _loadCharacters();
    await _loadEndings();
    await _loadCreatorCards();
    for (final era in Era.values) {
      await _loadEraCards(era);
    }

    _loaded = true;
  }

  Future<void> _loadCreatorCards() async {
    try {
      final raw = await rootBundle.loadString('assets/cards/el_creador.json');
      final list = jsonDecode(raw) as List<dynamic>;
      _creatorCards
        ..clear()
        ..addAll(list.map((e) => GameCard.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      _creatorCards.clear();
    }
  }

  List<GameCard> get creatorCards => List.unmodifiable(_creatorCards);

  Future<void> _loadCharacters() async {
    final raw = await rootBundle.loadString('assets/cards/characters.json');
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    for (final item in list) {
      final character = Character.fromJson(item as Map<String, dynamic>);
      _characters[character.id] = character;
    }
  }

  Future<void> _loadEndings() async {
    final raw = await rootBundle.loadString('assets/cards/endings.json');
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    _endings.addAll(
      list.map((e) => Ending.fromJson(e as Map<String, dynamic>)),
    );
  }

  Future<void> _loadEraCards(Era era) async {
    try {
      final raw = await rootBundle.loadString(
        'assets/cards/${era.cardsFileName}',
      );
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      _cardsByEra[era.name] = list
          .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _cardsByEra[era.name] = [];
    }
  }

  /// TODAS las cartas del juego, sin importar de qué archivo/era vienen.
  /// Esta es la lista que ahora usa GameController para elegir al azar.
  List<GameCard> get allCards =>
      _cardsByEra.values.expand((list) => list).toList();

  List<GameCard> cardsForEra(Era era) =>
      List.unmodifiable(_cardsByEra[era.name] ?? const []);

  int get totalCardCount => allCards.length;

  Character? characterById(String id) => _characters[id];
  List<Character> get allCharacters => List.unmodifiable(_characters.values);

  List<Ending> get endings => List.unmodifiable(_endings);

  GameCard? cardById(String id) {
    for (final card in allCards) {
      if (card.id == id) return card;
    }
    return null;
  }

  /// Obtiene el asset de imagen para un personaje por su ID.
  /// Usa la misma lógica que imageAssetFor(GameCard) pero para personajes.
  /// Si no existe el personaje, retorna la imagen de fallback.
  String imageAssetForCharacter(String characterId) {
    final character = characterById(characterId);
    return character?.imageAsset ?? fallbackImage;
  }

  String imageAssetFor(GameCard card) {
    if (card.imageAsset != null && card.imageAsset!.isNotEmpty) {
      return card.imageAsset!;
    }
    final character = characterById(card.characterId);
    return character?.imageAsset ?? fallbackImage;
  }
}
