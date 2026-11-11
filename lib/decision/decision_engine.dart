import 'dart:math';

import 'package:random_jebi_flutter/decision/decision_models.dart';

class DecisionEngine {
  final Random _random;

  DecisionEngine({Random? random}) : _random = random ?? Random();

  DecisionRound createRound({
    required CharacterSet set,
    required DecisionMode mode,
  }) {
    final characters = set.characters;

    if (characters.length < 2) {
      throw StateError('캐릭터 데이터는 최소 2개가 필요합니다.');
    }

    late final CustomCharacter first;
    late final CustomCharacter second;

    if (characters.length == 2) {
      // 2명이면 등록한 두 캐릭터 그대로 사용
      first = characters[0];
      second = characters[1];
    } else {
      // 3명 이상이면 무작위로 섞어서 두 명 선택
      final shuffled = List<CustomCharacter>.of(characters)..shuffle(_random);

      first = shuffled[0];
      second = shuffled[1];
    }

    // 한 캐릭터는 긍정, 다른 캐릭터는 부정
    final positiveCharacterId = _random.nextBool() ? first.id : second.id;

    return DecisionRound(
      setId: set.id,
      mode: mode,
      first: first,
      second: second,
      positiveCharacterId: positiveCharacterId,
    );
  }
}
