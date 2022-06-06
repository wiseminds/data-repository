extension MapExt on Map<String, dynamic> {
  T? getKey<T>(String key) {
    try {
      if (containsKey(key)) {
        return this[key];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
