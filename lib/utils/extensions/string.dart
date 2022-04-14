extension E on String {
    String get normalizeUrl {
    return replaceAll('//', '//');
  }
}