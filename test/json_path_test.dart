import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('JsonPath parsing and resolution', () {
    test('an empty path selects the root', () {
      final path = JsonPath.parse('');
      expect(path.isRoot, isTrue);
      expect(path.resolve({'a': 1}).value, {'a': 1});
    });

    test('a single key behaves as it always has', () {
      expect(JsonPath.parse('data').resolve({'data': 42}).value, 42);
    });

    test('descends arbitrarily deep', () {
      final json = {
        'response': {
          'payload': {
            'result': {
              'items': [1, 2, 3],
            },
          },
        },
      };
      expect(
        JsonPath.parse('response.payload.result.items').resolve(json).value,
        [1, 2, 3],
      );
    });

    test('indexes into lists', () {
      final json = {
        'data': {
          'pages': [
            {
              'items': ['a'],
            },
            {
              'items': ['b'],
            },
          ],
        },
      };
      expect(JsonPath.parse('data.pages[1].items[0]').resolve(json).value, 'b');
    });

    test('a backslash escapes a literal dot', () {
      final json = {
        'meta': {'user.name': 'ada'},
      };
      expect(JsonPath.parse(r'meta.user\.name').resolve(json).value, 'ada');
    });

    test('reports the segment that failed', () {
      final result = JsonPath.parse('data.items.name').resolve({'data': {}});
      expect(result.found, isFalse);
      expect(result.value, isNull);
      expect(result.missingAt, 'data.items');
    });

    test('an out-of-range index is a miss, not a crash', () {
      final result = JsonPath.parse('data[5]').resolve({
        'data': [1],
      });
      expect(result.found, isFalse);
      expect(result.missingAt, 'data[5]');
    });

    test('descending through a non-collection is a miss', () {
      final result = JsonPath.parse('a.b').resolve({'a': 'scalar'});
      expect(result.found, isFalse);
    });

    test('a malformed index is rejected at parse time', () {
      expect(() => JsonPath.parse('data[x]'), throwsFormatException);
      expect(() => JsonPath.parse('data[0'), throwsFormatException);
    });

    test('a null value that is present still counts as found', () {
      final result = JsonPath.parse('a').resolve({'a': null});
      expect(result.found, isTrue);
      expect(result.value, isNull);
    });
  });

  group('deep keys through the interceptor', () {
    Future<ApiResponse<List<dynamic>, dynamic>> fetch(
      String payload, {
      String dataKey = '',
      String? nestedKey,
    }) async {
      final client = MockClient((_) async => http.Response(payload, 200));
      return RemoteRepository(HttpApiProvider(client: client)).handleRequest(
        ApiRequest<List<dynamic>, dynamic>(
          baseUrl: 'https://example.com',
          path: 'things',
          dataKey: dataKey,
          nestedKey: nestedKey,
          interceptors: [JsonInterceptor<ApiError>(const {})],
        ),
      );
    }

    test('reaches a payload three levels down', () async {
      final response = await fetch(
        '{"response":{"payload":{"items":[1,2]}}}',
        dataKey: 'response.payload.items',
      );
      expect(response.body, [1, 2]);
    });

    test('nestedKey and dataKey compose, each multi-level', () async {
      final response = await fetch(
        '{"a":{"b":{"c":{"d":[9]}}}}',
        nestedKey: 'a.b',
        dataKey: 'c.d',
      );
      expect(response.body, [9]);
    });

    test('an unresolved path yields null and logs', () async {
      final logs = <String>[];
      ApiConfig().logger = logs.add;
      addTearDown(() => ApiConfig().logger = null);

      final response = await fetch(
        '{"data":{}}',
        dataKey: 'data.items.missing',
      );

      expect(response.body, isNull);
      expect(logs.any((l) => l.contains('did not resolve')), isTrue);
      expect(
        logs.any((l) => l.contains('data.items')),
        isTrue,
        reason: 'the log names the segment that failed',
      );
    });

    test('a single-key dataKey still works unchanged', () async {
      final response = await fetch('{"data":[1]}', dataKey: 'data');
      expect(response.body, [1]);
    });
  });
}
