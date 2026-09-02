/// The outcome of resolving a [JsonPath] against a decoded JSON tree.
class JsonPathResult {
  /// Whether every segment of the path resolved.
  final bool found;

  /// The value at the path, or null when [found] is false.
  final dynamic value;

  /// The path prefix that failed, e.g. `data.items` when `data` existed but
  /// held no `items`. Null when [found] is true.
  final String? missingAt;

  const JsonPathResult.found(this.value) : found = true, missingAt = null;

  const JsonPathResult.missing(this.missingAt) : found = false, value = null;
}

/// A dotted path into a decoded JSON tree.
///
/// Used by `dataKey`, `nestedKey` and `ErrorDescription.key` so a payload can
/// be reached at any depth rather than one level:
///
/// ```dart
/// dataKey: 'data.items'            // {"data": {"items": [...]}}
/// dataKey: 'data.pages[0].items'   // list indices are supported
/// dataKey: r'meta.user\.name'      // a backslash escapes a literal dot
/// dataKey: ''                      // empty path means the whole body
/// ```
///
/// A single key with no dots — the common case — behaves exactly as it always
/// has, so existing `dataKey: 'data'` values need no change.
class JsonPath {
  /// The path as written.
  final String raw;

  /// `String` map keys and `int` list indices, in order.
  final List<Object> segments;

  JsonPath.parse(this.raw) : segments = _parseSegments(raw);

  /// True when this path selects the root, i.e. it was empty.
  bool get isRoot => segments.isEmpty;

  /// Walks [root] one segment at a time, reporting where it stopped.
  ///
  /// Missing keys and out-of-range indices are reported rather than silently
  /// yielding the root, so a typo or a schema change is visible.
  JsonPathResult resolve(dynamic root) {
    dynamic current = root;

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];

      if (segment is int) {
        if (current is List && segment >= 0 && segment < current.length) {
          current = current[segment];
          continue;
        }
        return JsonPathResult.missing(describePrefix(i));
      }

      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
        continue;
      }
      return JsonPathResult.missing(describePrefix(i));
    }

    return JsonPathResult.found(current);
  }

  /// Renders the path up to and including segment [index], for diagnostics.
  String describePrefix(int index) {
    final buffer = StringBuffer();
    for (var i = 0; i <= index && i < segments.length; i++) {
      final segment = segments[i];
      if (segment is int) {
        buffer.write('[$segment]');
      } else {
        if (buffer.isNotEmpty) buffer.write('.');
        buffer.write(segment);
      }
    }
    return buffer.toString();
  }

  static List<Object> _parseSegments(String path) {
    final segments = <Object>[];
    final buffer = StringBuffer();
    var escaped = false;
    var i = 0;

    void endKey() {
      if (buffer.isNotEmpty) {
        segments.add(buffer.toString());
        buffer.clear();
      }
    }

    while (i < path.length) {
      final char = path[i];

      if (escaped) {
        buffer.write(char);
        escaped = false;
        i++;
        continue;
      }

      switch (char) {
        case r'\':
          escaped = true;
          i++;
        case '.':
          endKey();
          i++;
        case '[':
          endKey();
          final close = path.indexOf(']', i);
          if (close == -1) {
            throw FormatException('Unclosed "[" in JSON path "$path"');
          }
          final index = int.tryParse(path.substring(i + 1, close));
          if (index == null) {
            throw FormatException(
              'Expected a list index between "[" and "]" in JSON path "$path"',
            );
          }
          segments.add(index);
          i = close + 1;
        default:
          buffer.write(char);
          i++;
      }
    }

    endKey();
    return segments;
  }

  @override
  String toString() => 'JsonPath("$raw")';
}
