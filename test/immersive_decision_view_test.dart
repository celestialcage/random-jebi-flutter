import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_jebi_flutter/decision/decision_engine.dart';
import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:random_jebi_flutter/decision/decision_modes.dart';
import 'package:random_jebi_flutter/services/character_image_storage.dart';
import 'package:random_jebi_flutter/widgets/immersive_reveal_view.dart';
import 'package:random_jebi_flutter/widgets/immersive_selection_view.dart';

void main() {
  final set = CharacterSet(
    id: 'zelda',
    title: '젤다의 전설',
    characters: const [
      CustomCharacter(id: 'link', name: '링크'),
      CustomCharacter(id: 'zelda', name: '젤다'),
    ],
  );

  final round = DecisionEngine(random: Random(42))
      .createRound(set: set, mode: decisionModes[0]);

  Future<void> pumpSelection(
    WidgetTester tester, {
    required Size screenSize,
    required ValueChanged<String> onChoose,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = screenSize;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ImmersiveSelectionView(
          sets: [set],
          setIndex: 0,
          modeIndex: 0,
          round: round,
          storage: CharacterImageStorage(),
          onSetChanged: (_) {},
          onModeChanged: (_) {},
          onChoose: onChoose,
          onNewRound: () {},
          onManage: () {},
          onBack: () {},
        ),
      ),
    );
  }

  testWidgets('세로 화면에서는 캐릭터가 위아래로 배치된다', (tester) async {
    String? selectedId;

    await pumpSelection(
      tester,
      screenSize: const Size(400, 800),
      onChoose: (id) => selectedId = id,
    );

    expect(find.byKey(const ValueKey('choices-portrait')), findsOneWidget);

    await tester.tap(find.text('링크'));

    expect(selectedId, 'link');
  });

  testWidgets('가로 화면에서는 캐릭터가 좌우로 배치된다', (tester) async {
    await pumpSelection(
      tester,
      screenSize: const Size(800, 400),
      onChoose: (_) {},
    );

    expect(find.byKey(const ValueKey('choices-landscape')), findsOneWidget);
  });

  testWidgets('결과 화면에서 답변과 다시 선택 버튼이 표시된다', (tester) async {
    var backCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ImmersiveRevealView(
          character: set.characters.first,
          answer: '가',
          storage: CharacterImageStorage(),
          onBack: () => backCalled = true,
          onNewRound: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('링크: '), findsOneWidget);
    expect(find.text('가'), findsOneWidget);

    await tester.tap(find.text('다시 선택'));

    expect(backCalled, isTrue);
  });

  testWidgets('선택 화면에서 메뉴를 열고 닫을 수 있다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ImmersiveSelectionView(
          sets: [set],
          setIndex: 0,
          modeIndex: 0,
          round: round,
          storage: CharacterImageStorage(),
          onSetChanged: (_) {},
          onModeChanged: (_) {},
          onChoose: (_) {},
          onNewRound: () {},
          onManage: () {},
          onBack: () {},
        ),
      ),
    );

    // 메뉴가 닫혀 있어도 질문은 표시된다
    expect(find.text('할까?'), findsOneWidget);
    expect(find.text('캐릭터 세트'), findsNothing);

    await tester.tap(find.byTooltip('설정 열기'));
    await tester.pumpAndSettle();

    expect(find.text('캐릭터 세트'), findsOneWidget);
    expect(find.text('다른 두 캐릭터'), findsOneWidget);

    await tester.tap(find.byTooltip('설정 닫기'));
    await tester.pumpAndSettle();

    expect(find.text('캐릭터 세트'), findsNothing);
    expect(find.text('할까?'), findsOneWidget);
  });

  testWidgets('가로 결과 화면에는 우측 패널 레이아웃이 있다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 400);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ImmersiveRevealView(
          character: set.characters.first,
          answer: '해',
          storage: CharacterImageStorage(),
          onBack: () {},
          onNewRound: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reveal-landscape')), findsOneWidget);
    expect(find.text('링크: '), findsOneWidget);
    expect(find.text('해'), findsOneWidget);
  });
}
