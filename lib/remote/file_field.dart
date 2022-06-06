/// class for handling file upload
class FileFormField {
  /// file path
  final String path;

  /// file key to be used in the form data
  final String? key;

  FileFormField({required this.path, this.key});
}
