import 'package:flutter/foundation.dart';

import '../models/task.dart';
import 'gamification.dart';
import 'task_repository.dart';
import 'task_validation.dart';

enum TaskFilter { all, pending, overdue, completed }

class TaskStore extends ChangeNotifier {
  TaskStore({
    required this.repository,
    required this.ownerId,
    this.pageSize = 20,
  });

  final TaskRepository repository;
  final String ownerId;
  final int pageSize;

  List<Task> _tasks = <Task>[];
  bool _loading = false;
  bool _hasLoaded = false;
  String? _error;
  TaskFilter _filter = TaskFilter.all;
  String _query = '';
  int _page = 0;

  bool get isLoading => _loading;

  bool get hasLoaded => _hasLoaded;

  String? get error => _error;

  TaskFilter get filter => _filter;

  String get query => _query;

  int get page => _page;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);

  int get pendingCount =>
      _tasks.where((task) => task.status == TaskStatus.pending).length;

  int get completedCount => _tasks.length - pendingCount;

  int get overdueCount => _tasks.where((task) => task.isOverdue).length;

  int get dueTodayCount => _tasks.where(_isDueToday).length;

  int get completedThisWeek => _tasks.where((task) {
    final completedAt = task.completedAt;
    if (!task.isCompleted || completedAt == null) return false;
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return !completedAt.isBefore(startOfWeek);
  }).length;

  int get totalXp => Gamification.totalXp(_tasks);

  LevelProgress get levelProgress => Gamification.progressFor(_tasks);

  List<Achievement> get achievements => Gamification.achievementsFor(_tasks);

  List<Task> get filteredTasks {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = _tasks
        .where((task) {
          switch (_filter) {
            case TaskFilter.pending:
              if (task.isCompleted) return false;
            case TaskFilter.overdue:
              if (task.isCompleted || !task.isOverdue) return false;
            case TaskFilter.completed:
              if (!task.isCompleted) return false;
            case TaskFilter.all:
              break;
          }
          if (normalizedQuery.isEmpty) return true;
          return task.title.toLowerCase().contains(normalizedQuery) ||
              task.notes.toLowerCase().contains(normalizedQuery) ||
              task.course.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    filtered.sort(_compare);
    return filtered;
  }

  List<Task> get visibleTasks {
    final filtered = filteredTasks;
    final start = (_page * pageSize).clamp(0, filtered.length);
    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get filteredCount => filteredTasks.length;

  int get pageCount {
    final count = filteredTasks.length;
    if (count == 0) return 1;
    return ((count - 1) ~/ pageSize) + 1;
  }

  bool get canGoToPreviousPage => _page > 0;

  bool get canGoToNextPage => _page + 1 < pageCount;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final loaded = await repository.load(ownerId);
      _tasks = loaded;
      _hasLoaded = true;
      _clampPage();
    } on TaskStorageException catch (err) {
      _error =
          '${err.message}. Existing tasks may not be available until storage is readable.';
    } catch (_) {
      _error = 'Could not load your tasks from this device.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => load();

  Future<bool> addTask(TaskDraft draft) async {
    validateDraft(draft);
    final task = Task.create(
      title: draft.title,
      notes: draft.notes,
      course: draft.course,
      priority: draft.priority,
      dueDate: draft.dueDate,
      reminderAt: draft.reminderAt,
    );
    return _commit(<Task>[..._tasks, task]);
  }

  Future<bool> updateTask(String id, TaskDraft draft) async {
    validateDraft(draft);
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) {
      _error = 'That task no longer exists.';
      notifyListeners();
      return false;
    }

    final updated = _tasks[index].copyWith(
      title: draft.title.trim(),
      notes: draft.notes.trim(),
      course: draft.course.trim(),
      priority: draft.priority,
      dueDate: draft.dueDate,
      reminderAt: draft.reminderAt,
      updatedAt: DateTime.now(),
    );

    final next = List<Task>.of(_tasks);
    next[index] = updated;
    return _commit(next);
  }

  Future<bool> toggleCompletion(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return false;

    final task = _tasks[index];
    final now = DateTime.now();
    final updated = task.isCompleted
        ? task.copyWith(
            status: TaskStatus.pending,
            completedAt: null,
            updatedAt: now,
          )
        : task.copyWith(
            status: TaskStatus.completed,
            completedAt: now,
            xpAwarded: true,
            updatedAt: now,
          );

    final next = List<Task>.of(_tasks);
    next[index] = updated;
    return _commit(next);
  }

  Future<bool> deleteTask(String id) async {
    final next = _tasks.where((task) => task.id != id).toList(growable: false);
    if (next.length == _tasks.length) return false;
    return _commit(next);
  }

  /// Restores a previously deleted task, keeping its original identifier,
  /// timestamps and earned XP so undo is lossless.
  Future<bool> restoreTask(Task task) async {
    if (_tasks.any((existing) => existing.id == task.id)) return false;
    return _commit(<Task>[..._tasks, task]);
  }

  Future<bool> clearAll() async {
    try {
      await repository.clear(ownerId);
    } catch (_) {
      _error = 'Could not remove local task data. Please try again.';
      notifyListeners();
      return false;
    }

    _tasks = <Task>[];
    _error = null;
    _page = 0;
    notifyListeners();
    return true;
  }

  void setFilter(TaskFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    _page = 0;
    notifyListeners();
  }

  void setQuery(String query) {
    if (_query == query) return;
    _query = query;
    _page = 0;
    notifyListeners();
  }

  void nextPage() {
    if (!canGoToNextPage) return;
    _page += 1;
    notifyListeners();
  }

  void previousPage() {
    if (!canGoToPreviousPage) return;
    _page -= 1;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> _commit(List<Task> next) async {
    try {
      await repository.save(ownerId, next);
    } catch (err) {
      _error = err is TaskStorageException
          ? '${err.message}. Your previous task state was kept.'
          : 'Could not save your changes. Your previous task state was kept.';
      notifyListeners();
      return false;
    }

    _tasks = next;
    _error = null;
    _clampPage();
    notifyListeners();
    return true;
  }

  void _clampPage() {
    final maxPage = pageCount - 1;
    if (_page > maxPage) _page = maxPage < 0 ? 0 : maxPage;
  }

  bool _isDueToday(Task task) {
    final dueDate = task.dueDate;
    if (task.isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  int _compare(Task a, Task b) {
    if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;

    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue != null && bDue != null && !aDue.isAtSameMomentAs(bDue)) {
      return aDue.compareTo(bDue);
    }
    if (aDue != null && bDue == null) return -1;
    if (aDue == null && bDue != null) return 1;

    final priority = b.priority.index.compareTo(a.priority.index);
    if (priority != 0) return priority;

    return b.createdAt.compareTo(a.createdAt);
  }
}
