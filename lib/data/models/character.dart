/// Personaje recurrente que "habla" a través de las cartas.
/// Ver docs/DISEÑO_JUEGO.md, sección "Diseño de personajes recurrentes".
class Character {
  final String id;
  final String name;
  final String role;
  final String imageAsset;
  final String unlockEraId;

  /// Biografía/descripción del personaje (opcional)
  final String? bio;

  const Character({
    required this.id,
    required this.name,
    required this.role,
    required this.imageAsset,
    required this.unlockEraId,
    this.bio,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      imageAsset: json['imageAsset'] as String,
      unlockEraId: json['unlockEra'] as String? ?? 'fundacional',
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'imageAsset': imageAsset,
    'unlockEra': unlockEraId,
    if (bio != null) 'bio': bio,
  };
}