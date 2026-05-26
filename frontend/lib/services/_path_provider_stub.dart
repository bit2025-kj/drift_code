// Stub for path_provider on web — getApplicationDocumentsDirectory is never
// called on web (kIsWeb guards all callers), but needs to compile.

class Directory {
  final String path;
  const Directory(this.path);
}

Future<Directory> getApplicationDocumentsDirectory() async =>
    const Directory('/downloads');
