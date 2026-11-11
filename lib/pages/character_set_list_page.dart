import 'package:flutter/material.dart';
import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:random_jebi_flutter/pages/character_set_editor_page.dart';
import 'package:random_jebi_flutter/services/character_set_store.dart';
import 'package:random_jebi_flutter/widgets/character_portrait.dart';

class CharacterSetListPage extends StatefulWidget {
  final CharacterSetStore store;

  const CharacterSetListPage({super.key, required this.store});

  @override
  State<CharacterSetListPage> createState() => _CharacterSetListPageState();
}

class _CharacterSetListPageState extends State<CharacterSetListPage> {
  List<CharacterSet> _sets = [];
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sets = await widget.store.loadSets();

      if (!mounted) return;

      setState(() {
        _sets = sets;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = '저장된 세트를 불러오지 못했습니다: $error';
      });
    }
  }

  Future<void> _openEditor([CharacterSet? initial]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CharacterSetEditorPage(store: widget.store, initial: initial),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      await _load();
    }
  }

  Future<void> _delete(CharacterSet set) async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('세트를 삭제하시겠습니까?'),
        content: Text('"${set.title}" 세트와 연결된 이미지가 삭제됩니다.'),
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

    if (!mounted || confirmed != true) return;

    setState(() => _deleting = true);

    try {
      await widget.store.deleteSet(set.id);
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제에 실패했습니다: $error')));
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캐릭터 세트 관리')),
      floatingActionButton: _error == null && !_loading
          ? FloatingActionButton.extended(
              onPressed: _deleting ? null : () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('새 세트'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('다시 시도')),
                ],
              ),
            )
          : _sets.isEmpty
          ? const Center(
              child: Text(
                '아직 저장된 세트가 없습니다.\n'
                '새 세트를 만들어 보세요.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: _sets.length,
              itemBuilder: (context, index) {
                final set = _sets[index];

                return Card(
                  color: Colors.white,
                  child: ListTile(
                    onTap: _deleting ? null : () => _openEditor(set),
                    leading: SizedBox(
                      width: 58,
                      height: 58,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CharacterPortrait(
                          storage: widget.store.images,
                          fileName: set.characters.first.imageFileName,
                        ),
                      ),
                    ),
                    title: Text(
                      set.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('캐릭터 데이터 ${set.characters.length}개'),
                    trailing: IconButton(
                      tooltip: '${set.title} 삭제',
                      onPressed: _deleting ? null : () => _delete(set),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
