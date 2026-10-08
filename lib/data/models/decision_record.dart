class DecisionRecord {
  final int turn;
  final int importance;
  final String cardId;
  final String scene;
  final String choice;
  final List<String> notes;
  const DecisionRecord(
      {required this.turn,
      this.importance = 0,
      required this.cardId,
      required this.scene,
      required this.choice,
      this.notes = const []});
  Map<String, dynamic> toJson() => {
        'turn': turn,
        'importance': importance,
        'cardId': cardId,
        'scene': scene,
        'choice': choice,
        'notes': notes
      };
  factory DecisionRecord.fromJson(Map<String, dynamic> json) => DecisionRecord(
      turn: (json['turn'] as num).toInt(),
      importance: (json['importance'] as num?)?.toInt() ?? 0,
      cardId: json['cardId'] as String,
      scene: json['scene'] as String,
      choice: json['choice'] as String,
      notes: (json['notes'] as List? ?? const []).cast<String>());
}
