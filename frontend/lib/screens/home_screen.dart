import 'package:flutter/material.dart';

import '../models/task.dart';
import '../routing/app_router.dart';
import '../services/auth_service.dart';
import '../services/gamification.dart';
import '../services/session_store.dart';
import '../services/task_repository.dart';
import '../services/task_store.dart';
import '../services/task_validation.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/task_editor.dart';

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

  void _showSnack(String message, {SnackBarAction? action}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: action == null
            ? const Duration(seconds: 4)
            : const Duration(seconds: 6),
      ),
    );
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
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final restored = await _store.toggleCompletion(task.id);
            if (!mounted) return;
            _showSnack(
              restored
                  ? 'Completion undone. Earned XP is kept.'
                  : _store.error ?? 'Could not undo the change.',
            );
          },
        ),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be removed from this device.'),
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
    if (!saved) {
      _showSnack(_store.error ?? 'Could not delete the task.');
      return;
    }
    _showSnack(
      'Task deleted.',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          final restored = await _store.restoreTask(task);
          if (!mounted) return;
          _showSnack(
            restored
                ? 'Task restored.'
                : _store.error ?? 'Could not restore the task.',
          );
        },
      ),
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
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
  }

  void _openAssistant() {
    final session = widget.session;
    if (session == null) {
      _showSnack('Sign in to use the AI assistant.');
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.assistant,
      arguments: AssistantArgs(session: session),
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
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _hero(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _searchField(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _filters(context),
          ),
          if (_store.pageCount > 1) _pagination(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: _listHeading(context),
          ),
          if (_store.error != null) _errorBanner(_store.error!),
          ..._taskSection(context),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _store.levelProgress;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: AuxiliaColors.brandGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AuxiliaColors.indigo.withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _levelBadge(progress.level),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'WELCOME BACK',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.displayName ?? 'My workspace',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.totalXp} XP · '
                      '${_store.completedCount} of ${_store.tasks.length} complete',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              _headerIconButton(
                tooltip: 'Achievements',
                icon: Icons.emoji_events_outlined,
                onPressed: _showAchievements,
              ),
              const SizedBox(width: 6),
              _headerMenu(),
            ],
          ),
          const SizedBox(height: 18),
          Semantics(
            label:
                'Level ${progress.level}. ${progress.xpIntoLevel} of '
                '${progress.xpForNextLevel} XP earned toward the next level.',
            child: Column(
              children: <Widget>[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: <Widget>[
                    Text(
                      'Level ${progress.level}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${progress.xpIntoLevel} / ${progress.xpForNextLevel} XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _statTile('To do', '${_store.pendingCount}'),
                const SizedBox(width: 8),
                _statTile('Due today', '${_store.dueTodayCount}'),
                const SizedBox(width: 8),
                _statTile('Overdue', '${_store.overdueCount}'),
                const SizedBox(width: 8),
                _statTile('Done', '${_store.completedCount}'),
                const SizedBox(width: 8),
                _statTile('This week', '${_store.completedThisWeek}'),
                const SizedBox(width: 8),
                _statTile('Total XP', '${progress.totalXp}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelBadge(int level) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        'L$level',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.14),
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _headerMenu() {
    return PopupMenuButton<String>(
      tooltip: 'More options',
      onSelected: (value) {
        switch (value) {
          case 'achievements':
            _showAchievements();
          case 'assistant':
            _openAssistant();
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
          value: 'assistant',
          child: Text('AI assistant'),
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
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: _store.setQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search tasks',
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
    );
  }

  Widget _filters(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _filterChip(context, TaskFilter.all, 'All (${_store.tasks.length})'),
        _filterChip(
          context,
          TaskFilter.pending,
          'To do (${_store.pendingCount})',
        ),
        if (_store.overdueCount > 0)
          _filterChip(
            context,
            TaskFilter.overdue,
            'Overdue (${_store.overdueCount})',
          ),
        _filterChip(
          context,
          TaskFilter.completed,
          'Done (${_store.completedCount})',
        ),
      ],
    );
  }

  Widget _filterChip(BuildContext context, TaskFilter filter, String label) {
    final scheme = Theme.of(context).colorScheme;
    final bool selected = _store.filter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => _store.setFilter(filter),
      labelStyle: TextStyle(
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 13,
      ),
      selectedColor: scheme.primary.withValues(alpha: 0.12),
      backgroundColor: scheme.surface,
      side: BorderSide(
        color: selected
            ? scheme.primary.withValues(alpha: 0.4)
            : scheme.outlineVariant,
      ),
      shape: const StadiumBorder(),
    );
  }

  Widget _listHeading(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Your tasks',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_store.filteredCount} shown',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _taskSection(BuildContext context) {
    if (_store.tasks.isEmpty) {
      return <Widget>[_emptyState(context)];
    }

    if (_store.filteredCount == 0) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No tasks match your search or filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    return _store.visibleTasks
        .map(
          (task) => TaskCard(
            task: task,
            onToggle: () => _toggleTask(task),
            onEdit: () => _editTask(task),
            onDelete: () => _deleteTask(task),
          ),
        )
        .toList(growable: false);
  }

  Widget _errorBanner(String message) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
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
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AuxiliaColors.brandGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.checklist_rtl,
                size: 34,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text('No tasks yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Create your first task to start tracking progress and earning XP.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _createTask,
                child: const Text(
                  'Create your first task',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pagination(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              tooltip: 'Previous page',
              onPressed: _store.canGoToPreviousPage
                  ? _store.previousPage
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              'Page ${_store.page + 1} of ${_store.pageCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: _store.canGoToNextPage ? _store.nextPage : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
