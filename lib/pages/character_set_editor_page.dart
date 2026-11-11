import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:random_jebi_flutter/services/character_set_store.dart';
import 'package:random_jebi_flutter/widgets/character_portrait.dart';

class _EditableCharacter {
  final String id;
  String name;
  String? imageFileName;
  String? pickedPath;

  double focusX;
  double focusY;

  _EditableCharacter({
    required this.id,
    this.name = '',
    this.imageFileName,
    this.pickedPath,
    this.focusX = 0.0,
    this.focusY = 0.0,
  });
}

class CharacterSetEditorPage extends StatefulWidget {
  final CharacterSetStore store;
  final CharacterSet? initial;

  const CharacterSetEditorPage({super.key, required this.store, this.initial});

  @override
  State<CharacterSetEditorPage> createState() => _CharacterSetEditorPageState();
}

class _CharacterSetEditorPageState extends State<CharacterSetEditorPage> {
  final _picker = ImagePicker();

  late final TextEditingController _titleController;
  late List<_EditableCharacter> _characters;

  bool _saving = false;

  _EditableCharacter _newCharacter() {
    return _EditableCharacter(id: CharacterSetStore.makeId('char'));
  }

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;

    _titleController = TextEditingController(text: initial?.title ?? '');

    _characters = initial == null
        ? [_newCharacter(), _newCharacter()]
        : [
            for (final character in initial.characters)
              _EditableCharacter(
                id: character.id,
                name: character.name,
                imageFileName: character.imageFileName,
                focusX: character.focusX,
                focusY: character.focusY,
              ),
          ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _addCharacter() {
    setState(() {
      _characters = [..._characters, _newCharacter()];
    });
  }

  void _removeCharacter(String id) {
    if (_characters.length <= 2) {
      _message('캐릭터 데이터는 최소 2개가 필요합니다.');
      return;
    }

    setState(() {
      _characters = _characters
          .where((character) => character.id != id)
          .toList();
    });
  }

  Future<void> _pickImage(_EditableCharacter character) async {
    if (_saving) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (picked == null || !mounted) return;
      if (!_characters.contains(character)) return;

      setState(() {
        character.pickedPath = picked.path;
      });
    } catch (error) {
      if (!mounted) return;
      _message('사진을 선택하지 못했습니다: $error');
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    try {
      await widget.store.saveSet(
        setId: widget.initial?.id,
        title: _titleController.text,
        characters: [
          for (final character in _characters)
            CharacterInput(
              id: character.id,
              name: character.name,
              existingFileName: character.imageFileName,
              pickedPath: character.pickedPath,
              focusX: character.focusX,
              focusY: character.focusY,
            ),
        ],
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      if (!mounted) return;
      _message(error.message);
    } catch (error) {
      if (!mounted) return;
      _message('세트를 저장하지 못했습니다: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _characterEditor(int index) {
    final character = _characters[index];
    final hasImage =
        character.pickedPath != null || character.imageFileName != null;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '캐릭터 ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '캐릭터 삭제',
                  onPressed: _saving || _characters.length <= 2
                      ? null
                      : () => _removeCharacter(character.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _focusEditor(character),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _saving ? null : () => _pickImage(character),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(hasImage ? '이미지 변경' : '이미지 선택'),
            ),

            const SizedBox(height: 10),

            TextFormField(
              key: ValueKey('name-${character.id}'),
              initialValue: character.name,
              enabled: !_saving,
              maxLength: 40,
              onChanged: (value) {
                character.name = value;
              },
              decoration: const InputDecoration(
                labelText: '캐릭터 이름',
                hintText: '예: 글루민',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _focusPreview(
    _EditableCharacter character, {
    required String label,
    required double aspectRatio,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CharacterPortrait(
              storage: widget.store.images,
              fileName: character.imageFileName,
              previewPath: character.pickedPath,
              alignment: Alignment(character.focusX, character.focusY),
            ),
          ),
        ),
      ],
    );
  }

  Widget _focusEditor(_EditableCharacter character) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _focusPreview(
                character,
                label: '세로 미리보기',
                aspectRatio: 3 / 4,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _focusPreview(
                character,
                label: '가로 미리보기',
                aspectRatio: 16 / 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text('가로 초점 · 왼쪽 ↔ 오른쪽'),
        Slider(
          value: character.focusX,
          min: -1,
          max: 1,
          divisions: 20,
          onChanged: _saving
              ? null
              : (value) {
                  setState(() {
                    character.focusX = value;
                  });
                },
        ),

        const Text('세로 초점 · 위쪽 ↕ 아래쪽'),
        Slider(
          value: character.focusY,
          min: -1,
          max: 1,
          divisions: 20,
          onChanged: _saving
              ? null
              : (value) {
                  setState(() {
                    character.focusY = value;
                  });
                },
        ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _saving
                ? null
                : () {
                    setState(() {
                      character.focusX = 0;
                      character.focusY = 0;
                    });
                  },
            icon: const Icon(Icons.center_focus_strong),
            label: const Text('초점 중앙으로'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initial == null ? '새 캐릭터 세트' : '캐릭터 세트 수정'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _titleController,
                      enabled: !_saving,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: '세트 이름',
                        hintText: '예: 동물의 숲',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text('캐릭터 데이터를 2개 이상 등록하세요.'),

                    const SizedBox(height: 12),

                    for (int i = 0; i < _characters.length; i++)
                      Padding(
                        key: ValueKey(_characters[i].id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _characterEditor(i),
                      ),

                    OutlinedButton.icon(
                      onPressed: _saving ? null : _addCharacter,
                      icon: const Icon(Icons.add),
                      label: const Text('캐릭터 추가'),
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
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? '저장 중...' : '세트 저장하기'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
