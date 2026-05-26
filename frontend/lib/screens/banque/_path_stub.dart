// Stub for path_provider on web — never called because _downloadPdf() is
// guarded by !kIsWeb, but needed so the code compiles on web.

class Directory {
  final String path;
  const Directory(this.path);
}

Future<Directory> getTemporaryDirectory() async => const Directory('/tmp');
