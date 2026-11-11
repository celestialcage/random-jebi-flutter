class DrawItem {
  final String id;
  final String text;
  final bool isWinner;

  const DrawItem({
    required this.id,
    required this.text,
    required this.isWinner,
  });
}

class DrawResult {
  final int round;
  final DrawItem item;

  const DrawResult({required this.round, required this.item});
}
