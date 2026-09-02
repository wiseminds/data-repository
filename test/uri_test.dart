import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';

ApiRequest<Map<String, dynamic>, Map<String, dynamic>> request({
  String baseUrl = 'https://example.com',
  String path = '',
  Map<String, dynamic> query = const {},
}) => ApiRequest<Map<String, dynamic>, Map<String, dynamic>>(
  baseUrl: baseUrl,
  path: path,
  query: query,
);

void main() {
  group('ApiRequest.uri', () {
    test('does not append a bare "?" when there are no query parameters', () {
      expect(
        request(path: 'posts').uri.toString(),
        'https://example.com/posts',
      );
    });

    test('serialises the explicit query map', () {
      expect(
        request(path: 'posts', query: {'page': 1}).uri.toString(),
        'https://example.com/posts?page=1',
      );
    });

    test('explicit query wins over a parameter embedded in the path', () {
      // Previously the path's value was spread last and silently won.
      final uri = request(path: 'posts?page=99', query: {'page': 1}).uri;
      expect(uri.queryParameters['page'], '1');
    });

    test('keeps path-embedded parameters the query map does not override', () {
      final uri = request(path: 'posts?sort=asc', query: {'page': 1}).uri;
      expect(uri.queryParameters, {'sort': 'asc', 'page': '1'});
    });

    test('collapses the double slash between baseUrl and path', () {
      expect(
        request(baseUrl: 'https://example.com/', path: '/posts').uri.toString(),
        'https://example.com/posts',
      );
    });

    test('drops empty path segments', () {
      expect(request(path: 'a//b').uri.toString(), 'https://example.com/a/b');
    });
  });
}
