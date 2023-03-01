// /// Application environment variables
abstract class Env {
  String get baseUrl;
}

class Production extends Env {
  Production() : super();

  @override
  String toString() => 'Production';

  @override
  String get baseUrl => 'https://jsonplaceholder.typicode.com';
}

class Development extends Env {
  Development() : super();

  @override
  String toString() => 'Development';
  @override
  String get baseUrl => 'https://jsonplaceholder.typicode.com';
}

class Test extends Env {
  Test() : super();

  @override
  String toString() => 'Test';

  @override
  String get baseUrl => 'http://localhost:3000';
}
