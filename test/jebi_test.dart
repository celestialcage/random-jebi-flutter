import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:random_jebi_flutter/draw/draw_engine.dart';
import 'package:random_jebi_flutter/draw/jebi_rules.dart';
import 'package:random_jebi_flutter/models/jebi_models.dart';

void main() {
  final options = [
    const JebiOption(id: 'a', text: '사과', isWinner: true),
    const JebiOption(id: 'b', text: '포도', isWinner: false),
    const JebiOption(id: 'c', text: '수박', isWinner: false),
  ];

  group('JebiOption', () {
    test('copyWith은 원본을 변경하지 않는다.', () {
      final original = options[0];
      final updated = original.copyWith(text: '딸기');

      expect(original.text, '사과');
      expect(updated.text, '딸기');
      expect(updated.id, original.id);
      expect(updated.isWinner, true);
    });
  });

  group('JebiSlot JSON', () {
    test('직렬화 후 역직렬화하면 데이터가 유지된다.', () {
      final original = JebiSlot(
        id: 'slot-1',
        title: '과일 뽑기',
        items: options,
        createdAt: 123456789,
      );

      final encoded = jsonEncode(original.toJson());

      final decoded = JebiSlot.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(decoded.id, original.id);
      expect(decoded.title, original.title);
      expect(decoded.createdAt, original.createdAt);
      expect(decoded.items.length, 3);
      expect(decoded.items[0].text, '사과');
      expect(decoded.items[0].isWinner, true);
      expect(decoded.items[2].text, '수박');
    });
  });

  group('제비뽑기 규칙', () {
    test('빈 선택지는 추첨 대상에서 제외한다.', () {
      final items = JebiRules.createDrawItems([
        ...options,
        const JebiOption(id: 'empty', text: '    ', isWinner: false),
      ]);

      expect(items.length, 3);
      expect(items.map((e) => e.id), isNot(contains('empty')));
    });

    test('유효한 선택지가 2개 미만이면 시작할 수 없다.', () {
      expect(
        () => JebiRules.createDrawItems([
          const JebiOption(id: 'a', text: '사과', isWinner: false),
          const JebiOption(id: 'b', text: '', isWinner: false),
        ]),
        throwsFormatException,
      );
    });

    test('빈 선택지가 포함된 세트는 저장할 수 없다.', () {
      expect(
        () => JebiRules.validateSlot(
          title: '테스트',
          options: [
            ...options,
            const JebiOption(id: 'empty', text: '', isWinner: false),
          ],
        ),
        throwsFormatException,
      );
    });

    test('모든 제비를 뽑으면 게임이 종료된다.', () {
      final engine = DrawEngine(
        items: JebiRules.createDrawItems(options),
        random: Random(42),
        endCondition: JebiRules.isComplete,
      );

      final drawnIds = <String>[];

      while (!engine.isGameOver) {
        final result = engine.draw();

        expect(result, isNotNull);
        drawnIds.add(result!.item.id);
      }

      expect(engine.results.length, 3);
      expect(drawnIds.length, 3);
      expect(engine.remainingCount, 0);
      expect(engine.isGameOver, true);
      expect(engine.draw(), isNull);
    });

    test('당첨 선택지가 없어도 전부 추첨할 수 있다.', () {
      final noWinnerOptions = [
        const JebiOption(id: 'a', text: 'A', isWinner: false),
        const JebiOption(id: 'b', text: 'B', isWinner: false),
      ];

      final engine = DrawEngine(
        items: JebiRules.createDrawItems(noWinnerOptions),
        endCondition: JebiRules.isComplete,
      );

      while (!engine.isGameOver) {
        engine.draw();
      }

      expect(engine.results.length, 2);
      expect(engine.results.where((r) => r.item.isWinner), isEmpty);
    });
  });
}
