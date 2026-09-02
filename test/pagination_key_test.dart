// ignore_for_file: deprecated_member_use_from_same_package

import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Page extends Pagination {
  _Page({super.total, super.limit, super.pages, super.page});

  static _Page fromJson(Map<String, dynamic> json) => _Page(
    total: json['total'] as int? ?? 0,
    limit: json['limit'] as int? ?? 0,
    pages: json['pages'] as int? ?? 0,
    page: json['page'] as int? ?? 1,
  );
}

void main() {
  Future<ApiResponse<List<dynamic>, dynamic>> fetch(
    String payload, {
    String dataKey = '',
    String paginationKey = '',
    String? nestedKey,
  }) {
    final client = MockClient((_) async => http.Response(payload, 200));
    return RemoteRepository(HttpApiProvider(client: client)).handleRequest(
      ApiRequest<List<dynamic>, dynamic>(
        baseUrl: 'https://example.com',
        path: 'things',
        dataKey: dataKey,
        paginationKey: paginationKey,
        nestedKey: nestedKey,
        hasPagination: true,
        interceptors: [
          JsonInterceptor<ApiError>(
            const {},
            paginationFactory: _Page.fromJson,
          ),
        ],
      ),
    );
  }

  const nested = '{"result":{"page":2,"pages":7,"data":[1,2]}}';

  test('paginationKey locates the envelope with an absolute dataKey', () async {
    final response = await fetch(
      nested,
      dataKey: 'result.data',
      paginationKey: 'result',
    );

    expect(response.body, [1, 2]);
    expect(response.pagination?.page, 2);
    expect(response.pagination?.pages, 7);
  });

  test('pagination defaults to the root', () async {
    final response = await fetch(
      '{"page":3,"pages":9,"data":[1]}',
      dataKey: 'data',
    );

    expect(response.body, [1]);
    expect(response.pagination?.page, 3);
  });

  test('the deprecated nestedKey still produces the same result', () async {
    final legacy = await fetch(nested, nestedKey: 'result', dataKey: 'data');
    final modern = await fetch(
      nested,
      dataKey: 'result.data',
      paginationKey: 'result',
    );

    expect(legacy.body, modern.body);
    expect(legacy.pagination?.page, modern.pagination?.page);
    expect(legacy.pagination?.pages, modern.pagination?.pages);
  });

  test('nestedKey still scopes dataKey while it is set', () async {
    // dataKey stays relative to nestedKey, as it always was.
    final response = await fetch(nested, nestedKey: 'result', dataKey: 'data');
    expect(response.body, [1, 2]);
  });

  test('paginationKey may itself be multi-level', () async {
    final response = await fetch(
      '{"a":{"b":{"page":4,"pages":4,"items":[7]}}}',
      dataKey: 'a.b.items',
      paginationKey: 'a.b',
    );

    expect(response.body, [7]);
    expect(response.pagination?.page, 4);
  });

  test('an unresolved paginationKey leaves pagination null and logs', () async {
    final logs = <String>[];
    ApiConfig().logger = logs.add;
    addTearDown(() => ApiConfig().logger = null);

    final response = await fetch(
      '{"data":[1]}',
      dataKey: 'data',
      paginationKey: 'meta',
    );

    expect(response.body, [1]);
    expect(response.pagination, isNull);
    expect(logs.any((l) => l.contains('paginationKey')), isTrue);
  });
}
