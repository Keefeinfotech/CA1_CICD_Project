import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/task.dart';
import 'package:frontend/services/task_repository.dart';

import '../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists tasks across repository instances', () async {
    final first = SharedPreferencesTaskRepository();
    await first.save('owner', <Task>[makeTask(title: 'Persisted')]);

    final second = SharedPreferencesTaskRepository();
    final loaded = await second.load('owner');

    expect(loaded, hasLength(1));
    expect(loaded.single.title, 'Persisted');
  });

  test('keeps each owner separate', () async {
    final repository = SharedPreferencesTaskRepository();
    await repository.save('a', <Task>[makeTask(id: 'a1', title: 'A')]);
    await repository.save('b', <Task>[makeTask(id: 'b1', title: 'B')]);

    expect((await repository.load('a')).single.title, 'A');
    expect((await repository.load('b')).single.title, 'B');
  });

  test('returns an empty list when nothing is stored', () async {
    final repository = SharedPreferencesTaskRepository();
    expect(await repository.load('new-owner'), isEmpty);
  });

  test('throws a readable error for corrupt JSON', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auxilia.tasks.v1.owner': 'not-json',
    });
    final repository = SharedPreferencesTaskRepository();

    await expectLater(
      repository.load('owner'),
      throwsA(isA<TaskStorageException>()),
    );
  });

  test('throws when the stored shape is not a list', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auxilia.tasks.v1.owner': jsonEncode(<String, dynamic>{'tasks': []}),
    });
    final repository = SharedPreferencesTaskRepository();

    await expectLater(
      repository.load('owner'),
      throwsA(isA<TaskStorageException>()),
    );
  });

  test('skips individual malformed records', () async {
    final valid = makeTask(title: 'Valid');
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auxilia.tasks.v1.owner': jsonEncode(<dynamic>[
        valid.toJson(),
        <String, dynamic>{'id': 'broken'},
        'not-a-record',
      ]),
    });

    final loaded = await SharedPreferencesTaskRepository().load('owner');

    expect(loaded, hasLength(1));
    expect(loaded.single.title, 'Valid');
  });

  test('clears stored tasks', () async {
    final repository = SharedPreferencesTaskRepository();
    await repository.save('owner', <Task>[makeTask()]);
    await repository.clear('owner');

    expect(await repository.load('owner'), isEmpty);
  });
}
