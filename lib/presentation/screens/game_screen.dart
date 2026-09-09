import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../data/models/character.dart';
import '../../data/models/era.dart';
import '../../data/models/game_card.dart';
import '../../data/models/stat.dart';
import '../../data/repositories/card_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/game_engine/effect_applier.dart';
import '../../domain/game_engine/game_controller.dart';
import '../widgets/card_stack_backdrop.dart';
import '../widgets/dealing_intro.dart';
import '../widgets/stat_bar.dart';
import '../widgets/swipeable_card.dart';
import '../widgets/game_toast.dart';
import 'ending_screen.dart';
import 'loading_screen.dart';
import 'options_screen.dart';
import 'statistics_screen.dart';
import 'cards_screen.dart';
import 'events_eras_screen.dart';
import 'endings_gallery_screen.dart';
import '../../services/persistence/progress_service.dart';
import '../../services/audio/game_audio.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  static const Color _body = Color(0xFFEAE1D3);
  static const Color _ink = Color(0xFF16211B);

  bool _dealingDone = false;
  bool _introShown = false;
  bool _welcomeComplete = false;
  bool _endingAudioPlayed = false;
  Character? _pendingCharacter;
  Map<StatType, bool> _highlightedStats = {};
  final ProgressService _progress = ProgressService();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    final GameControllerState state = ref.watch(gameControllerProvider);
    final CardRepository repository = ref.watch(cardRepositoryProvider);

    ref.listen<GameControllerState>(gameControllerProvider, (previous, next) {
      if (previous != null && previous.gameState.currentEra != next.gameState.currentEra) {
        _showGameToast(
          'NUEVA ERA: ${next.gameState.currentEra.label.toUpperCase()}',
          icon: Icons.flag_rounded,
        );
      }
      if (previous?.gameState.activeEventId != next.gameState.activeEventId && next.gameState.activeEventId != null) {
        final event = EventRepository.byId(next.gameState.activeEventId!);
        if (event != null) {
          _showGameToast(
            event.title,
            icon: Icons.warning_amber_rounded,
          );
        }
      }
      final rescue = next.rescueOpportunity;
      if (rescue != null && previous?.rescueOpportunity != rescue) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showRescueDialog(context, rescue));
      }
      final character = next.unlockedCharacter;
      if (character == null || previous?.unlockedCharacter?.id == character.id) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (state.gameState.turn == 0 && (!_dealingDone || !_welcomeComplete)) {
          _pendingCharacter = character;
          return;
        }
        await _progress.init();
        GameAudio.instance.newCharacter();
        if (!_progress.characterNotificationsEnabled) {
          ref.read(gameControllerProvider.notifier).acknowledgeCharacterUnlock();
          return;
        }
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _CharacterUnlockDialog(character: character),
        );
        if (mounted) {
          ref.read(gameControllerProvider.notifier).acknowledgeCharacterUnlock();
        }
      });
    });

    if (state.isLoading) {
      _dealingDone = false;
      _introShown = false;
      _welcomeComplete = false;
      return const LoadingScreen();
    }

    if (state.ending != null) {
      if (!_endingAudioPlayed) { _endingAudioPlayed = true; GameAudio.instance.newCharacter(); }
      _dealingDone = false;
      _highlightedStats = {};
      return EndingScreen(ending: state.ending!);
    }

    final GameCard? card = state.currentCard;
    if (card == null) {
      return const Scaffold(
        body: Center(child: Text('No hay cartas disponibles.')),
      );
    }

    final bool isEvent = card.characterId.startsWith('evento_');

    String? characterName;
    if (isEvent) {
      final eventId = card.characterId.replaceFirst('evento_', '');
      final event = EventRepository.byId(eventId);
      characterName = event?.title ?? 'EVENTO';
    } else {
      final Character? character = repository.characterById(card.characterId);
      characterName = character?.name;
    }

    if (state.ending == null) _endingAudioPlayed = false;

    if (!_introShown && state.gameState.turn == 0) {
      _introShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGameIntro(context, onComplete: _completeWelcome));
    }

    return Scaffold(
      backgroundColor: _body,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(top: 0, left: 0, right: 0, height: height * .21, child: _Header(
                state: state,
                highlightedStats: _highlightedStats,
                canUseRescue: ref.read(gameControllerProvider.notifier).canUseRescuePower,
                onUseRescue: ref.read(gameControllerProvider.notifier).useRescuePower,
              )),
              Positioned(top: height * .21, left: 0, right: 0, height: height * .14, child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Text(
                    card.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: _ink,
                      fontSize: 17,
                      height: 1.45,
                    ),
                  ),
                ),
              )),
              Positioned(bottom: 0, left: 0, right: 0, height: height * .13, child: _Footer(days: state.gameState.daysInPower, onTap: () {
                GameAudio.instance.click();
                _showFooterMenu(context, state, () => ref.read(gameControllerProvider.notifier).restart());
              })),
              Positioned(top: height * .35, left: 0, right: 0, height: height * .52, child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
                child: _CardArea(
                  card: card,
                  characterName: characterName ?? 'Desconocido',
                  imageAsset: repository.imageAssetFor(card),
                  showIntro: !_dealingDone,
                  onIntroComplete: () {
                    setState(() => _dealingDone = true);
                    final pending = _pendingCharacter;
                    if (pending != null && _welcomeComplete) {
                      _pendingCharacter = null;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _presentCharacter(pending));
                    }
                  },
                  onSwiped: (SwipeDirection direction) {
                    _highlightedStats = {};
                    ref.read(gameControllerProvider.notifier).choose(direction);
                  },
                  onHighlightChange: (Map<StatType, bool> highlights) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _highlightedStats = highlights;
                        });
                      }
                    });
                  },
                ),
              )),
            ],
          );
        },
      ),
    );
  }

  void _completeWelcome() {
    if (!mounted) return;
    setState(() => _welcomeComplete = true);
    final pending = _pendingCharacter;
    if (pending != null && _dealingDone) {
      _pendingCharacter = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _presentCharacter(pending));
    }
  }

  Future<void> _presentCharacter(Character character) async {
    await _progress.init();
    if (!mounted) return;
    if (!_progress.characterNotificationsEnabled) {
      ref.read(gameControllerProvider.notifier).acknowledgeCharacterUnlock();
      return;
    }
    GameAudio.instance.newCharacter();
    await showDialog<void>(context: context, barrierDismissible: false, builder: (_) => _CharacterUnlockDialog(character: character));
    if (mounted) ref.read(gameControllerProvider.notifier).acknowledgeCharacterUnlock();
  }

  void _showGameToast(String message, {IconData? icon}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      GameToast.show(
        context: context,
        message: message,
        icon: icon,
        duration: const Duration(seconds: 3),
      );
    });
  }
}

