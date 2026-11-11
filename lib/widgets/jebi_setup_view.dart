import 'package:flutter/material.dart';
import 'package:random_jebi_flutter/draw/jebi_rules.dart';
import 'package:random_jebi_flutter/models/jebi_models.dart';

class JebiSetupView extends StatelessWidget {
  final List<JebiOption> options;
  final List<JebiSlot> slots;
  final String? editingSlotId;
  final TextEditingController titleController;

  final bool isLoading;
  final bool isBusy;
  final bool storageReady;
  final String? storageError;

  final VoidCallback onRetryLoad;
  final VoidCallback onNewList;
  final VoidCallback onAddOption;
  final ValueChanged<String> onRemoveOption;
  final void Function(String id, String text) onTextChanged;
  final ValueChanged<String> onToggleWinner;

  final ValueChanged<JebiSlot> onLoadSlot;
  final ValueChanged<String> onDeleteSlot;
  final VoidCallback onSaveSlot;
  final VoidCallback onStart;

  const JebiSetupView({
    super.key,
    required this.options,
    required this.slots,
    required this.editingSlotId,
    required this.titleController,
    required this.isLoading,
    required this.isBusy,
    required this.storageReady,
    required this.storageError,
    required this.onRetryLoad,
    required this.onNewList,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onTextChanged,
    required this.onToggleWinner,
    required this.onLoadSlot,
    required this.onDeleteSlot,
    required this.onSaveSlot,
    required this.onStart,
  });

  Widget _buildSavedSlots() {
    if (isLoading) {
      return const LinearProgressIndicator();
    }

    if (storageError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(storageError!),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onRetryLoad,
                child: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
      );
    }

    if (slots.isEmpty) {
      return const Text(
        '아직 저장된 세트가 없습니다.',
        style: TextStyle(color: Colors.blueGrey),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final slot = slots[index];
          final selected = editingSlotId == slot.id;

          return SizedBox(
            width: 220,
            child: Card(
              color: selected ? const Color(0xFFEEF2FF) : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: isBusy ? null : () => onLoadSlot(slot),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selected
                                  ? '편집 중 · ${slot.items.length}개'
                                  : '선택지 ${slot.items.length}개',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '${slot.title} 삭제',
                    onPressed: isBusy ? null : () => onDeleteSlot(slot.id),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSlotFull = slots.length >= JebiRules.maxSlots;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '제비 넣기',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '무엇을 뽑아볼까?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('선택지를 적고, 당첨으로 표시할 항목을 고를 수 있습니다.'),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '저장된 세트',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('${slots.length}/${JebiRules.maxSlots}'),
                ],
              ),
              const SizedBox(height: 12),
              _buildSavedSlots(),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: !storageReady || isBusy || isSlotFull
                      ? null
                      : onNewList,
                  icon: const Icon(Icons.add),
                  label: const Text('새 리스트'),
                ),
              ),

              if (isSlotFull)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '저장 공간이 가득 찼습니다.\n'
                      '새 리스트를 만들려면 기존 슬롯을 삭제해야 합니다.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Color(0xFFB45309), fontSize: 13),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '선택지',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('${options.length}/${JebiRules.maxOptions}'),
                ],
              ),
              const SizedBox(height: 12),

              for (int i = 0; i < options.length; i++)
                Padding(
                  key: ValueKey(options[i].id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _JebiOptionRow(
                    index: i,
                    option: options[i],
                    enabled: !isBusy,
                    onTextChanged: (text) {
                      onTextChanged(options[i].id, text);
                    },
                    onToggleWinner: () {
                      onToggleWinner(options[i].id);
                    },
                    onRemove: () {
                      onRemoveOption(options[i].id);
                    },
                  ),
                ),

              OutlinedButton.icon(
                onPressed: isBusy || options.length >= JebiRules.maxOptions
                    ? null
                    : onAddOption,
                icon: const Icon(Icons.add),
                label: const Text('선택지 추가'),
              ),

              const SizedBox(height: 28),

              Card(
                color: const Color(0xFFF5F3FF),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editingSlotId == null ? '다음에도 이 조합으로' : '저장된 세트 수정',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        enabled: !isBusy,
                        decoration: const InputDecoration(
                          labelText: '세트 이름',
                          hintText: '예: 점심 메뉴, 주말 내기',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: !storageReady || isBusy
                              ? null
                              : onSaveSlot,
                          child: Text(
                            editingSlotId == null ? '세트 저장하기' : '세트 수정 저장',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
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
              onPressed: isBusy ? null : onStart,
              child: const Text('이 리스트로 뽑기 시작하기'),
            ),
          ),
        ),
      ],
    );
  }
}

class _JebiOptionRow extends StatefulWidget {
  final int index;
  final JebiOption option;
  final bool enabled;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onToggleWinner;
  final VoidCallback onRemove;

  const _JebiOptionRow({
    // super.key,
    required this.index,
    required this.option,
    required this.enabled,
    required this.onTextChanged,
    required this.onToggleWinner,
    required this.onRemove,
  });

  @override
  State<_JebiOptionRow> createState() => __JebiOptionRowState();
}

class __JebiOptionRowState extends State<_JebiOptionRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.option.text);
  }

  @override
  void didUpdateWidget(covariant _JebiOptionRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 저장 슬롯을 불러오는 등 외부 데이터가 바뀐 경우
    if (_controller.text != widget.option.text) {
      _controller.value = TextEditingValue(
        text: widget.option.text,
        selection: TextSelection.collapsed(offset: widget.option.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '선택지 ${widget.index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              enabled: widget.enabled,
              onChanged: widget.onTextChanged,
              decoration: const InputDecoration(
                hintText: '예: 커피 사기',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilterChip(
                  label: Text(widget.option.isWinner ? '★ 당첨' : '☆ 일반'),
                  selected: widget.option.isWinner,
                  onSelected: widget.enabled
                      ? (_) => widget.onToggleWinner()
                      : null,
                ),
                const Spacer(),
                IconButton(
                  tooltip: '선택지 ${widget.index + 1} 삭제',
                  onPressed: widget.enabled ? widget.onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
