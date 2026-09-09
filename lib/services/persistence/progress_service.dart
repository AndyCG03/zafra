import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/game_record.dart';
import '../../data/models/stat.dart';

/// Guarda progreso simple: finales vistos y configuración liviana.
class ProgressService {
  static const _boxName = 'zafra_progress';
  static const _seenEndingsKey = 'seen_endings';
  static const _gameKey = 'game_state';
  static const _characterNotificationsKey = 'character_notifications';
  static const _ambientVolumeKey = 'ambient_volume';
  static const _effectsVolumeKey = 'effects_volume';
  static const _soundKey = 'sound_enabled';
  static const _hapticsKey = 'haptics_enabled';
  static const _discoveredCardsKey = 'discovered_cards';
  static const _unlockedCharactersKey = 'unlocked_characters';
  static const _discoveredEventsKey = 'discovered_events';
  static const _maxEraKey = 'max_era_reached';
  static const _appStatsKey = 'app_statistics';
  static const _creatorMessagesKey = 'seen_creator_messages';
  static const _bestGamesKey = 'best_games';

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Set<String> get seenEndingIds {
    final list = (_box?.get(_seenEndingsKey) as List?)?.cast<String>() ?? [];
    return list.toSet();
  }

  Future<void> markEndingSeen(String endingId) async {
    final current = seenEndingIds..add(endingId);
    await _box?.put(_seenEndingsKey, current.toList());
  }

  Future<void> saveGame(Map<String, dynamic> data) async => _box?.put(_gameKey, data);
  Map<String, dynamic>? get savedGame {
    final value = _box?.get(_gameKey);
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }
  Future<void> clearGame() async => _box?.delete(_gameKey);
  bool get characterNotificationsEnabled => _box?.get(_characterNotificationsKey, defaultValue: true) as bool? ?? true;
  Future<void> setCharacterNotificationsEnabled(bool enabled) async => _box?.put(_characterNotificationsKey, enabled);
  double get ambientVolume => (_box?.get(_ambientVolumeKey, defaultValue: .12) as num).toDouble();
  double get effectsVolume => (_box?.get(_effectsVolumeKey, defaultValue: .8) as num).toDouble();
  Future<void> setAmbientVolume(double value) async => _box?.put(_ambientVolumeKey, value);
  Future<void> setEffectsVolume(double value) async => _box?.put(_effectsVolumeKey, value);
  bool get soundEnabled => _box?.get(_soundKey, defaultValue: true) as bool? ?? true;
  bool get hapticsEnabled => _box?.get(_hapticsKey, defaultValue: true) as bool? ?? true;
  Future<void> setSoundEnabled(bool value) async => _box?.put(_soundKey, value);
  Future<void> setHapticsEnabled(bool value) async => _box?.put(_hapticsKey, value);
  Set<String> get discoveredCardIds => ((_box?.get(_discoveredCardsKey) as List?)?.cast<String>() ?? []).toSet();
  Future<Set<String>> unlockedCharacterIds() async => discoveredCardIds;
  Set<String> get unlockedCharacters => ((_box?.get(_unlockedCharactersKey) as List?)?.cast<String>() ?? []).toSet();
  Future<void> markCharacterUnlocked(String id) async { final ids = unlockedCharacters..add(id); await _box?.put(_unlockedCharactersKey, ids.toList()); }
  Future<void> addDiscoveredCard(String id) async { final ids = discoveredCardIds..add(id); await _box?.put(_discoveredCardsKey, ids.toList()); }
  Set<String> get discoveredEventIds => ((_box?.get(_discoveredEventsKey) as List?)?.cast<String>() ?? const []).toSet();
  Future<void> markEventDiscovered(String id) async {
    final ids = discoveredEventIds..add(id);
    await _box?.put(_discoveredEventsKey, ids.toList());
  }
  int get maxEraReached => (_box?.get(_maxEraKey, defaultValue: 0) as num).toInt();
  Future<void> markEraReached(int eraIndex) async {
    if (eraIndex > maxEraReached) await _box?.put(_maxEraKey, eraIndex);
  }

  Map<String, dynamic> get appStatistics {
    final raw = _box?.get(_appStatsKey);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {'games': 0, 'turns': 0, 'left': 0, 'right': 0};
  }
  int get gamesPlayed => (appStatistics['games'] as num? ?? 0).toInt();
  int get totalTurnsPlayed => (appStatistics['turns'] as num? ?? 0).toInt();
  int get totalLeftSwipes => (appStatistics['left'] as num? ?? 0).toInt();
  int get totalRightSwipes => (appStatistics['right'] as num? ?? 0).toInt();

  Future<void> registerGameStarted() async {
    final stats = appStatistics;
    stats['games'] = (stats['games'] as num? ?? 0).toInt() + 1;
    await _box?.put(_appStatsKey, stats);
  }

  /// Registra el cierre de un mandato (final por colapso o por supervivencia).
  /// Si se pasa [finalStats], además guarda un [GameRecord] y actualiza
  /// el ranking de mejores partidas (top 3 por turnos sobrevividos).
  Future<void> registerMandate({
    required int turns,
    required int left,
    required int right,
    int eraIndex = 0,
    int days = 0,
    String? endingId,
    String? endingTitle,
    Map<StatType, int>? finalStats,
  }) async {
    final stats = appStatistics;
    stats['turns'] = (stats['turns'] as num? ?? 0).toInt() + turns;
    stats['left'] = (stats['left'] as num? ?? 0).toInt() + left;
    stats['right'] = (stats['right'] as num? ?? 0).toInt() + right;
    await _box?.put(_appStatsKey, stats);

    if (finalStats != null) {
      final record = GameRecord(
        turns: turns,
        days: days,
        eraIndex: eraIndex,
        endingId: endingId,
        endingTitle: endingTitle,
        finalStats: finalStats,
        date: DateTime.now(),
      );
      final games = bestGames..add(record);
      games.sort((a, b) => b.turns.compareTo(a.turns));
      final top = games.take(3).toList();
      await _box?.put(_bestGamesKey, top.map((g) => g.toJson()).toList());
    }
  }

  /// Top 3 partidas históricas (ordenadas por turnos sobrevividos, desc).
  List<GameRecord> get bestGames {
    final raw = (_box?.get(_bestGamesKey) as List?) ?? const [];
    final list = raw
        .map((e) => GameRecord.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => b.turns.compareTo(a.turns));
    return list;
  }

  Set<String> get seenCreatorMessageIds => ((_box?.get(_creatorMessagesKey) as List?)?.cast<String>() ?? const []).toSet();
  Future<void> markCreatorMessageSeen(String id) async {
    final ids = seenCreatorMessageIds..add(id);
    await _box?.put(_creatorMessagesKey, ids.toList());
  }
}