void _showRescueDialog(BuildContext context, StatType type) {
  final controller = ProviderScope.containerOf(context).read(gameControllerProvider.notifier);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialog) => AlertDialog(
      backgroundColor: const Color(0xFF16211B),
      title: Text(
        '${type.label.toUpperCase()} EN CRISIS',
        style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFC79A3E)),
      ),
      content: const Text(
        'Tu comodín puede evitar la derrota y recuperar esta estadística.',
        style: TextStyle(fontFamily: 'monospace', color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () {
            GameAudio.instance.click(); // ✅ Click al usar comodín
            Navigator.pop(dialog);
            controller.useRescuePower(type);
          },
          child: const Text('USAR COMODIN'),
        ),
        FilledButton(
          onPressed: () {
            GameAudio.instance.click(); // ✅ Click al aceptar derrota
            Navigator.pop(dialog);
            controller.declineRescue();
          },
          child: const Text('ACEPTAR DERROTA'),
        ),
      ],
    ),
  );
}

void _showGameIntro(BuildContext context, {VoidCallback? onComplete}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialog) => AlertDialog(
      backgroundColor: const Color(0xFF16211B),
      title: const Text(
        'TOMA EL GOBIERNO',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'monospace',
          color: Color(0xFFC79A3E),
          letterSpacing: 1.5,
        ),
      ),
      content: const Text(
        'La isla acaba de salir de una crisis. Las instituciones estan fragiles, las reservas son escasas y cada decision tendra un precio. Equilibra al pueblo, la economia, las relaciones exteriores y el aparato del Estado para mantenerte en el poder.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'monospace',
          color: Color(0xFFFFF8E7),
          height: 1.4,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        FilledButton(
          onPressed: () {
            GameAudio.instance.click();
            Navigator.pop(dialog);
            onComplete?.call();
          },
          child: const Text('COMENZAR'),
        ),
      ],
    ),
  );
}

