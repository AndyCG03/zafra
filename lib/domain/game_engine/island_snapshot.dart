import '../../data/models/stat.dart';
import 'game_state.dart';

enum IslandDistrict {
  water('La acequia'),
  neighborhoods('Los barrios'),
  mill('El ingenio'),
  port('El puerto'),
  palace('La plaza');

  final String label;
  const IslandDistrict(this.label);
}

class DistrictReport {
  final String title;
  final String detail;
  const DistrictReport(this.title, this.detail);
}

/// A view of decisions already made. Opening the map never advances a turn.
class IslandSnapshot {
  final Set<String> flags;
  final bool poverty;
  IslandSnapshot(GameState state)
      : flags = Set.unmodifiable(state.flags),
        poverty = state.statOf(StatType.economia).value <= 20;
  bool has(String flag) => flags.contains(flag);
  bool get waterRepaired =>
      has('agua_obra') || has('agua_recirculada') || has('agua_resuelta');
  bool get commonWater => has('agua_legado_comun');
  bool get localCouncils => has('agua_local');
  bool get military => has('agua_control') || has('puerto_militar');
  bool get portRepaired =>
      has('puerto_credito') || has('puerto_local') || has('puerto_resuelto');
  bool get autonomousPort => has('puerto_legado_autonomo');
  bool get dependentPort => has('puerto_legado_dependiente');
  bool get sharedPort => has('puerto_abierto') || has('puerto_cooperativa');
  bool get queues =>
      has('registro_provisional') ||
      has('ventanilla_abierta') ||
      has('turno_tarde');
  bool get simplifiedQueues => has('tramites_unificados');
  DistrictReport report(IslandDistrict district) => switch (district) {
        IslandDistrict.water => has('agua_legado_privado')
            ? const DistrictReport('La red tiene concesionario',
                'Se renovaron los depósitos. Las tarifas y el acceso dependen del contrato que dejaste firmado.')
            : commonWater
                ? const DistrictReport('El agua es un bien común',
                    'Las tarifas solidarias sostienen la red. Los depósitos ya llevan el sello de la isla.')
                : waterRepaired
                    ? const DistrictReport('La acequia vuelve a funcionar',
                        'La obra cambió el paisaje. El reparto y el mantenimiento siguen siendo decisiones políticas.')
                    : has('agua_cisternas')
                        ? const DistrictReport('La isla espera las cisternas',
                            'El suministro provisional gana tiempo. La acequia dañada aún necesita una reparación duradera.')
                        : const DistrictReport('Una acequia rota',
                            'El ciclón dejó fugas y depósitos vacíos. Tus decisiones determinarán quién recibe el agua y quién cuida la red.'),
        IslandDistrict.neighborhoods => DistrictReport(
            localCouncils
                ? 'Los consejos tienen las llaves'
                : has('agua_control')
                    ? 'Hay soldados junto a los pozos'
                    : has('refugios_vecinales')
                        ? 'La escuela también es un refugio'
                        : 'Las casas después del ciclón',
            '${localCouncils ? 'Los vecinos administran los depósitos y publican sus cuentas.' : has('refugios_vecinales') ? 'Los barrios conservan llaves del refugio y una ruta de evacuación.' : 'El barrio vive las consecuencias del reparto y las obras.'} ${simplifiedQueues ? 'Unificaste los trámites: la cola se acortó.' : queues ? 'La oficina tiene una cola que vuelve cada mañana.' : 'La oficina aún no ha cambiado sus reglas.'}'),
        IslandDistrict.mill => DistrictReport(
            has('agua_recirculada')
                ? 'La cosecha reutiliza el agua'
                : has('agua_parche')
                    ? 'El parche mantiene el ingenio'
                    : 'El ingenio espera su cosecha',
            '${has('agua_recirculada') ? 'Un circuito devuelve el agua a los depósitos y reduce el desperdicio.' : 'El trabajo depende del agua y de las reparaciones que hayas financiado.'} ${has('aprendices_puerto') ? 'Los aprendices tienen herramientas y un oficio que compartir.' : poverty ? 'Las reservas bajas obligan a aplazar trabajos.' : 'Las exportaciones siguen conectando el taller con el muelle.'}'),
        IslandDistrict.port => DistrictReport(
            dependentPort
                ? 'Las claves están fuera de la isla'
                : autonomousPort
                    ? 'La isla conserva sus claves'
                    : has('puerto_militar')
                        ? 'El muelle tiene escolta militar'
                        : sharedPort
                            ? 'Varios operadores comparten el muelle'
                            : portRepaired
                                ? 'El puerto vuelve a abrir'
                                : 'El muelle sigue dañado',
            '${dependentPort ? 'El proveedor administra los accesos digitales: modernización y dependencia conviven en el mismo contrato.' : autonomousPort ? 'La auditoría dejó el control del sistema en manos de la isla.' : sharedPort ? 'La cooperativa o el acceso compartido dan voz a más trabajadores.' : 'Las garantías y las licencias que firmes cambiarán quién puede usarlo.'} ${has('misterio_encubierto') ? 'El expediente del almacén sigue reservado.' : has('misterio_revelado') ? 'El desvío de la cosecha dejó pruebas públicas.' : 'El almacén aún conserva preguntas sobre sus cargamentos.'}'),
        IslandDistrict.palace => DistrictReport(
            has('biblioteca_publica')
                ? 'La plaza tiene una biblioteca'
                : has('estatua_local')
                    ? 'Tu estatua mira hacia la cantina'
                    : has('audiencia_abierta')
                        ? 'La plaza recibe una audiencia'
                        : 'La plaza frente a palacio',
            '${has('biblioteca_publica') ? 'Elegiste libros donde podía estar tu monumento. La cantina ya organiza lecturas.' : has('estatua_local') ? 'Los artistas dieron trabajo al taller; la Cantinera insiste en que la estatua escucha mejor.' : 'Aquí se cruzan las órdenes de palacio y las preguntas de la calle.'} ${has('lider_pacto') ? 'El pacto exige reuniones abiertas y presupuesto.' : has('general_privilegios') ? 'La brigada del General conserva una excepción a las auditorías.' : 'Los aliados siguen esperando acuerdos que también les cuesten algo.'}'),
      };
}
