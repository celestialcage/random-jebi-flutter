import 'package:flutter/material.dart';
import 'package:random_jebi_flutter/decision/decision_engine.dart';
import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:random_jebi_flutter/decision/decision_modes.dart';
import 'package:random_jebi_flutter/pages/character_set_list_page.dart';
import 'package:random_jebi_flutter/services/character_set_store.dart';
import 'package:random_jebi_flutter/widgets/immersive_reveal_view.dart';
import 'package:random_jebi_flutter/widgets/immersive_selection_view.dart';

class CustomDecisionPage extends StatefulWidget {
  const CustomDecisionPage({super.key});

  @override
  State<CustomDecisionPage> createState() => _CustomDecisionPageState();
}

class _CustomDecisionPageState extends State<CustomDecisionPage> {
  final DecisionEngine _engine = DecisionEngine();
  final CharacterSetStore _store = CharacterSetStore();

  List<CharacterSet> _sets = [];

  int _setIndex = 0;
  int _modeIndex = 0;

  DecisionRound? _round;
  String? _selectedCharacterId;

  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    // 기존에 선택했던 세트 기억
    final previousId = _sets.isNotEmpty && _setIndex < _sets.length
        ? _sets[_setIndex].id
        : null;

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final loaded = await _store.loadSets();

      if (!mounted) return;

      var nextIndex = loaded.indexWhere((set) => set.id == previousId);

      if (nextIndex < 0) nextIndex = 0;

      setState(() {
        _sets = loaded;
        _setIndex = nextIndex;
        _selectedCharacterId = null;
        _loading = false;

        _round = loaded.isEmpty
            ? null
            : _engine.createRound(
                set: loaded[nextIndex],
                mode: decisionModes[_modeIndex],
              );
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = '캐릭터 세트를 불러오지 못했습니다: $error';
      });
    }
  }

  void _newRound() {
    if (_sets.isEmpty) return;

    setState(() {
      _round = _engine.createRound(
        set: _sets[_setIndex],
        mode: decisionModes[_modeIndex],
      );
      _selectedCharacterId = null;
    });
  }

  void _changeSet(int index) {
    if (index == _setIndex) return;

    setState(() {
      _setIndex = index;
      _round = _engine.createRound(
        set: _sets[_setIndex],
        mode: decisionModes[_modeIndex],
      );
      _selectedCharacterId = null;
    });
  }

  void _changeMode(int index) {
    if (index == _modeIndex) return;

    setState(() {
      _modeIndex = index;
      _round = _engine.createRound(
        set: _sets[_setIndex],
        mode: decisionModes[_modeIndex],
      );
      _selectedCharacterId = null;
    });
  }

  void _choose(String characterId) {
    final round = _round;

    if (round == null) return;

    // 현재 라운드에 있는 캐릭터인지 확인
    if (characterId != round.first.id && characterId != round.second.id) {
      return;
    }

    setState(() {
      _selectedCharacterId = characterId;
    });
  }

  void _returnToSelection() {
    if (_selectedCharacterId == null) return;

    setState(() {
      _selectedCharacterId = null;
    });
  }

  Future<void> _openSetManager() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => CharacterSetListPage(store: _store)),
    );

    if (!mounted) return;

    // 편집되거나 삭제된 세트 정보를 다시 읽음
    await _loadSets();
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('커스텀 모드')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.collections_bookmark_outlined, size: 64),
              const SizedBox(height: 16),
              const Text(
                '아직 캐릭터 세트가 없습니다.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('캐릭터 데이터를 입력해 세트를 만드세요.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openSetManager,
                icon: const Icon(Icons.add),
                label: const Text('세트 만들기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('커스텀 모드')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadSets,
                child: const Text('다시 불러오기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    final round = _round;

    if (_loading) {
      content = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_loadError != null) {
      content = _buildErrorScreen();
    } else if (_sets.isEmpty || round == null) {
      content = _buildEmptyScreen();
    } else if (_selectedCharacterId == null) {
      content = ImmersiveSelectionView(
        key: const ValueKey('selection-view'),
        sets: _sets,
        setIndex: _setIndex,
        modeIndex: _modeIndex,
        round: round,
        storage: _store.images,
        onSetChanged: _changeSet,
        onModeChanged: _changeMode,
        onChoose: _choose,
        onNewRound: _newRound,
        onManage: _openSetManager,
        onBack: () => Navigator.of(context).pop(),
      );
    } else {
      final selected = round.first.id == _selectedCharacterId
          ? round.first
          : round.second;

      content = ImmersiveRevealView(
        key: ValueKey('reveal-${selected.id}'),
        character: selected,
        answer: round.resultFor(selected.id),
        storage: _store.images,
        onBack: _returnToSelection,
        onNewRound: _newRound,
      );
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PopScope<void>(
      canPop: _selectedCharacterId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedCharacterId != null) {
          _returnToSelection();
        }
      },
      child: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: content,
      ),
    );
  }
}
