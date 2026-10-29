import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/task.dart';
import 'package:frontend/services/task_repository.dart';
import 'package:frontend/services/task_store.dart';
import 'package:frontend/services/task_validation.dart';

import '../helpers.dart';

TaskStore buildStore(InMemoryTaskRepository repository, {int pageSize = 20}) {
  return TaskStore(
    repository: repository,
    ownerId: 'owner',
    pageSize: pageSize,
  );
}

void main() {
  group('loading', () {
    test('loads persisted tasks', () async {
      final repository = InMemoryTaskRepository(
        seed: <String, List<Task>>{
          'owner': <Task>[makeTask(title: 'Existing')],
        },
      );
      final store = buildStore(repository);

      await store.load();

      expect(store.hasLoaded, isTrue);
      expect(store.isLoading, isFalse);
      expect(store.tasks.single.title, 'Existing');
    });

    test('reports a readable error when storage cannot be read', () async {
      final repository = InMemoryTaskRepository()..failOnLoad = true;
      final store = buildStore(repository);

      await store.load();

      expect(store.error, contains('Simulated read failure'));
      expect(store.tasks, isEmpty);
    });
  });

  group('writes', () {
    test('adds and persists a task', () async {
      final repository = InMemoryTaskRepository();
      final store = buildStore(repository);
      await store.load();

      final saved = await store.addTask(const TaskDraft(title: '  New task  '));

      expect(saved, isTrue);
      expect(store.tasks.single.title, 'New task');
      expect(repository.saveCount, 1);
    });

    test('rejects a blank title without writing', () async {
      final repository = InMemoryTaskRepository();
      final store = buildStore(repository);
      await store.load();

      await expectLater(
        store.addTask(const TaskDraft(title: '   ')),
        throwsA(isA<TaskValidationException>()),
      );
      expect(repository.saveCount, 0);
      expect(store.tasks, isEmpty);
    });

    test('updates a task and preserves earned XP', () async {
      final repository = InMemoryTaskRepository();
      final store = buildStore(repository);
      await store.load();

      await store.addTask(
        const TaskDraft(title: 'Original', priority: TaskPriority.high),
      );
      final original = store.tasks.single;
      await store.toggleCompletion(original.id);

      final saved = await store.updateTask(
        original.id,
        const TaskDraft(title: 'Renamed', priority: TaskPriority.high),
      );

      expect(saved, isTrue);
      expect(store.tasks.single.title, 'Renamed');
      expect(store.tasks.single.isCompleted, isTrue);
      expect(store.totalXp, 30);
    });

    test('keeps the previous state when a write fails', () async {
      final repository = InMemoryTaskRepository();
      final store = buildStore(repository);
      await store.load();
      await store.addTask(const TaskDraft(title: 'Kept'));

      repository.failOnSave = true;
      final saved = await store.addTask(const TaskDraft(title: 'Lost'));

      expect(saved, isFalse);
      expect(store.tasks, hasLength(1));
      expect(store.tasks.single.title, 'Kept');
      expect(store.error, contains('previous task state was kept'));
    });
  });

  group('completion and XP', () {
    test('does not award XP twice for repeated completion', () async {
      final repository = InMemoryTaskRepository();
      final store = buildStore(repository);
      await store.load();
      await store.addTask(
        const TaskDraft(title: 'High', priority: TaskPriority.high),
      );
      final id = store.tasks.single.id;

      await store.toggleCompletion(id);
      expect(store.tasks.single.isCompleted, isTrue);
      expect(store.totalXp, 30);

      await store.toggleCompletion(id);
      expect(store.tasks.single.isCompleted, isFalse);
      expect(store.totalXp, 30);

      await store.toggleCompletion(id);
      expect(store.tasks.single.isCompleted, isTrue);
      expect(store.totalXp, 30);
    });

    test('derives level and achievements from persisted state', () async {
      final repository = InMemoryTaskRepository();
      final store = buildStore(repository);
      await store.load();

      for (var i = 0; i < 5; i++) {
        await store.addTask(
          const TaskDraft(title: 'Task', priority: TaskPriority.high),
        );
        await store.toggleCompletion(store.tasks.last.id);
      }

      expect(store.totalXp, 150);
      expect(store.levelProgress.level, 2);
      expect(
        store.achievements
            .firstWhere((achievement) => achievement.id == 'five_done')
            .unlocked,
        isTrue,
      );
    });
  });

  group('filtering and pagination', () {
    test('paginates large lists instead of exposing everything', () async {
      final repository = InMemoryTaskRepository(
        seed: <String, List<Task>>{
          'owner': <Task>[
            for (var i = 0; i < 25; i++)
              makeTask(id: 'task-$i', title: 'Task $i'),
          ],
        },
      );
      final store = buildStore(repository, pageSize: 10);
      await store.load();

      expect(store.pageCount, 3);
      expect(store.visibleTasks, hasLength(10));
      expect(store.canGoToNextPage, isTrue);

      store.nextPage();
      expect(store.page, 1);
      expect(store.visibleTasks, hasLength(10));

      store.nextPage();
      expect(store.page, 2);
      expect(store.visibleTasks, hasLength(5));
      expect(store.canGoToNextPage, isFalse);
    });

    test('filters by status', () async {
      final repository = InMemoryTaskRepository(
        seed: <String, List<Task>>{
          'owner': <Task>[
            makeTask(id: '1'),
            makeTask(id: '2'),
            makeTask(id: '3', status: TaskStatus.completed),
          ],
        },
      );
      final store = buildStore(repository);
      await store.load();

      store.setFilter(TaskFilter.pending);
      expect(store.filteredCount, 2);

      store.setFilter(TaskFilter.completed);
      expect(store.filteredCount, 1);
    });

    test('searches titles and notes', () async {
      final repository = InMemoryTaskRepository(
        seed: <String, List<Task>>{
          'owner': <Task>[
            makeTask(id: '1', title: 'Buy milk'),
            makeTask(id: '2', title: 'Write report', notes: 'milk budget'),
            makeTask(id: '3', title: 'Call mum'),
          ],
        },
      );
      final store = buildStore(repository);
      await store.load();

      store.setQuery('MILK');
      expect(store.filteredCount, 2);
    });
  });

  group('deletion', () {
    test('deletes a single task', () async {
      final repository = InMemoryTaskRepository(
        seed: <String, List<Task>>{
          'owner': <Task>[makeTask(id: '1')],
        },
      );
      final store = buildStore(repository);
      await store.load();

      expect(await store.deleteTask('1'), isTrue);
      expect(store.tasks, isEmpty);
      expect(await repository.load('owner'), isEmpty);
    });

    test('clears all local data for the owner', () async {
      final repository = InMemoryTaskRepository(
        seed: <String, List<Task>>{
          'owner': <Task>[makeTask(id: '1'), makeTask(id: '2')],
        },
      );
      final store = buildStore(repository);
      await store.load();

      expect(await store.clearAll(), isTrue);
      expect(store.tasks, isEmpty);
      expect(await repository.load('owner'), isEmpty);
    });

    test('reports a failed clear without pretending success', () async {
      final repository = InMemoryTaskRepository(
        seed: <String, List<Task>>{
          'owner': <Task>[makeTask(id: '1')],
        },
      )..failOnClear = true;
      final store = buildStore(repository);
      await store.load();

      expect(await store.clearAll(), isFalse);
      expect(store.tasks, hasLength(1));
      expect(store.error, isNotNull);
    });
  });
}
