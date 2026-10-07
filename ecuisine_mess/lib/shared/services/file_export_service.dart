import 'dart:io';

import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:path/path.dart' as p;

/// Saves exported files for the user.
abstract interface class FileExportService {
  /// Writes [bytes] as [fileName] and returns the full path it was saved to.
  Future<String> save(String fileName, List<int> bytes);
}

/// Saves into the user's Downloads folder, never overwriting an existing file.
class DownloadsFileExportService implements FileExportService {
  DownloadsFileExportService({Directory? directory}) : _directory = directory;

  final Directory? _directory;

  Directory _resolve() {
    if (_directory != null) return _directory;
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw const UnexpectedFailure('Cannot locate the Downloads folder');
    }
    return Directory(p.join(home, 'Downloads'));
  }

  @override
  Future<String> save(String fileName, List<int> bytes) async {
    try {
      final dir = _resolve();
      await dir.create(recursive: true);
      var target = File(p.join(dir.path, fileName));
      final stem = p.basenameWithoutExtension(fileName);
      final ext = p.extension(fileName);
      for (var n = 1; await target.exists(); n++) {
        target = File(p.join(dir.path, '$stem ($n)$ext'));
      }
      await target.writeAsBytes(bytes, flush: true);
      return target.path;
    } on FileSystemException catch (e) {
      throw UnexpectedFailure('Could not save file: ${e.message}');
    }
  }
}
