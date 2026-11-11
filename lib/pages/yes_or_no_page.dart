import 'dart:math';

import 'package:flutter/material.dart';

class CharacterPreset {
  final String label;
  final String firstName;
  final String firstEmoji;
  final String secondName;
  final String secondEmoji;

  const CharacterPreset({
    required this.label,
    required this.firstName,
    required this.firstEmoji,
    required this.secondName,
    required this.secondEmoji,
  });
}

const presets = <CharacterPreset>[
  CharacterPreset(
    label: '천사 / 악마',
    firstName: '천사',
    firstEmoji: '😇',
    secondName: '악마',
    secondEmoji: '😈',
  ),
  CharacterPreset(
    label: '엄마 / 아빠',
    firstName: '엄마',
    firstEmoji: '👩',
    secondName: '아빠',
    secondEmoji: '👨',
  ),
  CharacterPreset(
    label: '할머니 / 할아버지',
    firstName: '할머니',
    firstEmoji: '👵',
    secondName: '할아버지',
    secondEmoji: '👴',
  ),
  CharacterPreset(
    label: '여동생 / 남동생',
    firstName: '여동생',
    firstEmoji: '👧',
    secondName: '남동생',
    secondEmoji: '👦',
  ),
];

class YesOrNoPage extends StatefulWidget {
  const YesOrNoPage({super.key});

  @override
  State<YesOrNoPage> createState() => _YesOrNoPageState();
}

class _YesOrNoPageState extends State<YesOrNoPage> {
  final Random _random = Random();

  late int _presetIndex;
  late bool _firstGetsPositive;

  bool _isBuying = false;

  @override
  void initState() {
    super.initState();

    _presetIndex = _random.nextInt(presets.length);
    _assignResults();
  }

  void _assignResults() {
    _firstGetsPositive = _random.nextBool();
  }

  void _changeMode(bool isBuying) {
    if (_isBuying == isBuying) return;

    setState(() {
      _isBuying = isBuying;
      _assignResults();
    });
  }

  void _changePreset(int index) {
    if (_presetIndex == index) return;

    setState(() {
      _presetIndex = index;
      _assignResults();
    });
  }

  void _randomPreset() {
    final otherIndexes = List.generate(presets.length, (index) => index)
      ..remove(_presetIndex);

    final next = otherIndexes[_random.nextInt(otherIndexes.length)];

    _changePreset(next);
  }

  String _resultFor(int cardIndex) {
    final positive = cardIndex == 0 ? _firstGetsPositive : !_firstGetsPositive;

    if (_isBuying) {
      return positive ? '사' : '사지마';
    }

    return positive ? '해' : '하지마';
  }

  void _showResult(int cardIndex) {
    final preset = presets[_presetIndex];

    final name = cardIndex == 0 ? preset.firstName : preset.secondName;

    final emoji = cardIndex == 0 ? preset.firstEmoji : preset.secondEmoji;

    final result = _resultFor(cardIndex);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('$name의 의견'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              result,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4338CA),
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('닫기'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _characterCard(int index) {
    final preset = presets[_presetIndex];

    final name = index == 0 ? preset.firstName : preset.secondName;

    final emoji = index == 0 ? preset.firstEmoji : preset.secondEmoji;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: () => _showResult(index),
        child: SizedBox(
          height: 164,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                '$name 말 듣기',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('양자택일'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: '메인 화면',
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('OX 결정', style: TextStyle(color: Color(0xFF4F46E5))),
            const SizedBox(height: 8),
            const Text(
              '누구 말을 들을까?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('할지말지 살지말지 고민될 때'),
            const SizedBox(height: 28),

            SegmentedButton(
              segments: const [
                ButtonSegment<bool>(value: false, label: Text('할까?')),
                ButtonSegment<bool>(value: true, label: Text('살까?')),
              ],
              selected: {_isBuying},
              showSelectedIcon: false,
              onSelectionChanged: (selected) {
                _changeMode(selected.first);
              },
            ),

            const SizedBox(height: 28),
            const Text(
              '조합 고르기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: _presetIndex,
                    isExpanded: true,
                    items: [
                      for (int i = 0; i < presets.length; i++)
                        DropdownMenuItem<int>(
                          value: i,
                          child: Text(presets[i].label),
                        ),
                    ],
                    onChanged: (index) {
                      if (index != null) {
                        _changePreset(index);
                      }
                    },
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '다른 조합 무작위 선택',
                  onPressed: _randomPreset,
                  icon: const Icon(Icons.shuffle),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Text(
              '다른 조합을 고르고 새로운 의견 듣기',
              style: TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),

            _characterCard(0),
            const SizedBox(height: 14),
            _characterCard(1),

            const SizedBox(height: 24),
            const Text('✨', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
