// Mobile implementation — dart:io + open_filex are available here.

import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> createDownloadDir(String basePath) async {
  final dir = Directory(p.join(basePath, 'nafa_downloads'));
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir.path;
}

Future<void> deleteLocalFiles(String documentId) async {
  try {
    final base = Directory(p.join(
      (await getApplicationDocumentsDirectory()).path,
      'nafa_downloads',
    ));
    if (!await base.exists()) return;
    await for (final entity in base.list()) {
      if (entity is File && p.basename(entity.path).startsWith(documentId)) {
        await entity.delete();
      }
    }
  } catch (_) {}
}

Future<void> openDownloadedFile(String filePath) async {
  await OpenFilex.open(filePath);
}

Future<double> computeTotalSizeMb(String dirPath) async {
  final dir = Directory(dirPath);
  if (!await dir.exists()) return 0;
  double total = 0;
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) {
      total += await entity.length();
    }
  }
  return total / (1024 * 1024);
}
