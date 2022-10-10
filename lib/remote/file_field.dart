/// class for handling file upload
class FileFormField {
  /// file path
  final String? path;

  /// file key to be used in the form data
  final String? key, stringFile;

  /// file bytes
  final List<int>? bytes;
 

  FileFormField({this.bytes, this.stringFile,  this.path, this.key});
}
