class CustomCharacter {
  final String id;
  final String name;
  final String? imageFileName;

  // -1.0 ~ 1.0
  final double focusX;
  final double focusY;

  const CustomCharacter({
    required this.id,
    required this.name,
    this.imageFileName,
    this.focusX = 0.0,
    this.focusY = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageFileName': imageFileName,
    'focusX': focusX,
    'focusY': focusY,
  };

  factory CustomCharacter.fromJson(Map<String, dynamic> json) {
    return CustomCharacter(
      id: json['id'] as String,
      name: json['name'] as String,
      imageFileName: json['imageFileName'] as String?,
      focusX: ((json['focusX'] as num?)?.toDouble() ?? 0.0)
          .clamp(-1.0, 1.0)
          .toDouble(),
      focusY: ((json['focusY'] as num?)?.toDouble() ?? 0.0)
          .clamp(-1.0, 1.0)
          .toDouble(),
    );
  }
}

class CharacterSet {
  final String id;
  final String title;
  final List<CustomCharacter> characters;

  CharacterSet({
    required this.id,
    required this.title,
    required List<CustomCharacter> characters,
  }) : characters = List.unmodifiable(characters) {
    if (characters.length < 2) {
      throw ArgumentError('캐릭터 데이터는 최소 2개가 필요합니다.');
    }

    final ids = characters.map((c) => c.id).toSet();

    if (ids.length != characters.length) {
      throw ArgumentError('캐릭터 id가 중복되었습니다.');
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'characters': characters.map((c) => c.toJson()).toList(),
  };

  factory CharacterSet.fromJson(Map<String, dynamic> json) {
    return CharacterSet(
      id: json['id'] as String,
      title: json['title'] as String,
      characters: [
        for (final item in json['characters'] as List<dynamic>)
          CustomCharacter.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

class DecisionMode {
  final String id;
  final String label;
  final String positive;
  final String negative;

  const DecisionMode({
    required this.id,
    required this.label,
    required this.positive,
    required this.negative,
  });
}

class DecisionRound {
  final String setId;
  final DecisionMode mode;

  final CustomCharacter first;
  final CustomCharacter second;

  final String positiveCharacterId;

  const DecisionRound({
    required this.setId,
    required this.mode,
    required this.first,
    required this.second,
    required this.positiveCharacterId,
  });

  bool isPositiveFor(String characterId) {
    if (characterId != first.id && characterId != second.id) {
      throw ArgumentError('이번 라운드에 없는 캐릭터입니다.');
    }

    return positiveCharacterId == characterId;
  }

  String resultFor(String characterId) {
    return isPositiveFor(characterId) ? mode.positive : mode.negative;
  }
}
