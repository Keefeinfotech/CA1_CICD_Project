import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_validation.dart';
import '../utils/formatters.dart';

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.initial});

  final Task? initial;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(
    text: widget.initial?.title ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.initial?.notes ?? '',
  );
  late final TextEditingController _course = TextEditingController(
    text: widget.initial?.course ?? '',
  );
  late TaskPriority _priority = widget.initial?.priority ?? TaskPriority.medium;
  late DateTime? _dueDate = widget.initial?.dueDate;
  late DateTime? _reminderAt = widget.initial?.reminderAt;
  String? _scheduleError;

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _course.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _setDueDate() async {
    final picked = await _pickDateTime(
      _dueDate ?? DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _dueDate = picked;
      _scheduleError = null;
    });
  }

  Future<void> _setReminder() async {
    final picked = await _pickDateTime(
      _reminderAt ?? _dueDate ?? DateTime.now().add(const Duration(hours: 1)),
    );
    if (picked == null) return;
    setState(() {
      _reminderAt = picked;
      _scheduleError = null;
    });
  }

  void _save() {
    final draft = TaskDraft(
      title: _title.text.trim(),
      notes: _notes.text.trim(),
      course: _course.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      reminderAt: _reminderAt,
    );

    final titleError = validateTitle(draft.title);
    if (titleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(titleError)),
      );
      return;
    }

    final notesError = validateNotes(draft.notes);
    if (notesError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notesError)),
      );
      return;
    }

    final courseError = validateCourse(draft.course);
    if (courseError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(courseError)),
      );
      return;
    }

    final scheduleError = validateSchedule(
      dueDate: _dueDate,
      reminderAt: _reminderAt,
    );
    if (scheduleError != null) {
      setState(() => _scheduleError = scheduleError);
      return;
    }

    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit task' : 'New task',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _title,
                autofocus: !_isEditing,
                maxLength: maxTitleLength,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What needs to be done?',
                ),
                validator: validateTitle,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _course,
                maxLength: maxCourseLength,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Course or subject (optional)',
                  hintText: 'e.g. COMP 2101',
                  counterText: '',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: validateCourse,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _notes,
                maxLength: maxNotesLength,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
                validator: validateNotes,
              ),
              const SizedBox(height: 12),
              Text('Priority', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: TaskPriority.values
                    .map(
                      (priority) => ButtonSegment<TaskPriority>(
                        value: priority,
                        label: Text(priority.label),
                      ),
                    )
                    .toList(growable: false),
                selected: <TaskPriority>{_priority},
                onSelectionChanged: (selection) {
                  setState(() => _priority = selection.first);
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _setDueDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _dueDate == null
                          ? 'Set due date'
                          : 'Due ${formatTaskDate(_dueDate!)}',
                    ),
                  ),
                  if (_dueDate != null)
                    IconButton(
                      tooltip: 'Clear due date',
                      onPressed: () => setState(() {
                        _dueDate = null;
                        _scheduleError = null;
                      }),
                      icon: const Icon(Icons.event_busy),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _setReminder,
                    icon: const Icon(Icons.notifications_outlined),
                    label: Text(
                      _reminderAt == null
                          ? 'Set reminder'
                          : 'Remind ${formatTaskDate(_reminderAt!)}',
                    ),
                  ),
                  if (_reminderAt != null)
                    IconButton(
                      tooltip: 'Clear reminder',
                      onPressed: () => setState(() {
                        _reminderAt = null;
                        _scheduleError = null;
                      }),
                      icon: const Icon(Icons.notifications_off_outlined),
                    ),
                ],
              ),
              if (_scheduleError != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _scheduleError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: Text(_isEditing ? 'Save changes' : 'Create task'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
