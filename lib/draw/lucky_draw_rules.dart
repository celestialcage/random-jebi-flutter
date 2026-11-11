import 'package:random_jebi_flutter/draw/draw_item.dart';

List<DrawItem> createLuckyDrawItems({
  required int total,
  required int winners,
}) {
  if (total < 2 || total > 99) {
    throw ArgumentError.value(total, 'total', '참가자는 최소 2명, 최대 99명이어야 합니다.');
  }

  if (winners < 1 || winners >= total) {
    throw ArgumentError.value(
      winners,
      'winners',
      '당첨자 수는 1명 이상, 참가자 수 미만이어야 합니다.',
    );
  }

  return [
    for (int i = 0; i < winners; i++)
      DrawItem(id: 'w-$i', text: '당첨자 ${i + 1}', isWinner: true),

    for (int i = 0; i < total - winners; i++)
      DrawItem(id: 'l-$i', text: '참가자 ${i + 1}', isWinner: false),
  ];
}

bool isLuckyDrawComplete(List<DrawResult> results, {required int winnerCount}) {
  final drawnWinners = results.where((result) => result.item.isWinner).length;

  return drawnWinners >= winnerCount;
}
