import 'package:flutter/material.dart';
import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:random_jebi_flutter/decision/decision_modes.dart';
import 'package:random_jebi_flutter/services/character_image_storage.dart';
import 'package:random_jebi_flutter/widgets/character_portrait.dart';

class ImmersiveSelectionView extends StatefulWidget {
  final List<CharacterSet> sets;
  final int setIndex;
  final int modeIndex;
  final DecisionRound round;
  final CharacterImageStorage storage;

  final ValueChanged<int> onSetChanged;
  final ValueChanged<int> onModeChanged;
  final ValueChanged<String> onChoose;
  final VoidCallback onNewRound;
  final VoidCallback onManage;
  final VoidCallback onBack;

  const ImmersiveSelectionView({
    super.key,
    required this.sets,
    required this.setIndex,
    required this.modeIndex,
    required this.round,
    required this.storage,
    required this.onSetChanged,
    required this.onModeChanged,
    required this.onChoose,
    required this.onNewRound,
    required this.onManage,
    required this.onBack,
  });

  @override
  State<ImmersiveSelectionView> createState() => _ImmersiveSelectionViewState();
}

class _ImmersiveSelectionViewState extends State<ImmersiveSelectionView> {
  bool _menuExpanded = false;

  void _closeMenu() {
    setState(() => _menuExpanded = false);
  }

  Widget _roundIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xBB111827),
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }

  Widget _settingsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.60,
      ),
      decoration: BoxDecoration(
        color: const Color(0xF01E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('캐릭터 세트', style: TextStyle(color: Colors.white70)),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: widget.setIndex,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                items: [
                  for (int i = 0; i < widget.sets.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        widget.sets[i].title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  widget.onSetChanged(value);
                  _closeMenu();
                },
              ),
            ),
            const SizedBox(height: 10),

            const Text('질문 모드', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < decisionModes.length; i++)
                  ChoiceChip(
                    label: Text(decisionModes[i].label),
                    selected: widget.modeIndex == i,
                    showCheckmark: false,
                    selectedColor: Colors.white,
                    backgroundColor: const Color(0xFF4338CA),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: widget.modeIndex == i
                          ? const Color(0xFF312E81)
                          : Colors.white,
                    ),
                    onSelected: (_) {
                      widget.onModeChanged(i);
                      _closeMenu();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () {
                    widget.onNewRound();
                    _closeMenu();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.shuffle),
                  label: const Text('다른 두 캐릭터'),
                ),
                TextButton.icon(
                  onPressed: () {
                    _closeMenu();
                    widget.onManage();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('세트 관리'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _characterPanel(
    CustomCharacter character, {
    required bool topPortraitPanel,
  }) {
    return Semantics(
      button: true,
      label: '${character.name} 선택',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onChoose(character.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CharacterPortrait(
                storage: widget.storage,
                fileName: character.imageFileName,
                alignment: Alignment(character.focusX, character.focusY),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: topPortraitPanel ? 60 : 18,
                child: Text(
                  character.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 12)],
                  ),
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final landscape =
                  constraints.maxWidth > -560 &&
                  constraints.maxWidth > constraints.maxHeight;

              final first = _characterPanel(
                widget.round.first,
                topPortraitPanel: !landscape,
              );

              final second = _characterPanel(
                widget.round.second,
                topPortraitPanel: false,
              );

              if (landscape) {
                return Row(
                  key: const ValueKey('choices-landscape'),
                  children: [
                    Expanded(child: first),
                    const SizedBox(
                      width: 2,
                      child: ColoredBox(color: Colors.white24),
                    ),
                    Expanded(child: second),
                  ],
                );
              }

              return Column(
                key: const ValueKey('choices-portrait'),
                children: [
                  Expanded(child: first),
                  const SizedBox(
                    height: 2,
                    child: ColoredBox(color: Colors.white24),
                  ),
                  Expanded(child: second),
                ],
              );
            },
          ),

          // 두 캐릭터 사이의 정확한 중앙에 질문 배치
          Align(
            alignment: Alignment.center,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xE6111827),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white70),
                ),
                child: Text(
                  widget.round.mode.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 평소에는 조작 버튼만,
          // 설정을 누르면 메뉴가 펼쳐짐
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _roundIconButton(
                          tooltip: '뒤로가기',
                          icon: Icons.arrow_back,
                          onPressed: widget.onBack,
                        ),
                        _roundIconButton(
                          tooltip: _menuExpanded ? '설정 닫기' : '설정 열기',
                          icon: _menuExpanded ? Icons.close : Icons.tune,
                          onPressed: () {
                            setState(() {
                              _menuExpanded = !_menuExpanded;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  AnimatedSize(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    curve: Curves.easeOutCubic,
                    child: _menuExpanded
                        ? _settingsPanel()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
