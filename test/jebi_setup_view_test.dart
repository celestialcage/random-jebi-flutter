import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_jebi_flutter/models/jebi_models.dart';
import 'package:random_jebi_flutter/widgets/jebi_setup_view.dart';

const testOptions = [
  JebiOption(id: 'a', text: '사과', isWinner: true),
  JebiOption(id: 'b', text: '포도', isWinner: false),
];

Widget createTestApp({
  required int slotCount,
  required TextEditingController controller,
  required VoidCallback onNewList,
}) {
  final slots = List.generate(
    slotCount,
    (i) => JebiSlot(
      id: 'slot-$i',
      title: '저장 슬롯 $i',
      items: testOptions,
      createdAt: i,
    ),
  );

  return MaterialApp(
    home: Scaffold(
      body: JebiSetupView(
        options: testOptions,
        slots: slots,
        editingSlotId: null,
        titleController: controller,
        isLoading: false,
        isBusy: false,
        storageReady: true,
        storageError: null,
        onRetryLoad: () {},
        onNewList: onNewList,
        onAddOption: () {},
        onRemoveOption: (_) {},
        onTextChanged: (_, _) {},
        onToggleWinner: (_) {},
        onLoadSlot: (_) {},
        onDeleteSlot: (_) {},
        onSaveSlot: () {},
        onStart: () {},
      ),
    ),
  );
}

void main() {
  testWidgets('슬롯이 10개면 새 리스트 버튼이 비활성화된다', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    var called = false;

    await tester.pumpWidget(
      createTestApp(
        slotCount: 10,
        controller: controller,
        onNewList: () => called = true,
      ),
    );

    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '새 리스트'),
    );

    expect(button.onPressed, isNull);
    expect(called, isFalse);
    expect(find.textContaining('저장 공간이 가득 찼습니다'), findsOneWidget);
  });

  testWidgets('슬롯이 9개면 새 리스트를 생성할 수 있다', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    var called = false;

    await tester.pumpWidget(
      createTestApp(
        slotCount: 9,
        controller: controller,
        onNewList: () => called = true,
      ),
    );

    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '새 리스트'),
    );

    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('새 리스트'));
    await tester.pump();

    expect(called, isTrue);
  });
}
