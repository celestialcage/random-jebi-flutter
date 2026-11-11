import 'package:flutter/material.dart';
import 'package:random_jebi_flutter/pages/custom_decision_page.dart';
import 'package:random_jebi_flutter/pages/jebi_page.dart';
import 'package:random_jebi_flutter/pages/lucky_draw_page.dart';
import 'package:random_jebi_flutter/pages/yes_or_no_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            Text(
              '랜덤 뽑기 게임',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '오늘은 무엇을\n뽑아볼까?',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text('고민하지말고 GO'),
            const SizedBox(height: 32),

            _modeTile(
              context,
              emoji: '⚖️',
              title: '양자택일',
              description: 'OX - 누구 말을 들을까?',
              destination: const YesOrNoPage(),
            ),
            const SizedBox(height: 12),

            _modeTile(
              context,
              emoji: '🎯',
              title: '럭키드로우',
              description: '참가 인원을 정하고 당첨자 뽑기',
              destination: const LuckyDrawPage(),
            ),
            const SizedBox(height: 12),

            _modeTile(
              context,
              emoji: '🎟️',
              title: '제비뽑기',
              description: '선택지를 직접 넣은 제비뽑기',
              destination: const JebiPage(),
            ),
            const SizedBox(height: 12),

            _modeTile(
              context,
              emoji: '🪄',
              title: '커스텀 모드',
              description: '직접 설정한 캐릭터로 결정하기',
              destination: const CustomDecisionPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeTile(
    BuildContext context, {
    required String emoji,
    required String title,
    required String description,
    Widget? destination,
  }) {
    final enabled = destination != null;

    return Card(
      margin: EdgeInsets.zero,
      color: enabled ? Colors.white : Colors.grey.shade100,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: destination == null
            ? null
            : () {
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => destination));
              },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      enabled ? description : '$description · 준비 중',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
