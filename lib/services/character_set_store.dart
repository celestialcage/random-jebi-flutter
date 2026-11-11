// 편집 화면에서 저장 서비스로 넘길 입력 DTO
import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:random_jebi_flutter/repositories/character_set_repository.dart';
import 'package:random_jebi_flutter/services/character_image_storage.dart';

// 저장소로 전달하는 입력 DTO
class CharacterInput {
  final String id;
  final String name;
  final String? existingFileName;
  final String? pickedPath; // 임시 편집 상태

  final double focusX;
  final double focusY;

  const CharacterInput({
    required this.id,
    required this.name,
    this.existingFileName,
    this.pickedPath,
    this.focusX = 0.0,
    this.focusY = 0.0,
  });
}

// 캐릭터 세트 JSON과 이미지 처리 엮기
class CharacterSetStore {
  static int _sequence = 0;

  final CharacterSetRepository repository;
  final CharacterImageStorage images;

  CharacterSetStore({
    CharacterSetRepository? repository,
    CharacterImageStorage? images,
  }) : repository = repository ?? CharacterSetRepository(),
       images = images ?? CharacterImageStorage();

  static String makeId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}'
        '-${_sequence++}';
  }

  Future<List<CharacterSet>> loadSets() {
    return repository.loadAll();
  }

  Future<void> saveSet({
    String? setId,
    required String title,
    required List<CharacterInput> characters,
  }) async {
    // 세트 단위 검사
    if (title.trim().isEmpty) {
      throw const FormatException('세트 이름을 입력해 주세요.');
    }

    if (characters.length < 2) {
      throw const FormatException('캐릭터 데이터는 최소 2개 필요합니다.');
    }

    final ids = characters.map((c) => c.id).toSet();

    if (ids.length != characters.length) {
      throw const FormatException('캐릭터 ID가 중복되었습니다.');
    }

    // 개별 캐릭터 데이터 검사
    for (final character in characters) {
      if (character.name.trim().isEmpty) {
        throw const FormatException('캐릭터의 이름은 비워둘 수 없습니다.');
      }

      if (character.pickedPath == null && character.existingFileName == null) {
        throw const FormatException('캐릭터의 이미지는 비워둘 수 없습니다.');
      }

      if (!character.focusX.isFinite ||
          !character.focusY.isFinite ||
          character.focusX < -1 ||
          character.focusX > 1 ||
          character.focusY < -1 ||
          character.focusY > 1) {
        throw const FormatException('이미지 초점값은 -1부터 1 사이여야 합니다.');
      }
    }

    // 기존 데이터 로드에 실패하면 저장을 진행하지 않음
    final previous = await repository.loadAll();

    if (setId != null && !previous.any((set) => set.id == setId)) {
      throw StateError('수정할 세트를 찾을 수 없습니다.');
    }

    final importedFiles = <String>[];

    try {
      final updatedCharacters = <CustomCharacter>[];

      for (final character in characters) {
        String fileName;

        if (character.pickedPath != null) {
          fileName = await images.importFrom(character.pickedPath!);
          importedFiles.add(fileName);
        } else {
          fileName = character.existingFileName!;
        }

        updatedCharacters.add(
          CustomCharacter(
            id: character.id,
            name: character.name.trim(),
            imageFileName: fileName,
            focusX: character.focusX,
            focusY: character.focusY,
          ),
        );
      }

      final updatedSet = CharacterSet(
        id: setId ?? makeId('set'),
        title: title.trim(),
        characters: updatedCharacters,
      );

      final next = <CharacterSet>[
        if (setId == null) updatedSet,
        for (final old in previous)
          if (old.id == setId) updatedSet else old,
      ];

      // 이미지가 모두 준비된 후 메타데이터 저장
      await repository.saveAll(next);

      // 성공 후 기존의 불필요한 이미지 정리
      await _cleanupUnused(previous, next);
    } catch (_) {
      // 저장 호출이 실패해도 실제 반영 여부가 불명확할 수 있음.
      // 메타데이터를 다시 읽고 미참조 파일만 정리.
      try {
        final persisted = await repository.loadAll();
        final referenced = _referencedFiles(persisted);

        for (final fileName in importedFiles) {
          if (!referenced.contains(fileName)) {
            await images.delete(fileName);
          }
        }
      } catch (_) {
        // 저장 상태를 확인할 수 없으면 이미지 삭제를 보류
      }
      rethrow;
    }
  }

  Future<void> deleteSet(String setId) async {
    final previous = await repository.loadAll();

    final next = previous.where((set) => set.id != setId).toList();

    if (next.length == previous.length) {
      throw StateError('삭제할 세트를 찾을 수 없습니다.');
    }

    // 메타데이터에서 세트를 먼저 제거
    await repository.saveAll(next);

    // 다른 세트에서 참조하지 않는 파일만 삭제
    await _cleanupUnused(previous, next);
  }

  Set<String> _referencedFiles(List<CharacterSet> sets) {
    return {
      for (final set in sets)
        for (final character in set.characters)
          if (character.imageFileName != null) character.imageFileName!,
    };
  }

  Future<void> _cleanupUnused(
    List<CharacterSet> previous,
    List<CharacterSet> next,
  ) async {
    final before = _referencedFiles(previous);
    final after = _referencedFiles(next);

    for (final fileName in before.difference(after)) {
      try {
        await images.delete(fileName);
      } catch (_) {
        // 메타데이터 저장은 성공했으므로 예전 파일은
        // 삭제 실패해도 데이터 손실을 피하기 위해 무시
      }
    }
  }
}
