import 'package:flutter/material.dart';

import 'package:frontend/models/task.dart';

Task makeTask({
  String id = 'task-1',
  String title = 'Write report',
  String notes = '',
  TaskPriority priority = TaskPriority.medium,
  TaskStatus status = TaskStatus.pending,
  DateTime? dueDate,
  DateTime? reminderAt,
  DateTime? completedAt,
  bool xpAwarded = false,
}) {
  return Task(
    id: id,
    title: title,
    notes: notes,
    priority: priority,
    status: status,
    dueDate: dueDate,
    reminderAt: reminderAt,
    createdAt: DateTime(2026, 1, 1, 9),
    updatedAt: DateTime(2026, 1, 1, 9),
    completedAt: completedAt,
    xpAwarded: xpAwarded,
  );
}

Widget wrapApp(Widget child, {TextScaler? textScaler}) {
  return MaterialApp(
    home: child,
    builder: textScaler == null
        ? null
        : (context, widget) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(textScaler: textScaler),
              child: widget ?? const SizedBox.shrink(),
            );
          },
  );
}
