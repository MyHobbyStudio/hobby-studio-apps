class ImportException implements Exception {
  final String message;

  ImportException(this.message);

  @override
  String toString() => message;
}