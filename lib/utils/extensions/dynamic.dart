extension ToIntEx on Object {
  /// Best-effort conversion to [int]; returns null when the value is not
  /// an int and cannot be parsed as one.
  int? get asInt {
    if (this is int) return this as int;
    return int.tryParse(toString());
  }
}
