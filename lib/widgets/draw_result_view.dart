import 'package:flutter/material.dart';
import 'package:random_jebi_flutter/draw/draw_item.dart';

class DrawResultView extends StatelessWidget {
  final List<DrawResult> results;
  final VoidCallback onReset;

  const DrawResultView({
    super.key,
    required this.results,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final winners = results.where((result) => result.item.isWinner).toList();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '오늘의 추첨 기록',
                style: TextStyle(color: Color(0xFF4F46E5)),
              ),
              const SizedBox(height: 8),
              const Text(
                '결과 모아보기',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✦ 추첨 완료!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('총 ${results.length}장 공개 · 당첨 ${winners.length}개'),
                      const Divider(height: 32),

                      const Text(
                        '당첨자',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (winners.isEmpty) const Text('당첨으로 표시된 항목이 없습니다.'),

                      for (final result in winners)
                        ListTile(
                          leading: const Icon(
                            Icons.star,
                            color: Color(0xFF6366F1),
                          ),
                          title: Text(result.item.text),
                          subtitle: Text('${result.round}번째 추첨에서'),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                '뽑은 순서',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              for (final result in results)
                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${result.round}')),
                    title: Text(result.item.text),
                    trailing: Text(result.item.isWinner ? '★ 당첨' : '일반'),
                  ),
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
              onPressed: onReset,
              child: const Text('설정으로 돌아가 다시 시작'),
            ),
          ),
        ),
      ],
    );
  }
}
