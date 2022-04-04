class CacheDescription {
  /// unique key used to store both cache data and metadata
  final String _key;
  String get key => _key;

  /// time in seconds, defaults to [120] seconds
  final int lifeSpan;

  /// ignore cache expiration time
  final bool overrideTime;

  /// expire cache data
  final bool invalidateCache;

  /// this tell the cache client to only fetch from cache and to ignore saving to cache
  final bool ignoreSave;

  CacheDescription copyWith(
          {int? lifeSpan,
          bool? overrideTime,
          bool? invalidateCache,
          bool? ignoreSave}) =>
      CacheDescription(_key,
          lifeSpan: lifeSpan ?? this.lifeSpan,
          overrideTime: overrideTime ?? this.overrideTime,
          ignoreSave: ignoreSave ?? this.ignoreSave,
          invalidateCache: invalidateCache ?? this.invalidateCache);

  CacheDescription(this._key,
      {this.ignoreSave = false,
      this.lifeSpan = CacheDescription.oneMinute * 2,
      this.overrideTime = false,
      this.invalidateCache = false});

  static const oneMonth = oneDay * 30;
  static const sevenDays = oneDay * 7;
  static const oneDay = oneHour * 24;
  static const oneHour = oneMinute * 60;
  static const oneMinute = 60 * oneSecond;

  /// in milliseconds
  static const oneSecond = 1000;
}
