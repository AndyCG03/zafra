import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/era.dart';
import '../../domain/game_engine/island_chronicle.dart';
import '../../domain/game_engine/game_state.dart';
import '../models/game_card.dart';
import '../models/character.dart';
import '../models/ending.dart';

/// Catálogo de contenido. La selección aplica las condiciones y la era.
class CardRepository {
  final Map<String, List<GameCard>> _cardsByEra = {};
  final Map<String, Character> _characters = {};
  final List<Ending> _endings = [];
  final List<GameCard> _creatorCards = [];

  static const String fallbackImage = 'assets/images/logo/icon card.png';

  bool _loaded = false;
  Future<void>? _loading;
  List<GameCard> _allCards = const [];
  final Map<String, GameCard> _cardsById = {};
  List<String> _campaignCardIds = const [];
  List<Map<String, dynamic>> _campaignActs = const [];
  List<String> get campaignCardIds => _campaignCardIds;
  GameCard? campaignCardAt(GameState state) {
    if (state.campaignIndex >= _campaignCardIds.length) return null;
    final base = _campaignCardIds[state.campaignIndex];
    return cardById(IslandChronicle.routeId(state, base) ?? base);
  }

  int campaignAct(int index) {
    var cursor = 0;
    for (var n = 0; n < _campaignActs.length; n++) {
      cursor += (_campaignActs[n]['cards'] as List).length;
      if (index < cursor) return n + 1;
    }
    return _campaignActs.length;
  }

  String campaignActTitle(int index) {
    var cursor = 0;
    for (var n = 0; n < _campaignActs.length; n++) {
      final act = _campaignActs[n];
      cursor += (act['cards'] as List).length;
      if (index < cursor) return 'ACTO ${n + 1} · ${act['title']}';
    }
    return 'CAMPAÑA COMPLETADA';
  }

  Future<void> loadAll() async {
    if (_loaded) return;
    if (_loading != null) return _loading;
    _loading = _loadContent();
    try {
      await _loading;
    } finally {
      _loading = null;
    }
  }

  Future<void> _loadContent() async {
    _characters.clear();
    _endings.clear();
    _cardsByEra.clear();
    await _loadCharacters();
    await _loadEndings();
    await _loadCreatorCards();
    for (final era in Era.values) {
      await _loadEraCards(era);
    }

    final stories = jsonDecode(
            await rootBundle.loadString('assets/cards/arcos_narrativos.json'))
        as List;
    final campaign =
        jsonDecode(await rootBundle.loadString('assets/cards/campana.json'))
            as Map<String, dynamic>;
    _campaignActs = (campaign['acts'] as List).cast<Map<String, dynamic>>();
    _campaignCardIds = List.unmodifiable(
        _campaignActs.expand((act) => (act['cards'] as List).cast<String>()));
    _allCards = List.unmodifiable([
      ..._cardsByEra.values.expand((cards) => cards),
      ...IslandChronicle.routes,
      ...stories.map((e) => GameCard.fromJson(e as Map<String, dynamic>)),
      ...(campaign['cards'] as List)
          .map((e) => GameCard.fromJson(e as Map<String, dynamic>)),
    ]);
    _cardsById.clear();
    for (final card in [..._allCards, ..._creatorCards]) {
      if (_cardsById.containsKey(card.id)) {
        throw FormatException('Carta duplicada: ${card.id}');
      }
      _cardsById[card.id] = card;
    }
    if (_campaignCardIds.toSet().length != _campaignCardIds.length ||
        _campaignCardIds.any((id) => !_cardsById.containsKey(id))) {
      throw const FormatException(
          'El recorrido de campaña contiene escenas duplicadas o inexistentes.');
    }
    _loaded = true;
  }

  Future<void> _loadCreatorCards() async {
    final raw = await rootBundle.loadString('assets/cards/el_creador.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _creatorCards
      ..clear()
      ..addAll(list.map((e) => GameCard.fromJson(e as Map<String, dynamic>)));
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
    final storyEndings = jsonDecode(
            await rootBundle.loadString('assets/cards/finales_historia.json'))
        as List;
    _endings.addAll(
        storyEndings.map((e) => Ending.fromJson(e as Map<String, dynamic>)));
  }

  Future<void> _loadEraCards(Era era) async {
    final raw = await rootBundle.loadString(
      'assets/cards/${era.cardsFileName}',
    );
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    _cardsByEra[era.name] =
        list.map((e) => GameCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Vista inmutable, construida una vez al cargar el catálogo.
  List<GameCard> get allCards => _allCards;

  List<GameCard> cardsForEra(Era era) =>
      List.unmodifiable(_cardsByEra[era.name] ?? const []);

  int get totalCardCount => allCards.length;

  Character? characterById(String id) => _characters[id];
  List<Character> get allCharacters => List.unmodifiable(_characters.values);

  List<Ending> get endings => List.unmodifiable(_endings);

  GameCard? cardById(String id) => _cardsById[id];

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
