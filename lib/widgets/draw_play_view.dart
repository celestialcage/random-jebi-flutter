import 'package:flutter/material.dart';
import 'package:random_jebi_flutter/draw/draw_engine.dart';
import 'package:random_jebi_flutter/draw/draw_item.dart';

class DrawPlayView extends StatefulWidget {
  final DrawEngine engine;
  final ValueChanged<List<DrawResult>> onFinish;

  const DrawPlayView({super.key, required this.engine, required this.onFinish});

  @override
  State<DrawPlayView> createState() => _DrawPlayViewState();
}

class _DrawPlayViewState extends State<DrawPlayView> {
  DrawResult? _revealedResult;

  void _drawOnce() {
    // 결과를 확인하기 전에는 중복 추첨 불가
    if (_revealedResult != null) return;

    final result = widget.engine.draw();

    if (result == null) return;

    setState(() {
      _revealedResult = result;
    });
  }

  void _continueGame() {
    if (widget.engine.isGameOver) {
      widget.onFinish(widget.engine.results);
      return;
    }

    setState(() {
      _revealedResult = null;
    });
  }

  Widget _buildDrawCard() {
    final result = _revealedResult;

    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 콘텐츠 크기만큼만 차지
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.engine.drawnCount + (result == null ? 1 : 0)}번째 제비',
              style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            Text(
              result == null
                  ? '?'
                  : result.item.isWinner
                  ? '★'
                  : '✦',
              style: const TextStyle(fontSize: 64, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 100,
              child: SingleChildScrollView(
                child: Text(
                  result?.item.text ?? '두구두구...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (result != null) ...[
              const SizedBox(height: 12),
              Text(
                result.item.isWinner ? '🎉 당첨입니다!' : '일반 선택지가 나왔어요',
                style: const TextStyle(
                  color: Color(0xFF4338CA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '눌러보자!',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '뽑기 게임',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('남은 제비: ${engine.remainingCount}개'),
                    Text('${engine.drawnCount} / ${engine.totalCount}장 공개'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildDrawCard(),

              const SizedBox(height: 24),
              Text(
                engine.isGameOver
                    ? '추첨이 끝났습니다. 전체 결과를 확인해보세요.'
                    : _revealedResult != null
                    ? '확인 결과는 마지막에 모아서 볼 수 있습니다.'
                    : '이미 뽑은 제비는 다시 나오지 않습니다.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _revealedResult == null ? _drawOnce : _continueGame,
              child: Text(
                _revealedResult == null
                    ? '한 장 뽑기'
                    : engine.isGameOver
                    ? '결과 보러 가기'
                    : '다음 제비 뽑기',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
