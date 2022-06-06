extension IntExt on int {
  /// returns date in milliseconds as current Time + (this represented as seconds)
  int get secondsToMilliseconds =>
      DateTime.now().add(Duration(seconds: this)).millisecondsSinceEpoch;

  /// compares time in milliseconds against current timestamp
  /// and returns true if time is past
  bool get isPast => DateTime.now().millisecondsSinceEpoch > this;
  // double get height => ScreenUtil().setHeight(this);

  Duration get toMilliseconds => Duration(milliseconds: this);
}
