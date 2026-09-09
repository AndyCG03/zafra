import 'stat.dart';

/// Un final narrativo. Se resuelve cuando alguna estadística colapsa
/// (llega a 0 o a 100). Ver docs/DISEÑO_JUEGO.md, "Diseño de finales".
class Ending {
  final String id;
  final StatType causedBy;
  final bool wasAtMin; // true = colapsó por llegar a 0, false = a 100
  final String eraId; // en qué era ocurrió, para variar el texto
  final String title;
  final String description;
  final String imageAsset;
  final bool isSurvival;

  const Ending({
    required this.id,
    required this.causedBy,
    required this.wasAtMin,
    required this.eraId,
    required this.title,
    required this.description,
    required this.imageAsset,
    this.isSurvival = false,
  });

  factory Ending.fromJson(Map<String, dynamic> json) {
    return Ending(
      id: json['id'] as String,
      causedBy: StatType.values.firstWhere(
        (e) => e.name == json['causedBy'],
      ),
      wasAtMin: json['wasAtMin'] as bool,
      eraId: json['era'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageAsset: json['imageAsset'] as String,
      isSurvival: json['isSurvival'] as bool? ?? false,
    );
  }
}