void _showFooterMenu(BuildContext context, GameControllerState state, VoidCallback restart) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1F2E26),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'MENU DEL GOBIERNO',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFC79A3E),
                letterSpacing: 2,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Color(0xFFC79A3E)),
            title: const Text('REINICIAR PARTIDA'),
            onTap: () async {
              GameAudio.instance.click(); // ✅ Click al presionar
              Navigator.pop(sheet);
              final ok = await showDialog<bool>(
                context: context,
                builder: (dialog) => AlertDialog(
                  title: const Text('¿Reiniciar partida?'),
                  content: const Text('Se perderá el progreso actual.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        GameAudio.instance.click(); // ✅ Click al cancelar
                        Navigator.pop(dialog, false);
                      },
                      child: const Text('CANCELAR'),
                    ),
                    FilledButton(
                      onPressed: () {
                        GameAudio.instance.click(); // ✅ Click al confirmar
                        Navigator.pop(dialog, true);
                      },
                      child: const Text('REINICIAR'),
                    ),
                  ],
                ),
              );
              if (ok == true) restart();
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune, color: Color(0xFFC79A3E)),
            title: const Text('AJUSTES'),
            onTap: () {
              GameAudio.instance.click(); // ✅ Click al presionar
              Navigator.pop(sheet);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OptionsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Color(0xFFC79A3E)),
            title: const Text('ESTADISTICAS'),
            onTap: () {
              GameAudio.instance.click(); // ✅ Click al presionar
              Navigator.pop(sheet);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatisticsScreen(statistics: state.statistics),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card_rounded, color: Color(0xFFC79A3E)),
            title: const Text('PERSONAJES'),
            onTap: () {
              GameAudio.instance.click(); // ✅ Click al presionar
              Navigator.pop(sheet);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_stories_rounded, color: Color(0xFFC79A3E)),
            title: const Text('EVENTOS Y ERAS'),
            onTap: () {
              GameAudio.instance.click();
              Navigator.pop(sheet);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventsErasScreen(
                    reachedEra: state.gameState.currentEra,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_circle_rounded, color: Color(0xFFC79A3E)),
            title: const Text('FINALES'),
            onTap: () {
              GameAudio.instance.click();
              Navigator.pop(sheet);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EndingsGalleryScreen()));
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _CharacterUnlockDialog extends StatelessWidget {
  const _CharacterUnlockDialog({required this.character});
  final Character character;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFF16211B),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFFC79A3E)),
    ),
    title: const Text(
      'NUEVA VOZ EN EL GOBIERNO',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'monospace',
        color: Color(0xFFC79A3E),
        fontSize: 14,
        letterSpacing: 1.2,
      ),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          character.imageAsset,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 14),
        Text(
          character.name.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFFFFF8E7),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          character.role,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFFEAE1D3),
            fontSize: 12,
          ),
        ),
      ],
    ),
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      FilledButton.icon(
        onPressed: () {
          GameAudio.instance.click(); // ✅ Click al cerrar
          Navigator.pop(context);
        },
        icon: const Icon(Icons.volume_up),
        label: const Text('ESCUCHAR'),
        style: FilledButton.styleFrom(
          backgroundColor: Color(0xFFC79A3E),
          foregroundColor: Color(0xFF16211B),
        ),
      ),
    ],
  );
}

class _CardArea extends StatelessWidget {
  const _CardArea({
    required this.card,
    required this.characterName,
    required this.imageAsset,
    required this.showIntro,
    required this.onIntroComplete,
    required this.onSwiped,
    required this.onHighlightChange,
  });

