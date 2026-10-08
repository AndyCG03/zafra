import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zafra/data/models/era.dart';
import 'package:zafra/data/models/stat.dart';
import 'package:zafra/data/repositories/card_repository.dart';
import 'package:zafra/data/repositories/event_repository.dart';
import 'package:zafra/domain/game_engine/ending_resolver.dart';
import 'package:zafra/domain/game_engine/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('catálogo completo y referencias válidas', () async {
    final repository = CardRepository();
    await Future.wait([
      repository.loadAll(),
      repository.loadAll(),
      EventRepository.loadEvents()
    ]);
    expect(repository.allCards, isNotEmpty);
    expect(repository.allCards.map((c) => c.id).toSet().length,
        repository.totalCardCount);
    for (final era in Era.values) {
      expect(repository.cardsForEra(era), isNotEmpty);
    }
    final all = [
      ...repository.allCards,
      ...repository.creatorCards,
      ...EventRepository.definitions.expand((e) => e.cards)
    ];
    final ids = all.map((c) => c.id).toSet();
    for (final c in all) {
      expect(c.text.trim(), isNotEmpty, reason: c.id);
      expect(c.weight, greaterThan(0), reason: c.id);
      expect(File(repository.imageAssetFor(c)).existsSync(), isTrue,
          reason: c.id);
      if (!c.characterId.startsWith('evento_')) {
        expect(repository.characterById(c.characterId), isNotNull,
            reason: c.id);
      }
      for (final option in [c.left, c.right]) {
        for (final scheduled in option.scheduleCards) {
          expect(ids, contains(scheduled.cardId), reason: c.id);
          expect(scheduled.afterTurns, greaterThanOrEqualTo(1));
          expect(scheduled.title.trim(), isNotEmpty);
        }
        expect(option.text.trim(), isNotEmpty, reason: c.id);
        if (option.nextCardId != null) {
          expect(ids, contains(option.nextCardId), reason: c.id);
        }
        if (option.startsEvent != null) {
          expect(EventRepository.byId(option.startsEvent!), isNotNull,
              reason: c.id);
        }
        if (option.favorsCharacter != null) {
          expect(repository.characterById(option.favorsCharacter!), isNotNull);
        }
        for (final character in option.trustChanges.keys) {
          expect(repository.characterById(character), isNotNull, reason: c.id);
        }
        for (final outcome in option.conditionalOutcomes) {
          for (final character in {
            ...outcome.minTrust.keys,
            ...outcome.maxTrust.keys
          }) {
            expect(repository.characterById(character), isNotNull,
                reason: c.id);
          }
        }
        if (option.grantsRescue != null) {
          expect(StatType.values.map((t) => t.name),
              contains(option.grantsRescue));
        }
      }
    }
    for (final ending in repository.endings) {
      expect(File(ending.imageAsset).existsSync(), isTrue, reason: ending.id);
    }
    expect(repository.allCards.where((c) => c.isRare), isNotEmpty);
    expect(identical(repository.allCards, repository.allCards), isTrue);
    final resolver = EndingResolver();
    for (final era in Era.values) {
      for (final type in StatType.values) {
        for (final value in [0, 100]) {
          final initial = GameState.initial();
          final state = initial.copyWith(
              currentEra: era,
              stats: {...initial.stats, type: Stat(type, value)});
          final ending = resolver.resolve(
              state: state, availableEndings: repository.endings);
          expect(ending, isNotNull, reason: '${era.name}/${type.name}/$value');
          expect(ending!.isSurvival, isFalse);
          expect(ending.isStoryEnding, isFalse);
        }
      }
    }
  });
}
