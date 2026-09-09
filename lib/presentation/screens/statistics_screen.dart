import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/era.dart';
import '../../data/models/stat.dart';
import '../../data/models/game_record.dart';
import '../../domain/game_engine/game_statistics.dart';
import '../../services/persistence/progress_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key, required this.statistics});

  final GameStatistics statistics;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _progress = ProgressService();
  late final Future<void> _ready = _progress.init();

  static const _icons = {
    StatType.pueblo: Icons.groups_rounded,
    StatType.economia: Icons.attach_money_rounded,
    StatType.relacionesExteriores: Icons.public_rounded,
    StatType.aparatoDelEstado: Icons.account_balance_rounded,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.container,
    appBar: AppBar(
      title: const Text('ESTADÍSTICAS', style: TextStyle(fontFamily: 'monospace', letterSpacing: 2)),
      backgroundColor: AppTheme.background,
      foregroundColor: AppTheme.accent,
    ),
    body: FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bestGames = _progress.bestGames;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _Title('RESUMEN GENERAL'),
            const SizedBox(height: 10),
            Row(children: [
              _Counter(label: 'PARTIDAS', value: _progress.gamesPlayed),
              const SizedBox(width: 10),
              _Counter(label: 'PERSONAJES', value: _progress.unlockedCharacters.length),
              const SizedBox(width: 10),
              _Counter(label: 'FINALES', value: _progress.seenEndingIds.length),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _Counter(label: 'TURNOS TOTALES', value: _progress.totalTurnsPlayed),
              const SizedBox(width: 10),
              _Counter(label: 'IZQUIERDA', value: _progress.totalLeftSwipes),
              const SizedBox(width: 10),
              _Counter(label: 'DERECHA', value: _progress.totalRightSwipes),
            ]),
            const SizedBox(height: 26),
            const _Title('MEJORES PARTIDAS'),
            const SizedBox(height: 10),
            if (bestGames.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Aún no has completado ningún mandato.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.background, fontFamily: 'monospace')),
              )
            else
              for (var i = 0; i < bestGames.length; i++)
                _BestGameCard(rank: i + 1, record: bestGames[i], icons: _icons),
            const SizedBox(height: 26),
            const _Title('PARTIDA ACTUAL'),
            const SizedBox(height: 10),
            Row(children: [
              _Counter(label: 'TURNOS', value: widget.statistics.totalTurns),
              const SizedBox(width: 10),
              _Counter(label: 'IZQUIERDA', value: widget.statistics.leftSwipes),
              const SizedBox(width: 10),
              _Counter(label: 'DERECHA', value: widget.statistics.rightSwipes),
            ]),
            const SizedBox(height: 26),
            const _Title('PROMEDIO DE ESTADÍSTICAS POR ERA'),
            const SizedBox(height: 10),
            for (final era in Era.values)
              if (widget.statistics.averagesFor(era).isNotEmpty)
                _EraAverage(era: era, averages: widget.statistics.averagesFor(era), icons: _icons),
            if (widget.statistics.timeline.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Text('Aún no hay decisiones registradas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.background, fontFamily: 'monospace')),
              ),
            if (widget.statistics.timeline.isNotEmpty) ...[
              const SizedBox(height: 22),
              const _Title('LÍNEA DE TIEMPO'),
              const SizedBox(height: 10),
              for (final record in widget.statistics.timeline.reversed) _TimelineEntry(record: record),
            ],
          ],
        );
      },
    ),
  );
}

class _BestGameCard extends StatelessWidget {
  const _BestGameCard({required this.rank, required this.record, required this.icons});
  final int rank;
  final GameRecord record;
  final Map<StatType, IconData> icons;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white54,
      borderRadius: BorderRadius.circular(8),
      border: const Border(left: BorderSide(color: AppTheme.accent, width: 4)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$rank',
            style: const TextStyle(
              color: AppTheme.background,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            record.endingTitle ?? 'Mandato finalizado',
            style: const TextStyle(color: AppTheme.background, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 14, runSpacing: 4, children: [
        Text('${record.turns} turnos', style: const TextStyle(color: AppTheme.background, fontSize: 11)),
        Text('${record.days} días en el poder', style: const TextStyle(color: AppTheme.background, fontSize: 11)),
        Text('Llegó a: ${record.era.label}', style: const TextStyle(color: AppTheme.background, fontSize: 11)),
      ]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        for (final type in StatType.values)
          Column(children: [
            Icon(icons[type], color: AppTheme.background, size: 16),
            Text('${record.finalStats[type]}', style: const TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold, fontSize: 11)),
          ]),
      ]),
    ]),
  );
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(6)),
    child: Column(children: [Text('$value', style: const TextStyle(color: AppTheme.accent, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 3), Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 8, letterSpacing: .7), textAlign: TextAlign.center)]),
  ));
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: AppTheme.background, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1));
}

class _EraAverage extends StatelessWidget {
  const _EraAverage({required this.era, required this.averages, required this.icons});
  final Era era;
  final Map<StatType, double> averages;
  final Map<StatType, IconData> icons;
  @override
  Widget build(BuildContext context) => Card(color: Colors.white54, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(era.label.toUpperCase(), style: const TextStyle(color: AppTheme.background, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [for (final type in StatType.values) Column(children: [Icon(icons[type], color: AppTheme.background, size: 19), Text(averages[type]!.toStringAsFixed(1), style: const TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold))])]),
  ])));
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.record});
  final StatChangeRecord record;
  @override
  Widget build(BuildContext context) {
    final changes = StatType.values.where((type) => record.changeFor(type) != 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(6), border: const Border(left: BorderSide(color: AppTheme.accent, width: 4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TURNO ${record.turn} · ${record.direction.name.toUpperCase()} · ${record.era.label}', style: const TextStyle(color: AppTheme.background, fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(spacing: 10, runSpacing: 4, children: [for (final type in changes) Text('${type.label}: ${record.before[type]} → ${record.after[type]} (${record.changeFor(type) > 0 ? '+' : ''}${record.changeFor(type)})', style: const TextStyle(color: AppTheme.background, fontSize: 11))]),
      ]),
    );
  }
}
