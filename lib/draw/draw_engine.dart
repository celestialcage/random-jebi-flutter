import 'dart:math';

import 'package:random_jebi_flutter/draw/draw_item.dart';

// 외부에서 게임 종료 규칙을 전달받기 위한 함수 타입
typedef GameEndCondition = bool Function(
  List<DrawItem> remaining,
  List<DrawResult> results,
);

class DrawEngine {
  final List<DrawItem> _remaining;
  final List<DrawResult> _results = [];

  final GameEndCondition _endCondition;
  final int totalCount;

  DrawEngine({
    required List<DrawItem> items,
    required this._endCondition,
    Random? random,
  }) : _remaining = List<DrawItem>.of(items),
       totalCount = items.length {
    if (items.isEmpty) {
      throw ArgumentError('추첨할 항목이 비어 있습니다.');
    }

    _remaining.shuffle(random ?? Random());
  }

  // 외부에서는 내부 리스트를 직접 수정할 수 없도록 함
  List<DrawResult> get results => List<DrawResult>.unmodifiable(_results);

  int get remainingCount => _remaining.length;

  int get drawnCount => _results.length;

  bool get isGameOver {
    if (_remaining.isEmpty) return true;

    return _endCondition(List<DrawItem>.unmodifiable(_remaining), results);
  }

  // 제비 한 장 뽑기
  DrawResult? draw() {
    if (isGameOver) return null;

    final nextItem = _remaining.removeLast();

    final result = DrawResult(round: _results.length + 1, item: nextItem);

    _results.add(result);

    return result;
  }
}
