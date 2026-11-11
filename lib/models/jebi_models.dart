class JebiOption {
  final String id;
  final String text;
  final bool isWinner;

  const JebiOption({
    required this.id,
    required this.text,
    required this.isWinner,
  });

  JebiOption copyWith({String? text, bool? isWinner}) {
    return JebiOption(
      id: id,
      text: text ?? this.text,
      isWinner: isWinner ?? this.isWinner,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'isWinner': isWinner};
  }

  factory JebiOption.fromJson(Map<String, dynamic> json) {
    return JebiOption(
      id: json['id'] as String,
      text: json['text'] as String,
      isWinner: json['isWinner'] as bool,
    );
  }
}

class JebiSlot {
  final String id;
  final String title;
  final List<JebiOption> items;
  final int createdAt;

  JebiSlot({
    required this.id,
    required this.title,
    required List<JebiOption> items,
    required this.createdAt,
  }) : items = List<JebiOption>.unmodifiable(items);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt,
    };
  }

  factory JebiSlot.fromJson(Map<String, dynamic> json) {
    return JebiSlot(
      id: json['id'] as String,
      title: json['title'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => JebiOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as int,
    );
  }
}
