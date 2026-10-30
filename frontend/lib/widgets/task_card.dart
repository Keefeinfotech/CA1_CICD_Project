import 'package:flutter/material.dart';

import '../models/task.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completed = task.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Semantics(
        container: true,
        label:
            'Task: ${task.title}. ${task.priority.label} priority. $_statusText. $_dueText.',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                container: true,
                label: completed
                    ? 'Mark ${task.title} as pending'
                    : 'Mark ${task.title} as complete',
                toggled: completed,
                child: Checkbox(value: completed, onChanged: (_) => onToggle()),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
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
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                _priorityIcons[task.priority],
                                size: 16,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${task.priority.label} priority',
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                task.isOverdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.schedule,
                                size: 16,
                                color: task.isOverdue
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _dueText,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: task.isOverdue ? scheme.error : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: task.isOverdue
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
                IconButton(
                  tooltip: 'Edit ${task.title}',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete ${task.title}',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
