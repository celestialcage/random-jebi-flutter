import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:random_jebi_flutter/repositories/character_set_repository.dart';
import 'package:random_jebi_flutter/services/character_set_store.dart';

// 실제 기기 저장소에 접근하지 않는 Fake Repository
class FakeCharacterSetRepository extends CharacterSetRepository {
  List<CharacterSet> stored = [];

  @override
  Future<List<CharacterSet>> loadAll() async {
    return List.of(stored);
  }

  @override
  Future<void> saveAll(List<CharacterSet> sets) async {
    stored = List.of(sets);
  }
}

void main() {
  final exampleSet = CharacterSet(
    id: 'zelda-set',
    title: '젤다의 전설',
    characters: const [
      CustomCharacter(id: 'link', name: '링크', imageFileName: 'link.jpg'),
      CustomCharacter(id: 'zelda', name: '젤다', imageFileName: 'zelda.png'),
    ],
  );

  test('JSON 직렬화 후 복원해도 이미지 파일명이 유지된다', () {
    final encoded = jsonEncode(exampleSet.toJson());

    final restored = CharacterSet.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );

    expect(restored.id, exampleSet.id);
    expect(restored.title, '젤다의 전설');
    expect(restored.characters.length, 2);
    expect(restored.characters[0].name, '링크');
    expect(restored.characters[0].imageFileName, 'link.jpg');
    expect(restored.characters[1].imageFileName, 'zelda.png');
  });

  test('캐릭터 ID가 중복되면 세트 생성을 거부한다', () {
    expect(
      () => CharacterSet(
        id: 'invalid',
        title: '중복',
        characters: const [
          CustomCharacter(id: 'a', name: 'A'),
          CustomCharacter(id: 'a', name: 'B'),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('이미지가 없는 캐릭터는 저장할 수 없다', () async {
    final fake = FakeCharacterSetRepository();
    final store = CharacterSetStore(repository: fake);

    await expectLater(
      store.saveSet(
        title: '이미지 없는 세트',
        characters: const [
          CharacterInput(id: 'a', name: 'A'),
          CharacterInput(id: 'b', name: 'B'),
        ],
      ),
      throwsFormatException,
    );

    expect(fake.stored, isEmpty);
  });

  test('기존 세트를 수정해도 세트 ID와 캐릭터 ID가 유지된다', () async {
    final fake = FakeCharacterSetRepository();
    final store = CharacterSetStore(repository: fake);

    const characters = [
      CharacterInput(id: 'link', name: '링크', existingFileName: 'link.jpg'),
      CharacterInput(id: 'zelda', name: '젤다', existingFileName: 'zelda.jpg'),
    ];

    await store.saveSet(title: '젤다의 전설', characters: characters);

    final originalId = fake.stored.single.id;

    await store.saveSet(
      setId: originalId,
      title: '젤다의 전설 수정',
      characters: const [
        CharacterInput(id: 'link', name: '용사 링크', existingFileName: 'link.jpg'),
        CharacterInput(id: 'zelda', name: '젤다', existingFileName: 'zelda.jpg'),
      ],
    );

    expect(fake.stored.length, 1);
    expect(fake.stored.single.id, originalId);
    expect(fake.stored.single.title, '젤다의 전설 수정');
    expect(fake.stored.single.characters.first.id, 'link');
    expect(fake.stored.single.characters.first.name, '용사 링크');
  });
}
