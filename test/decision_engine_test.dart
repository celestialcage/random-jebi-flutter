import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_jebi_flutter/decision/decision_engine.dart';
import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:random_jebi_flutter/decision/decision_modes.dart';

void main() {
  final twoCharacters = CharacterSet(
    id: 'set-1',
    title: '두 캐릭터',
    characters: const [
      CustomCharacter(id: 'a', name: 'A'),
      CustomCharacter(id: 'b', name: 'B'),
    ],
  );

  test('캐릭터 2명이면 두 명 모두 선택된다', () {
    final engine = DecisionEngine(random: Random(42));

    final round = engine.createRound(
      set: twoCharacters,
      mode: decisionModes[0],
    );

    expect(round.first.id, 'a');
    expect(round.second.id, 'b');
  });

  test('두 캐릭터의 결과는 항상 반대다', () {
    final engine = DecisionEngine(random: Random(42));

    final round = engine.createRound(
      set: twoCharacters,
      mode: decisionModes[0],
    );

    final answers = {round.resultFor('a'), round.resultFor('b')};

    expect(answers, {'해', '하지마'});
  });

  test('같은 라운드에서는 결과가 유지된다', () {
    final engine = DecisionEngine(random: Random(42));

    final round = engine.createRound(
      set: twoCharacters,
      mode: decisionModes[0],
    );

    final firstAnswer = round.resultFor('a');

    expect(round.resultFor('a'), firstAnswer);
    expect(round.resultFor('a'), firstAnswer);
  });

  test('3명 이상이면 중복 없이 두 명을 선택한다', () {
    final set = CharacterSet(
      id: 'set-2',
      title: '세 캐릭터',
      characters: const [
        CustomCharacter(id: 'a', name: 'A'),
        CustomCharacter(id: 'b', name: 'B'),
        CustomCharacter(id: 'c', name: 'C'),
      ],
    );

    final engine = DecisionEngine(random: Random(42));

    for (int i = 0; i < 100; i++) {
      final round = engine.createRound(set: set, mode: decisionModes[0]);

      expect(round.first.id, isNot(round.second.id));
      expect({'a', 'b', 'c'}, contains(round.first.id));
      expect({'a', 'b', 'c'}, contains(round.second.id));
    }
  });

  test('새로운 질문 모드도 엔진 수정 없이 적용된다', () {
    final customMode = DecisionMode(
      id: 'have',
      label: '가질까?',
      positive: '가져',
      negative: '가지지마',
    );

    final engine = DecisionEngine(random: Random(42));

    final round = engine.createRound(set: twoCharacters, mode: customMode);

    expect({round.resultFor('a'), round.resultFor('b')}, {'가져', '가지지마'});
  });

  test('캐릭터가 1명이면 세트를 생성할 수 없다', () {
    expect(
      () => CharacterSet(
        id: 'invalid',
        title: '잘못된 세트',
        characters: const [CustomCharacter(id: 'a', name: 'A')],
      ),
      throwsArgumentError,
    );
  });
}
