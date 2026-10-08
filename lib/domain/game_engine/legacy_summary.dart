import 'game_state.dart';
import '../../data/models/game_mode.dart';

/// El desenlace político y el legado de las decisiones cuentan historias distintas.
class LegacySummary {
  static List<String> paragraphs(GameState state) {
    final flags = state.flags;
    final result = <String>[];
    if (state.promise != null) {
      final status = switch (state.promiseStatus) {
        PromiseStatus.fulfilled => 'cumplida',
        PromiseStatus.broken => 'incumplida',
        _ => 'pendiente',
      };
      result.add(
          'Tu promesa de gobierno: ${state.promise!.label.toLowerCase()}. Quedó $status.');
    }
    if (flags.contains('misterio_encubierto')) {
      result.add(
          'La cosecha desaparecida terminó en un archivo cerrado. Quienes conocían sus secretos conservaron poder sobre el siguiente gobierno.');
    } else if (flags.contains('misterio_reparado')) {
      result.add(
          'La investigación dejó un archivo público y una reparación para las familias. La isla aprendió a exigir cuentas.');
    } else if (flags.contains('misterio_revelado')) {
      result.add(
          'Publicaste pruebas del desvío de la cosecha. La verdad cambió la relación entre el puerto y el gobierno.');
    }
    if (flags.contains('agua_legado_comun')) {
      result.add(
          'El agua quedó como un bien común. La promesa de la acequia terminó en una red que la isla administra y financia.');
    } else if (flags.contains('agua_legado_privado')) {
      result.add(
          'La red de agua se renovó con una concesión regulada. La isla ganó infraestructura y dejó a sus sucesores la tarea de vigilar las tarifas.');
    } else if (flags.contains('agua_barrios')) {
      result.add(
          'Los barrios recuerdan que fueron los primeros en recibir agua cuando todo faltaba. La reconstrucción aún tiene capítulos pendientes.');
    } else if (flags.contains('agua_ingenio')) {
      result.add(
          'Tu primera apuesta fue salvar la cosecha. El ingenio siguió trabajando, mientras los barrios esperaban que la recuperación también llegara a sus casas.');
    }
    if (flags.contains('puerto_legado_autonomo')) {
      result.add(
          'El puerto terminó automatizado, pero la isla conservó las claves. Quienes lleguen después podrán cambiar sus reglas.');
    } else if (flags.contains('puerto_legado_dependiente')) {
      result.add(
          'El proveedor modernizó el puerto y conservó su control digital. Las cuentas mejoraron; la autonomía quedó ligada al contrato.');
    } else if (flags.contains('puerto_credito') ||
        flags.contains('puerto_local')) {
      result.add(flags.contains('puerto_credito')
          ? 'El adelanto extranjero reabrió el muelle. Sus condiciones siguieron presentes en cada discusión sobre el puerto.'
          : 'Elegiste reconstruir el muelle con talleres locales. La isla conservó esa experiencia, aunque la obra exigió tiempo y reservas.');
    }
    if (state.pendingConsequences.isNotEmpty) {
      result.add(
          'Quedaron ${state.pendingConsequences.length} asuntos en la agenda. El siguiente gobierno heredará: ${state.pendingConsequences.map((e) => e.title).join('; ')}.');
    }
    if (result.isEmpty) {
      result.add(
          'La isla recordará un gobierno de ${state.turn} decisiones. Su historia continúa con quienes quedaron aquí.');
    }
    return result;
  }
}
