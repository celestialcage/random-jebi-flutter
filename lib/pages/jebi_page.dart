import 'package:flutter/material.dart';
import 'package:random_jebi_flutter/draw/draw_engine.dart';
import 'package:random_jebi_flutter/draw/draw_item.dart';
import 'package:random_jebi_flutter/draw/jebi_rules.dart';
import 'package:random_jebi_flutter/models/jebi_models.dart';
import 'package:random_jebi_flutter/repositories/jebi_slot_repository.dart';
import 'package:random_jebi_flutter/widgets/draw_play_view.dart';
import 'package:random_jebi_flutter/widgets/draw_result_view.dart';
import 'package:random_jebi_flutter/widgets/jebi_setup_view.dart';

enum JebiStep { setup, play, result }

class JebiPage extends StatefulWidget {
  const JebiPage({super.key});

  @override
  State<JebiPage> createState() => _JebiPageState();
}

class _JebiPageState extends State<JebiPage> {
  static int _idCounter = 0;

  final JebiSlotRepository _repository = JebiSlotRepository();
  final TextEditingController _titleController = TextEditingController();

  late List<JebiOption> _options;
  List<JebiSlot> _slots = [];

  String? _editingSlotId;

  bool _loading = true;
  bool _storageReady = false;
  bool _busy = false;
  String? _storageError;

  JebiStep _step = JebiStep.setup;
  DrawEngine? _engine;
  List<DrawResult> _finalResults = [];

  String _newId(String prefix) {
    final time = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$time-${_idCounter++}';
  }

  JebiOption _blankOption() {
    return JebiOption(id: _newId('opt'), text: '', isWinner: false);
  }

  List<JebiOption> _blankOptions() {
    return [_blankOption(), _blankOption()];
  }

  @override
  void initState() {
    super.initState();
    _options = _blankOptions();
    _loadSlots();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // 저장소에서 슬롯 불러오기
  Future<void> _loadSlots() async {
    setState(() {
      _loading = true;
      _storageReady = false;
      _storageError = null;
    });

    try {
      final loaded = await _repository.load();

      if (!mounted) return;

      setState(() {
        _slots = loaded;
        _storageReady = true;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[JEBI LOAD ERROR] $error');
      debugPrint('$stackTrace');
      if (!mounted) return;

      setState(() {
        _loading = false;
        _storageReady = false;
        _storageError =
            '저장된 슬롯을 불러오지 못했습니다. '
            '저장소 상태를 확인한 뒤 다시 시도해 주십시오.';
      });
    }
  }

  // 선택지 한 줄 추가
  void _addOption() {
    if (_options.length >= JebiRules.maxOptions) return;

    setState(() {
      _options = [..._options, _blankOption()];
    });
  }

  // 선택지 한 줄 삭제
  void _removeOption(String id) {
    if (_options.length <= JebiRules.minOptions) {
      _showMessage('선택지는 최소 ${JebiRules.minOptions}개 이상 유지해야 합니다.');
      return;
    }

    setState(() {
      _options = _options.where((option) => option.id != id).toList();
    });
  }

  // 선택지 텍스트 변경
  void _changeText(String id, String text) {
    setState(() {
      _options = [
        for (final option in _options)
          if (option.id == id) option.copyWith(text: text) else option,
      ];
    });
  }

  // 당첨 여부 변경
  void _toggleWinner(String id) {
    setState(() {
      _options = [
        for (final option in _options)
          if (option.id == id)
            option.copyWith(isWinner: !option.isWinner)
          else
            option,
      ];
    });
  }

  // 빈 리스트로 초기화하는 공통 메서드
  void _clearEditor() {
    FocusScope.of(context).unfocus();

    setState(() {
      _options = _blankOptions();
      _editingSlotId = null;
      _titleController.clear();
    });
  }

  Future<void> _newList() async {
    if (_busy || !_storageReady) return;

    if (_slots.length >= JebiRules.maxSlots) {
      _showMessage(
        '슬롯 저장소가 가득 찼습니다. 새 리스트를 생성하려면 '
        '기존 슬롯을 삭제해야 합니다.',
      );
      return;
    }

    final hasContent = _options.any((option) => option.text.trim().isNotEmpty);

    final needsConfirmation =
        hasContent ||
        _editingSlotId != null ||
        _titleController.text.trim().isNotEmpty;

    if (needsConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('새 리스트를 만드시겠습니까?'),
          content: const Text('현재 작성 중인 내용이 초기화됩니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('새로 작성'),
            ),
          ],
        ),
      );

      if (!mounted || confirmed != true) return;
    }

    _clearEditor();
  }

  // 저장 슬롯을 편집기에 불러오기
  void _loadSlot(JebiSlot slot) {
    FocusScope.of(context).unfocus();

    setState(() {
      _options = List<JebiOption>.of(slot.items);
      _titleController.text = slot.title;
      _editingSlotId = slot.id;
    });
  }

