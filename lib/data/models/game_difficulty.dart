enum GameDifficulty {
  story(
      'Historia',
      'Más margen para explorar la historia; las promesas y las rivalidades siguen teniendo consecuencias.',
      .7,
      .8),
  normal('Normal', 'El equilibrio original del juego.', 1, 1),
  challenge('Desafío', 'Pérdidas más duras y ganancias moderadas.', 1.35, .9);

  final String label;
  final String description;
  final double loss;
  final double gain;
  const GameDifficulty(this.label, this.description, this.loss, this.gain);
}
