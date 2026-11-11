import 'package:flutter/material.dart';
import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:random_jebi_flutter/services/character_image_storage.dart';
import 'package:random_jebi_flutter/widgets/character_portrait.dart';

class ImmersiveRevealView extends StatelessWidget {
  final CustomCharacter character;
  final String answer;
  final CharacterImageStorage storage;

  final VoidCallback onBack;
  final VoidCallback onNewRound;

  const ImmersiveRevealView({
    super.key,
    required this.character,
    required this.answer,
    required this.storage,
    required this.onBack,
    required this.onNewRound,
  });

  static const _background = Color(0xFF111827);

  Widget _buildImage({required bool landscape, required Duration duration}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 기존 이미지 확대 연출 유지
        ClipRect(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.08, end: 1.0),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: CharacterPortrait(
              storage: storage,
              fileName: character.imageFileName,
              alignment: Alignment(character.focusX, character.focusY),
            ),
          ),
        ),

        // 이미지가 끝나는 방향으로만 그라데이션
        Positioned(
          top: landscape ? 0 : null,
          bottom: 0,
          left: landscape ? null : 0,
          right: 0,
          width: landscape ? 56 : null,
          height: landscape ? null : 56,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: landscape
                      ? Alignment.centerLeft
                      : Alignment.bottomCenter,
                  end: landscape
                      ? Alignment.centerRight
                      : Alignment.bottomCenter,
                  colors: [Colors.transparent, _background],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultPanel({
    required bool landscape,
    required Duration duration,
  }) {
    return ColoredBox(
      color: _background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 기존 결과 텍스트 등장 연출 유지
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: duration,
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      '${character.name}: ',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFC7D2FE),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        answer,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: landscape ? 42 : 50,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    onPressed: onBack,
                    child: const Text('다시 선택'),
                  ),
                  FilledButton(
                    onPressed: onNewRound,
                    child: const Text('새 라운드'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 접근성 설정에서 애니메이션 제거를 요청한 경우
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final imageDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 700);

    final textDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 550);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape =
                constraints.maxWidth >= 560 &&
                constraints.maxWidth > constraints.maxHeight;

            final image = _buildImage(
              landscape: landscape,
              duration: imageDuration,
            );

            final panel = _buildResultPanel(
              landscape: landscape,
              duration: textDuration,
            );

            if (landscape) {
              // 가로 화면: 오른쪽에 조작 패널
              final panelWidth = (constraints.maxWidth * 0.34)
                  .clamp(238.0, 360.0)
                  .toDouble();

              return Row(
                key: const ValueKey('reveal-landscape'),
                children: [
                  Expanded(child: image),
                  SizedBox(width: panelWidth, child: panel),
                ],
              );
            }

            // 세로 화면: 아래쪽에 조작 패널
            return Column(
              key: const ValueKey('reveal-portrait'),
              children: [
                Expanded(flex: 7, child: image),
                Expanded(flex: 3, child: panel),
              ],
            );
          },
        ),
      ),
    );
  }
}
