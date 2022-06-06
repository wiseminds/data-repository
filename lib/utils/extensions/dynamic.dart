extension ToIntExt on dynamic {
  int? get asInt {
    try {
      return this as int;
    } catch (e) {
      return null;
    }
  }
}

extension ToIntEx on Object {
  int? get asInt {
    if (this is int) return this as int;
    try {
      return int.tryParse(toString());
    } catch (e) {
      return null;
    }
  }
}
