import 'dart:io';

import 'package:flutter/material.dart';
import 'package:random_jebi_flutter/services/character_image_storage.dart';

class CharacterPortrait extends StatefulWidget {
  final CharacterImageStorage storage;
  final String? fileName;
  final String? previewPath;
  final AlignmentGeometry alignment;

  const CharacterPortrait({
    super.key,
    required this.storage,
    this.fileName,
    this.previewPath,
    this.alignment = Alignment.center,
  });

  @override
  State<CharacterPortrait> createState() => _CharacterPortraitState();
}

class _CharacterPortraitState extends State<CharacterPortrait> {
  Future<File>? _fileFuture;

  @override
  void initState() {
    super.initState();
    _resolveFile();
  }

  void _resolveFile() {
    if (widget.previewPath != null) {
      _fileFuture = Future.value(File(widget.previewPath!));
    } else if (widget.fileName != null) {
      _fileFuture = widget.storage.fileFor(widget.fileName!);
    } else {
      _fileFuture = null;
    }
  }

  @override
  void didUpdateWidget(covariant CharacterPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.fileName != widget.fileName ||
        oldWidget.previewPath != widget.previewPath ||
        oldWidget.storage != widget.storage) {
      _resolveFile();
    }
  }

  Widget _placeholder() {
    return const ColoredBox(
      color: Color(0xFF312E81),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Colors.white70,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final future = _fileFuture;

    if (future == null) return _placeholder();

    return FutureBuilder<File>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _placeholder();
        }

        return Image.file(
          snapshot.data!,
          fit: BoxFit.cover,
          alignment: widget.alignment,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return _placeholder();
          },
        );
      },
    );
  }
}
