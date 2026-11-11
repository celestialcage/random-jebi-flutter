import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:random_jebi_flutter/repositories/character_set_repository.dart';
import 'package:random_jebi_flutter/services/character_set_store.dart';

class FakeCharacterSetRepository extends CharacterSetRepository {
  List<CharacterSet> saved = [];

  @override
  Future<List<CharacterSet>> loadAll() async {
    return List.of(saved);
  }

  @override
  Future<void> saveAll(List<CharacterSet> sets) async {
    saved = List.of(sets);
  }
}

void main() {
  test('기존 JSON에 초점 필드가 없어도 중앙 정렬로 복원된다', () {
    final oldJson = {'id': 'link', 'name': '링크', 'imageFileName': 'link.jpg'};

    final character = CustomCharacter.fromJson(oldJson);

    expect(character.focusX, 0.0);
    expect(character.focusY, 0.0);
  });

  test('초점 좌표를 JSON으로 저장하고 복원할 수 있다', () {
    const original = CustomCharacter(
      id: 'link',
      name: '링크',
      imageFileName: 'link.jpg',
      focusX: -0.5,
      focusY: 0.7,
    );

    final raw = jsonEncode(original.toJson());

    final restored = CustomCharacter.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    expect(restored.focusX, -0.5);
    expect(restored.focusY, 0.7);
    expect(restored.imageFileName, 'link.jpg');
  });

  test('세트 수정 시 캐릭터별 초점이 저장된다', () async {
    final repository = FakeCharacterSetRepository();

    final store = CharacterSetStore(repository: repository);

    await store.saveSet(
      title: '젤다의 전설',
      characters: const [
        CharacterInput(
          id: 'link',
          name: '링크',
          existingFileName: 'link.jpg',
          focusX: 0.3,
          focusY: -0.8,
        ),
        CharacterInput(
          id: 'zelda',
          name: '젤다',
          existingFileName: 'zelda.jpg',
          focusX: -0.4,
          focusY: 0.5,
        ),
      ],
    );

    final characters = repository.saved.single.characters;

    expect(characters[0].focusX, 0.3);
    expect(characters[0].focusY, -0.8);
    expect(characters[1].focusX, -0.4);
    expect(characters[1].focusY, 0.5);
  });

  test('범위를 벗어난 초점값은 저장을 거부한다', () async {
    final store = CharacterSetStore(repository: FakeCharacterSetRepository());

    await expectLater(
      store.saveSet(
        title: '테스트',
        characters: const [
          CharacterInput(
            id: 'a',
            name: 'A',
            existingFileName: 'a.jpg',
            focusX: 2.0,
          ),
          CharacterInput(id: 'b', name: 'B', existingFileName: 'b.jpg'),
        ],
      ),
      throwsFormatException,
    );
  });
}
