import 'package:random_jebi_flutter/draw/draw_item.dart';
import 'package:random_jebi_flutter/models/jebi_models.dart';

class JebiRules {
  static const int minOptions = 2;
  static const int maxOptions = 30;
  static const int maxSlots = 10;

  static List<DrawItem> createDrawItems(List<JebiOption> options) {
    final validOptions = options
        .where((option) => option.text.trim().isNotEmpty)
        .toList();

    if (validOptions.length < minOptions) {
      throw const FormatException('내용이 입력된 선택지가 최소 $minOptions개 필요합니다.');
    }

    if (validOptions.length > maxOptions) {
      throw const FormatException('선택지는 최대 $maxOptions개까지 가능합니다.');
    }

    return [
      for (final option in validOptions)
        DrawItem(
          id: option.id,
          text: option.text.trim(),
          isWinner: option.isWinner,
        ),
    ];
  }

  // 슬롯에 저장할 수 있는 데이터인지 검증
  static void validateSlot({
    required String title,
    required List<JebiOption> options,
  }) {
    if (title.trim().isEmpty) {
      throw const FormatException('저장할 세트 이름을 입력해주세요.');
    }

    if (options.length < minOptions || options.length > maxOptions) {
      throw const FormatException('선택지는 $minOptions개에서 $maxOptions개까지 가능합니다.');
    }

    if (options.any((option) => option.text.trim().isEmpty)) {
      throw const FormatException('빈 선택지가 있습니다. 내용을 채워주세요.');
    }
  }

  // 제비뽑기는 모든 제비를 소진해야 종료
  static bool isComplete(List<DrawItem> remaining, List<DrawResult> results) {
    return remaining.isEmpty;
  }
}
