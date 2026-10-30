import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  static const Map<TaskPriority, IconData> _priorityIcons =
      <TaskPriority, IconData>{
        TaskPriority.low: Icons.arrow_downward,
        TaskPriority.medium: Icons.remove,
        TaskPriority.high: Icons.priority_high,
      };

  String get _statusText {
    if (task.isCompleted) return 'Completed';
    if (task.isOverdue) return 'Overdue';
    return 'Pending';
  }

  String get _dueText {
    final dueDate = task.dueDate;
    if (dueDate == null) return 'No due date';
    return 'Due ${formatTaskDate(dueDate)}';
  }

  Color get _priorityColor => switch (task.priority) {
    TaskPriority.low => AuxiliaColors.success,
    TaskPriority.medium => AuxiliaColors.warning,
    TaskPriority.high => AuxiliaColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completed = task.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        container: true,
        label:
            'Task: ${task.title}. ${task.priority.label} priority. $_statusText. $_dueText.',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Semantics(
                  container: true,
                  label: completed
                      ? 'Mark ${task.title} as pending'
                      : 'Mark ${task.title} as complete',
                  toggled: completed,
                  child: Checkbox(
                    value: completed,
                    onChanged: (_) => onToggle(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: completed ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                      if (task.notes.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          task.notes.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          _pill(
                            context,
                            color: _priorityColor,
                            icon: _priorityIcons[task.priority]!,
                            child: Text(
                              '${task.priority.label} priority',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _priorityColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _pill(
                            context,
                            color: task.isOverdue
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                            icon: task.isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.schedule,
                            child: Text(
                              _dueText,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: task.isOverdue ? scheme.error : null,
                              ),
                            ),
                          ),
                          Text(
                            _statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: task.isCompleted
                                  ? AuxiliaColors.success
                                  : task.isOverdue
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (onEdit != null)
                _actionButton(
                  context,
                  tooltip: 'Edit ${task.title}',
                  onPressed: onEdit!,
                  icon: Icons.edit_outlined,
                ),
              if (onDelete != null)
                _actionButton(
                  context,
                  tooltip: 'Delete ${task.title}',
                  onPressed: onDelete!,
                  icon: Icons.delete_outline,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(child: child),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String tooltip,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
