import 'package:data_repository/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cache keys that share a last path segment do not collide', () {
    // Regression: the old implementation used key.split('/').last, so
    // 'posts/1' and 'comments/1' both mapped to '1.json'.
    final manager = CacheManager();
    expect(
      manager.fileNameFor('posts/1'),
      isNot(manager.fileNameFor('comments/1')),
    );
  });

  test('a key maps to a stable, filesystem-safe name', () {
    final manager = CacheManager();
    final name = manager.fileNameFor('posts?page=1&sort=asc');

    expect(name, manager.fileNameFor('posts?page=1&sort=asc'));
    expect(name, endsWith('.json'));
    expect(
      RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name),
      isTrue,
      reason: 'must not contain path separators or query characters',
    );
  });

  test('MapRepository honours the LocalRepository contract', () async {
    final repo = MapRepository();
    final future = DateTime.now()
        .add(const Duration(minutes: 5))
        .millisecondsSinceEpoch;

    await repo.saveData('k', '{"a":1}');
    repo.saveTime('k', future);

    expect(await repo.getData('k'), '{"a":1}');
    expect(await repo.getTime('k'), future);
    expect(await repo.checkCache('k'), isTrue);

    repo.removeData('k');
    expect(await repo.getData('k'), isNull);
    expect(await repo.checkCache('k'), isFalse);
  });

  test('an expired entry reports as unusable', () async {
    final repo = MapRepository();
    await repo.saveData('k', 'v');
    repo.saveTime(
      'k',
      DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    );

    expect(await repo.checkCache('k'), isFalse);
  });

  test('an unknown key is a miss, not a crash', () async {
    final repo = MapRepository();
    expect(await repo.getTime('nope'), isNull);
    expect(await repo.checkCache('nope'), isFalse);
  });
}