  // 신규 슬롯 저장 / 기존 슬롯 수정
  Future<void> _saveSlot() async {
    if (!_storageReady || _busy) return;

    final title = _titleController.text.trim();

    try {
      JebiRules.validateSlot(title: title, options: _options);
    } on FormatException catch (error) {
      _showMessage(error.message);
      return;
    }

    final editingIndex = _editingSlotId == null
        ? -1
        : _slots.indexWhere((slot) => slot.id == _editingSlotId);

    if (_editingSlotId != null && editingIndex < 0) {
      _showMessage('수정할 슬롯을 찾을 수 없습니다.');
      return;
    }

    if (editingIndex < 0 && _slots.length >= JebiRules.maxSlots) {
      _showMessage('슬롯은 최대 ${JebiRules.maxSlots}개까지만 저장할 수 있습니다.');
      return;
    }

    final slot = JebiSlot(
      id: editingIndex >= 0 ? _slots[editingIndex].id : _newId('slot'),
      title: title,
      items: _options,
      createdAt: editingIndex >= 0
          ? _slots[editingIndex].createdAt
          : DateTime.now().millisecondsSinceEpoch,
    );

    final nextSlots = List<JebiSlot>.of(_slots);

    if (editingIndex >= 0) {
      nextSlots[editingIndex] = slot;
    } else {
      nextSlots.insert(0, slot);
    }

    setState(() {
      _busy = true;
    });

    try {
      await _repository.saveAll(nextSlots);

      if (!mounted) return;

      setState(() {
        _slots = nextSlots;
        _editingSlotId = slot.id;
      });

      _showMessage(editingIndex >= 0 ? '세트가 수정되었습니다.' : '세트가 저장되었습니다.');
    } catch (error, stackTrace) {
      debugPrint('[JEBI SAVE ERROR] $error');
      debugPrint('$stackTrace');
      _showMessage('세트를 저장하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // 저장 슬롯 삭제
  Future<void> _deleteSlot(String id) async {
    if (!_storageReady || _busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('세트를 삭제하시겠습니까?'),
        content: const Text('저장된 세트가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true || _busy) return;

    final nextSlots = _slots.where((slot) => slot.id != id).toList();

    setState(() {
      _busy = true;
    });

    try {
      await _repository.saveAll(nextSlots);

      if (!mounted) return;

      setState(() {
        _slots = nextSlots;

        if (_editingSlotId == id) {
          _options = _blankOptions();
          _editingSlotId = null;
          _titleController.clear();
        }
      });

      _showMessage('세트가 삭제되었습니다.');
    } catch (error) {
      _showMessage('세트를 삭제하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // 선택지를 DrawEngine에 전달
  void _startGame() {
    List<DrawItem> items;

    try {
      items = JebiRules.createDrawItems(_options);
    } on FormatException catch (error) {
      _showMessage(error.message);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _engine = DrawEngine(items: items, endCondition: JebiRules.isComplete);

      _finalResults = [];
      _step = JebiStep.play;
    });
  }

  void _finishGame(List<DrawResult> results) {
    setState(() {
      _finalResults = results;
      _step = JebiStep.result;
    });
  }

  Future<void> _handleBack() async {
    if (_busy) {
      _showMessage('저장 작업이 끝난 뒤에 이동할 수 있습니다.');
      return;
    }

    if (_step == JebiStep.setup) {
      Navigator.of(context).pop();
      return;
    }

    if (_step == JebiStep.result) {
      setState(() {
        _step = JebiStep.setup;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('추첨을 종료하시겠습니까?'),
        content: const Text(
          '진행 중인 추첨 기록은 초기화되지만, '
          '작성한 선택지는 유지됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('계속 진행'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('설정으로 돌아가기'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _step = JebiStep.setup;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _step == JebiStep.setup && !_busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('제비뽑기'),
          leading: BackButton(onPressed: _handleBack),
        ),
        body: SafeArea(
          child: switch (_step) {
            JebiStep.setup => JebiSetupView(
              options: _options,
              slots: _slots,
              editingSlotId: _editingSlotId,
              titleController: _titleController,
              isLoading: _loading,
              isBusy: _busy,
              storageReady: _storageReady,
              storageError: _storageError,
              onRetryLoad: _loadSlots,
              onNewList: _newList,
              onAddOption: _addOption,
              onRemoveOption: _removeOption,
              onTextChanged: _changeText,
              onToggleWinner: _toggleWinner,
              onLoadSlot: _loadSlot,
              onDeleteSlot: _deleteSlot,
              onSaveSlot: _saveSlot,
              onStart: _startGame,
            ),

            JebiStep.play => DrawPlayView(
              engine: _engine!,
              onFinish: _finishGame,
            ),

            JebiStep.result => DrawResultView(
              results: _finalResults,
              onReset: () {
                setState(() {
                  _step = JebiStep.setup;
                });
              },
            ),
          },
        ),
      ),
    );
  }
}
