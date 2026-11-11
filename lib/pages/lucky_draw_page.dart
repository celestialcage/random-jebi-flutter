import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:random_jebi_flutter/draw/draw_engine.dart';
import 'package:random_jebi_flutter/draw/draw_item.dart';
import 'package:random_jebi_flutter/draw/lucky_draw_rules.dart';
import 'package:random_jebi_flutter/widgets/draw_play_view.dart';
import 'package:random_jebi_flutter/widgets/draw_result_view.dart';

enum GameStep { setup, play, result }

class LuckyDrawPage extends StatefulWidget {
  const LuckyDrawPage({super.key});

  @override
  State<LuckyDrawPage> createState() => _LuckyDrawPageState();
}

class _LuckyDrawPageState extends State<LuckyDrawPage> {
  final _totalController = TextEditingController(text: '2');
  final _winnersController = TextEditingController(text: '1');

  GameStep _step = GameStep.setup;

  DrawEngine? _engine;
  List<DrawResult> _finalResults = [];

  @override
  void dispose() {
    _totalController.dispose();
    _winnersController.dispose();
    super.dispose();
  }

  // +/- 버튼으로 참가 인원 변경
  void _adjustTotal(int delta) {
    final current = int.tryParse(_totalController.text) ?? 2;
    final next = (current + delta).clamp(2, 99).toInt();

    _totalController.text = '$next';

    final winners = int.tryParse(_winnersController.text);

    if (winners != null && winners >= next) {
      _winnersController.text = '${next - 1}';
    }
  }

  // +/- 버튼으로 당첨자 수 변경
  void _adjustWinners(int delta) {
    final total = int.tryParse(_totalController.text) ?? 2;
    final maxWinners = (total - 1).clamp(1, 98).toInt();

    final current = int.tryParse(_winnersController.text) ?? 1;
    final next = (current + delta).clamp(1, maxWinners).toInt();

    _winnersController.text = '$next';
  }

  void _startGame() {
    final total = int.tryParse(_totalController.text);
    final winners = int.tryParse(_winnersController.text);

    if (total == null ||
        winners == null ||
        total < 2 ||
        total > 99 ||
        winners < 1 ||
        winners >= total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참가자는 2~99명, 당첨자는 1명 이상 참가자 수 미만이어야 해요.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final items = createLuckyDrawItems(total: total, winners: winners);

    final engine = DrawEngine(
      items: items,
      endCondition: (_, results) {
        return isLuckyDrawComplete(results, winnerCount: winners);
      },
    );

    setState(() {
      _engine = engine;
      _finalResults = [];
      _step = GameStep.play;
    });
  }

  void _finishGame(List<DrawResult> results) {
    setState(() {
      _finalResults = results;
      _step = GameStep.result;
    });
  }

  // 앱바와 Android 시스템 뒤로가기에 공통 대응
  Future<void> _handleBack() async {
    if (_step == GameStep.setup) {
      Navigator.of(context).pop();
      return;
    }

    if (_step == GameStep.result) {
      setState(() {
        _step = GameStep.setup;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('추첨을 종료하시겠습니까?'),
        content: const Text(
          '진행 중인 추첨 기록은 초기화되지만\n'
          '참가 인원과 당첨자 수 설정은 유지됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('계속 진행'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('설정으로 돌아가기'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _step = GameStep.setup;
    });
  }

  // 참가자/당첨자 공용 숫자 입력 Widget
  Widget _numberInput({
    required String title,
    required String description,
    required TextEditingController controller,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: IconButton.filledTonal(
                    tooltip: '$title 줄이기',
                    onPressed: onDecrease,
                    icon: const Icon(Icons.remove),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '0',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: IconButton.filledTonal(
                    tooltip: '$title 늘리기',
                    onPressed: onIncrease,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetup() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '럭키드로우',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '당첨자 뽑기!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('참가 인원과 당첨자 수를 입력하세요.'),
              const SizedBox(height: 28),

              _numberInput(
                title: '총 참가 인원',
                description: '2명부터 99명까지 참여 가능합니다.',
                controller: _totalController,
                onDecrease: () => _adjustTotal(-1),
                onIncrease: () => _adjustTotal(1),
              ),

              const SizedBox(height: 16),

              _numberInput(
                title: '당첨자 수',
                description: '당첨자 수는 최소 1명, 최대 참가 인원을 넘을 수 없습니다.',
                controller: _winnersController,
                onDecrease: () => _adjustWinners(-1),
                onIncrease: () => _adjustWinners(1),
              ),
              const SizedBox(height: 20),

              const Text(
                '숫자를 직접 입력하거나 +/- 버튼으로 조절할 수 있습니다.',
                style: TextStyle(color: Colors.blueGrey),
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
              onPressed: _startGame,
              child: const Text('게임 시작하기'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _step == GameStep.setup,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('럭키드로우'),
          leading: BackButton(
            onPressed: () {
              _handleBack();
            },
          ),
        ),
        body: SafeArea(
          child: switch (_step) {
            GameStep.setup => _buildSetup(),

            GameStep.play => DrawPlayView(
              engine: _engine!,
              onFinish: _finishGame,
            ),

            GameStep.result => DrawResultView(
              results: _finalResults,
              onReset: () {
                setState(() {
                  _step = GameStep.setup;
                });
              },
            ),
          },
        ),
      ),
    );
  }
}