  final GameCard card;
  final String characterName;
  final String imageAsset;
  final bool showIntro;
  final VoidCallback onIntroComplete;
  final void Function(SwipeDirection direction) onSwiped;
  final void Function(Map<StatType, bool> highlights) onHighlightChange;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Column(
            children: [
              const Expanded(child: SizedBox()),
              const SizedBox(height: 12),
              Text(
                characterName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF16211B),
                  fontSize: 15,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Positioned.fill(
          bottom: 42,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (showIntro)
                    Positioned.fill(
                      child: DealingIntro(onComplete: onIntroComplete),
                    )
                  else ...[
                    const Positioned.fill(child: CardStackBackdrop()),
                    Positioned.fill(
                      child: SwipeableCard(
                        key: ValueKey(card.id),
                        card: card,
                        characterName: characterName,
                        imageAsset: imageAsset,
                        onSwiped: onSwiped,
                        onHighlightChange: onHighlightChange,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.highlightedStats,
    required this.canUseRescue,
    required this.onUseRescue,
  });

  final GameControllerState state;
  final Map<StatType, bool> highlightedStats;
  final bool Function(StatType) canUseRescue;
  final void Function(StatType) onUseRescue;

  static const List<StatType> _statOrder = [
    StatType.pueblo,
    StatType.economia,
    StatType.relacionesExteriores,
    StatType.aparatoDelEstado,
  ];

  static const Map<StatType, IconData> _iconFor = {
    StatType.pueblo: Icons.groups_rounded,
    StatType.economia: Icons.attach_money_rounded,
    StatType.relacionesExteriores: Icons.public_rounded,
    StatType.aparatoDelEstado: Icons.account_balance_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final hasAnyRescue = _statOrder.any((type) => canUseRescue(type));

    const Color boneWhite = Color(0xFFFFF8E7);
    const Color ink = Color(0xFF16211B);

    return GestureDetector(
      onTap: () {
        // ✅ Click al presionar el header (volver atrás)
        GameAudio.instance.click();
        Navigator.pop(context);
      },
      child: Container(
        color: ink,
        padding: const EdgeInsets.fromLTRB(14, 28, 14, 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Expanded(child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final StatType type in _statOrder)
                    StatIndicator(
                      icon: _iconFor[type]!,
                      label: type == StatType.relacionesExteriores
                          ? 'Exterior'
                          : type.label,
                      value: state.gameState.statOf(type).value,
                      isInDanger: state.gameState.statOf(type).isInDanger,
                      size: 24,
                      showValue: true,
                      isHighlighted: highlightedStats[type] ?? false,
                    ),
                ],
              )),
            ]),
            const SizedBox(height: 6),
            Container(
              height: 30,
              width: 220,
              decoration: BoxDecoration(
                border: Border.all(color: boneWhite, width: 1.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final type in _statOrder)
                    _RescuePower(
                      type: type,
                      enabled: canUseRescue(type),
                      onPressed: () => onUseRescue(type),
                      showIcon: hasAnyRescue,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TURNO ${state.gameState.turn}  ·  '
                  '${state.gameState.currentEra.label.toUpperCase()}',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: boneWhite,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _RescuePower extends StatelessWidget {
  const _RescuePower({
    required this.type,
    required this.enabled,
    required this.onPressed,
    required this.showIcon,
  });

  final StatType type;
  final bool enabled;
  final VoidCallback onPressed;
  final bool showIcon;

  static const _icons = {
    StatType.pueblo: Icons.volunteer_activism_rounded,
    StatType.economia: Icons.savings_rounded,
    StatType.relacionesExteriores: Icons.handshake_rounded,
    StatType.aparatoDelEstado: Icons.shield_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (!showIcon) {
      return const SizedBox(width: 16, height: 16);
    }

    const Color boneWhite = Color(0xFFFFF8E7);

    return TextButton(
      onPressed: enabled ? onPressed : null,
      child: Icon(
        _icons[type],
        size: 14,
        color: enabled ? boneWhite : const Color(0x66FFF8E7),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.days, required this.onTap});
  final int days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF16211B),
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: InkWell(
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'DIAS EN EL PODER',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFFFF8E7),
                fontSize: 22,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$days',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFFFF8E7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}