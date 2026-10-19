/// Arquivo local no build web. O backup em arquivo fica no app Android.
class File {
  File(this.path);

  final String path;

  Future<bool> exists() async => false;

  Future<String> readAsString() {
    throw UnsupportedError(
      'Leitura de arquivo local não está disponível na web.',
    );
  }

  Future<File> writeAsString(String contents, {bool flush = false}) {
    throw UnsupportedError(
      'Gravação de arquivo local não está disponível na web.',
    );
  }
}
