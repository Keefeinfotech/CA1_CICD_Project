import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskStorageException implements Exception {
  TaskStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Abstraction over local persistence so the storage engine can be replaced
/// without changing task logic or the UI.
abstract class TaskRepository {
  Future<List<Task>> load(String ownerId);

  Future<void> save(String ownerId, List<Task> tasks);

  Future<void> clear(String ownerId);
}

class SharedPreferencesTaskRepository implements TaskRepository {
  SharedPreferencesTaskRepository({SharedPreferences? preferences})
    : _preferences = preferences;

  static const String _keyPrefix = 'auxilia.tasks.v1.';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  String _keyFor(String ownerId) => '$_keyPrefix$ownerId';

  @override
  Future<List<Task>> load(String ownerId) async {
    final raw = (await _prefs).getString(_keyFor(ownerId));
    if (raw == null || raw.isEmpty) return <Task>[];

    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw TaskStorageException('The local task file is not valid JSON');
    }

    if (decoded is! List) {
      throw TaskStorageException(
        'The local task file has an unexpected format',
      );
    }

    final tasks = <Task>[];
    for (final item in decoded) {
      final task = Task.tryFromJson(item);
      if (task != null) tasks.add(task);
    }
    return tasks;
  }

  @override
  Future<void> save(String ownerId, List<Task> tasks) async {
    final encoded = jsonEncode(
      tasks.map((task) => task.toJson()).toList(growable: false),
    );
    final stored = await (await _prefs).setString(_keyFor(ownerId), encoded);
    if (!stored) {
      throw TaskStorageException('Local storage rejected the change');
    }
  }

  @override
  Future<void> clear(String ownerId) async {
    final removed = await (await _prefs).remove(_keyFor(ownerId));
    if (!removed) {
      throw TaskStorageException('Local task data could not be removed');
    }
  }
}

/// In-memory repository used by tests and for ephemeral demos.
class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository({Map<String, List<Task>>? seed}) {
    if (seed != null) {
      seed.forEach((owner, tasks) {
        _data[owner] = List<Task>.of(tasks);
      });
    }
  }

  final Map<String, List<Task>> _data = <String, List<Task>>{};

  bool failOnLoad = false;
  bool failOnSave = false;
  bool failOnClear = false;

  int saveCount = 0;

  @override
  Future<List<Task>> load(String ownerId) async {
    if (failOnLoad) {
      throw TaskStorageException('Simulated read failure');
    }
    return List<Task>.of(_data[ownerId] ?? const <Task>[]);
  }

  @override
  Future<void> save(String ownerId, List<Task> tasks) async {
    saveCount += 1;
    if (failOnSave) {
      throw TaskStorageException('Simulated write failure');
    }
    _data[ownerId] = List<Task>.of(tasks);
  }

  @override
  Future<void> clear(String ownerId) async {
    if (failOnClear) {
      throw TaskStorageException('Simulated clear failure');
    }
    _data.remove(ownerId);
  }
}
