import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/gamification.dart';
import '../services/session_store.dart';
import '../services/task_repository.dart';
import '../services/task_store.dart';
import '../services/task_validation.dart';
import '../widgets/task_card.dart';
import '../widgets/task_editor.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.ownerId,
    this.displayName,
    this.session,
    this.store,
  });

  final String ownerId;
  final String? displayName;
  final Session? session;
  final TaskStore? store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();
  late final TaskStore _store;
  late final bool _ownsStore;

  @override
  void initState() {
    super.initState();
    _ownsStore = widget.store == null;
    _store =
        widget.store ??
        TaskStore(
          repository: SharedPreferencesTaskRepository(),
          ownerId: widget.ownerId,
        );
    _store.addListener(_handleStoreChanged);
    _store.load();
  }

  @override
  void dispose() {
    _store.removeListener(_handleStoreChanged);
    if (_ownsStore) _store.dispose();
    _search.dispose();
    super.dispose();
  }

  void _handleStoreChanged() {
    if (mounted) setState(() {});
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createTask() async {
    final draft = await showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TaskEditor(),
    );
    if (draft == null || !mounted) return;

    try {
      final saved = await _store.addTask(draft);
      if (!mounted) return;
      _showSnack(
        saved ? 'Task created.' : _store.error ?? 'Could not create the task.',
      );
    } on TaskValidationException catch (err) {
      if (mounted) _showSnack(err.message);
    }
  }

  Future<void> _editTask(Task task) async {
    final draft = await showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TaskEditor(initial: task),
    );
    if (draft == null || !mounted) return;

    try {
      final saved = await _store.updateTask(task.id, draft);
      if (!mounted) return;
      _showSnack(
        saved ? 'Task updated.' : _store.error ?? 'Could not update the task.',
      );
    } on TaskValidationException catch (err) {
      if (mounted) _showSnack(err.message);
    }
  }

  Future<void> _toggleTask(Task task) async {
    final xpGain = !task.isCompleted && !task.xpAwarded
        ? Gamification.xpByPriority[task.priority] ?? 0
        : 0;
    final wasCompleted = task.isCompleted;

    final saved = await _store.toggleCompletion(task.id);
    if (!mounted) return;

    if (!saved) {
      _showSnack(_store.error ?? 'Could not update the task.');
      return;
    }

    if (wasCompleted) {
      _showSnack('Task reopened. Earned XP is kept.');
    } else {
      _showSnack(
        xpGain > 0 ? 'Task completed · +$xpGain XP' : 'Task completed.',
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          '"${task.title}" will be removed from this device. '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final saved = await _store.deleteTask(task.id);
    if (!mounted) return;
    _showSnack(
      saved ? 'Task deleted.' : _store.error ?? 'Could not delete the task.',
    );
  }

  Future<void> _clearAllTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove all local tasks?'),
        content: const Text(
          'Every task stored on this device will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove all'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final cleared = await _store.clearAll();
    if (!mounted) return;
    _showSnack(
      cleared
          ? 'All local tasks were removed.'
          : _store.error ?? 'Could not remove local tasks.',
    );
  }

  Future<void> _signOut() async {
    try {
      await AuthService().logout();
    } on SessionException catch (err) {
      if (mounted) _showSnack(err.message);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openAssistant() {
    final session = widget.session;
    if (session == null) {
      _showSnack('Sign in to use the AI assistant.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => AiChatScreen(session: session)),
    );
  }

  void _showAchievements() {
    final achievements = _store.achievements;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Achievements'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: achievements
                .map(
                  (achievement) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      achievement.unlocked
                          ? Icons.emoji_events
                          : Icons.lock_outline,
                    ),
                    title: Text(achievement.title),
                    subtitle: Text(achievement.description),
                    trailing: Text(
                      achievement.unlocked ? 'Unlocked' : 'Locked',
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _store.levelProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auxilia'),
        actions: <Widget>[
          IconButton(
            tooltip: 'AI assistant',
            onPressed: _openAssistant,
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'achievements':
                  _showAchievements();
                case 'clear':
                  _clearAllTasks();
                case 'signout':
                  _signOut();
              }
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'achievements',
                child: Text('Achievements'),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Text('Remove all local tasks'),
              ),
              if (widget.session != null)
                const PopupMenuItem<String>(
                  value: 'signout',
                  child: Text('Sign out'),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: Column(
        children: <Widget>[
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(child: Text('L${progress.level}')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.displayName ?? 'My tasks',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${progress.totalXp} XP · '
                              '${_store.completedCount} of ${_store.tasks.length} complete',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Achievements',
                        onPressed: _showAchievements,
                        icon: const Icon(Icons.emoji_events_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    label:
                        'Level ${progress.level}. ${progress.xpIntoLevel} of '
                        '${progress.xpForNextLevel} XP earned toward the next level.',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.fraction,
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: _store.setQuery,
              decoration: InputDecoration(
                labelText: 'Search tasks',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _store.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          _store.setQuery('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: <Widget>[
                _filterChip(TaskFilter.all, 'All (${_store.tasks.length})'),
                _filterChip(
                  TaskFilter.pending,
                  'To do (${_store.pendingCount})',
                ),
                _filterChip(
                  TaskFilter.completed,
                  'Done (${_store.completedCount})',
                ),
              ],
            ),
          ),
          if (_store.pageCount > 1) _pagination(),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  Widget _filterChip(TaskFilter filter, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _store.filter == filter,
      onSelected: (_) => _store.setFilter(filter),
    );
  }

  Widget _buildTaskList() {
    if (_store.isLoading && !_store.hasLoaded) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading your tasks...'),
            ],
          ),
        ),
      );
    }

    final children = <Widget>[];

    if (_store.error != null) {
      children.add(_errorBanner(_store.error!));
    }

    if (_store.tasks.isEmpty) {
      children.add(_emptyState());
    } else if (_store.filteredCount == 0) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No tasks match your search or filter.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      children.addAll(
        _store.visibleTasks.map(
          (task) => TaskCard(
            task: task,
            onToggle: () => _toggleTask(task),
            onEdit: () => _editTask(task),
            onDelete: () => _deleteTask(task),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      children: children,
    );
  }

  Widget _errorBanner(String message) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          TextButton(onPressed: _store.retry, child: const Text('Retry')),
          IconButton(
            tooltip: 'Dismiss message',
            onPressed: _store.clearError,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: <Widget>[
          const Icon(Icons.checklist_rtl, size: 64),
          const SizedBox(height: 16),
          Text('No tasks yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Create your first task to start tracking progress and earning XP.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _createTask,
            icon: const Icon(Icons.add),
            label: const Text('Create your first task'),
          ),
        ],
      ),
    );
  }

  Widget _pagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            tooltip: 'Previous page',
            onPressed: _store.canGoToPreviousPage ? _store.previousPage : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page ${_store.page + 1} of ${_store.pageCount}'),
          IconButton(
            tooltip: 'Next page',
            onPressed: _store.canGoToNextPage ? _store.nextPage : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
