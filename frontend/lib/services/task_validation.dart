import '../models/task.dart';

class TaskValidationException implements Exception {
  TaskValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

const int maxTitleLength = 120;
const int maxNotesLength = 2000;

String? validateTitle(String? value) {
  final title = (value ?? '').trim();
  if (title.isEmpty) return 'Enter a task title';
  if (title.length > maxTitleLength) {
    return 'Keep the title under $maxTitleLength characters';
  }
  return null;
}

String? validateNotes(String? value) {
  final notes = (value ?? '').trim();
  if (notes.length > maxNotesLength) {
    return 'Keep notes under $maxNotesLength characters';
  }
  return null;
}

String? validateSchedule({DateTime? dueDate, DateTime? reminderAt}) {
  if (reminderAt != null && dueDate == null) {
    return 'Add a due date before setting a reminder';
  }
  if (reminderAt != null && dueDate != null && reminderAt.isAfter(dueDate)) {
    return 'The reminder must be at or before the due date';
  }
  return null;
}

void validateDraft(TaskDraft draft) {
  final titleError = validateTitle(draft.title);
  if (titleError != null) throw TaskValidationException(titleError);

  final notesError = validateNotes(draft.notes);
  if (notesError != null) throw TaskValidationException(notesError);

  final scheduleError = validateSchedule(
    dueDate: draft.dueDate,
    reminderAt: draft.reminderAt,
  );
  if (scheduleError != null) throw TaskValidationException(scheduleError);
}
