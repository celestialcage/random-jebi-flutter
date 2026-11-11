import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CharacterImageStorage {
  static int _sequence = 0;

  Future<Directory> _imageDirectory() async {
    final documents = await getApplicationDocumentsDirectory();

    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}'
      'character_images',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<File> fileFor(String fileName) async {
    // 파일명만 허용하고 경로 문자열은 거부
    final validName = RegExp(r'^[a-zA-Z0-9_-]+\.[a-zA-Z0-9]{1,8}$');

    if (!validName.hasMatch(fileName)) {
      throw const FormatException('잘못된 이미지 파일명입니다.');
    }

    final directory = await _imageDirectory();

    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  Future<String> importFrom(String sourcePath) async {
    final source = File(sourcePath);

    if (!await source.exists()) {
      throw const FileSystemException('선택한 이미지 파일을 찾을 수 없습니다.');
    }

    final originalName = source.uri.pathSegments.last;
    final extension = originalName.split('.').last.toLowerCase();

    final safeExtension = RegExp(r'^[a-z0-9]{1,8}$').hasMatch(extension)
        ? extension
        : 'img';

    final fileName =
        'character-${DateTime.now().microsecondsSinceEpoch}'
        '-${_sequence++}.$safeExtension';

    final destination = await fileFor(fileName);

    await source.copy(destination.path);

    return fileName;
  }

  Future<void> delete(String fileName) async {
    final file = await fileFor(fileName);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
