import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/task.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/services/task_repository.dart';
import 'package:frontend/services/task_store.dart';

import '../helpers.dart';

Future<TaskStore> pumpHome(
  WidgetTester tester, {
  List<Task> seed = const <Task>[],
  bool failOnLoad = false,
  int pageSize = 20,
  double textScale = 1,
}) async {
  final repository = InMemoryTaskRepository(
    seed: <String, List<Task>>{'owner': seed},
  )..failOnLoad = failOnLoad;
  final store = TaskStore(
    repository: repository,
    ownerId: 'owner',
    pageSize: pageSize,
  );

  await tester.pumpWidget(
    wrapApp(
      HomeScreen(ownerId: 'owner', store: store),
      textScaler: textScale == 1 ? null : TextScaler.linear(textScale),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('shows an empty state that explains what to do', (tester) async {
    await pumpHome(tester);

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Create your first task'), findsOneWidget);
    expect(find.text('0 XP · 0 of 0 complete'), findsOneWidget);
  });

  testWidgets('creates a task through the editor', (tester) async {
    final store = await pumpHome(tester);

    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Buy milk');
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();

    expect(store.tasks, hasLength(1));
    expect(store.tasks.single.title, 'Buy milk');
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.textContaining('Task created'), findsOneWidget);
  });

  testWidgets('shows a validation message for a blank title', (tester) async {
    final store = await pumpHome(tester);

    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create task'));
    await tester.pump();

    expect(find.text('Enter a task title'), findsOneWidget);
    expect(store.tasks, isEmpty);
  });

  testWidgets('completes a task and awards XP once', (tester) async {
    final store = await pumpHome(
      tester,
      seed: <Task>[
        makeTask(title: 'Finish assignment', priority: TaskPriority.high),
      ],
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(store.tasks.single.isCompleted, isTrue);
    expect(store.totalXp, 30);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.textContaining('Task completed'), findsOneWidget);
  });

  testWidgets('confirms before deleting a task', (tester) async {
    final store = await pumpHome(
      tester,
      seed: <Task>[makeTask(title: 'Delete me')],
    );

    await tester.tap(find.byTooltip('Delete Delete me'));
    await tester.pumpAndSettle();

    expect(find.text('Delete task?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(store.tasks, isEmpty);
    expect(find.text('Delete me'), findsNothing);
  });

  testWidgets('shows a retryable error when loading fails', (tester) async {
    final store = await pumpHome(tester, failOnLoad: true);

    expect(store.error, isNotNull);
    expect(find.textContaining('Simulated read failure'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('paginates long task lists', (tester) async {
    await pumpHome(
      tester,
      pageSize: 10,
      seed: <Task>[
        for (var i = 0; i < 25; i++) makeTask(id: 'task-$i', title: 'Task $i'),
      ],
    );

    expect(find.text('Page 1 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2 of 3'), findsOneWidget);
  });

  testWidgets('filters tasks by status', (tester) async {
    await pumpHome(
      tester,
      seed: <Task>[
        makeTask(id: '1', title: 'Pending task'),
        makeTask(
          id: '2',
          title: 'Finished task',
          status: TaskStatus.completed,
          xpAwarded: true,
        ),
      ],
    );

    await tester.tap(find.text('To do (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Pending task'), findsOneWidget);
    expect(find.text('Finished task'), findsNothing);
  });

  testWidgets('opens the achievements list', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.emoji_events_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('First step'), findsOneWidget);
    expect(find.text('Locked'), findsWidgets);
  });

  testWidgets('remains usable at 200% text scaling on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await pumpHome(
      tester,
      textScale: 2,
      seed: <Task>[
        makeTask(
          title: 'A very long task title that should wrap rather than overflow',
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 12, 1, 9),
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('A very long task title'), findsOneWidget);
  });
}
