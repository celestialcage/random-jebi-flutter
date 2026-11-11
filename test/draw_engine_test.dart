import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_jebi_flutter/draw/draw_engine.dart';
import 'package:random_jebi_flutter/draw/draw_item.dart';
import 'package:random_jebi_flutter/draw/lucky_draw_rules.dart';

void main() {
  group('럭키드로우', () {
    test('참가자 수에 맞게 제비가 생성된다', () {
      final items = createLuckyDrawItems(total: 10, winners: 3);

      expect(items.length, 10);
      expect(items.where((item) => item.isWinner).length, 3);
    });

    test('잘못된 당첨자 수를 거부한다', () {
      expect(
        () => createLuckyDrawItems(total: 5, winners: 5),
        throwsArgumentError,
      );
    });

    test('중복 추첨 없이 모든 당첨자가 나오면 종료된다', () {
      const winnerCount = 3;

      final engine = DrawEngine(
        items: createLuckyDrawItems(total: 10, winners: winnerCount),
        random: Random(42), // 난수 생성기에 고정된 seed를 전달해서 동일한 실행 환경에서 결과를 재현할 수 있도록
        endCondition: (_, results) {
          return isLuckyDrawComplete(results, winnerCount: winnerCount);
        },
      );

      while (!engine.isGameOver) {
        final result = engine.draw();
        expect(result, isNotNull);
      }

      final results = engine.results;
      final ids = results.map((result) => result.item.id).toSet();

      final winners = results.where((result) => result.item.isWinner).length;

      expect(ids.length, results.length);
      expect(winners, winnerCount);
      expect(engine.draw(), isNull);
    });

    test('제비뽑기는 전부 소진할 때까지 진행할 수 있다', () {
      final items = [
        const DrawItem(id: 'a', text: '사과', isWinner: true),
        const DrawItem(id: 'b', text: '포도', isWinner: false),
        const DrawItem(id: 'c', text: '수박', isWinner: false),
      ];

      final engine = DrawEngine(
        items: items,
        endCondition: (remaining, _) => remaining.isEmpty,
      );

      while (!engine.isGameOver) {
        engine.draw();
      }

      expect(engine.results.length, 3);
      expect(engine.remainingCount, 0);
    });
  });
}
