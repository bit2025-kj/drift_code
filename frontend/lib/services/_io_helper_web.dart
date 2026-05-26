// Web stubs — dart:io and open_filex are unavailable on web.
// These functions are never called (kIsWeb guards all call sites),
// but must exist so the code compiles.

Future<String> createDownloadDir(String basePath) async => basePath;

Future<void> deleteLocalFiles(String documentId) async {}

Future<void> openDownloadedFile(String filePath) async {}

Future<double> computeTotalSizeMb(String dirPath) async => 0;
