import 'dart:io';

/// Enforces a minimum line-coverage threshold from `coverage/lcov.info`.
///
/// Usage: dart run tool/check_coverage.dart [minimumPercent]
void main(List<String> args) {
  final threshold = args.isEmpty ? 60.0 : double.parse(args.first);
  final report = File('coverage/lcov.info');

  if (!report.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info not found. Run flutter test --coverage.',
    );
    exitCode = 1;
    return;
  }

  var found = 0;
  var hit = 0;
  for (final line in report.readAsLinesSync()) {
    if (line.startsWith('LF:')) found += int.parse(line.substring(3));
    if (line.startsWith('LH:')) hit += int.parse(line.substring(3));
  }

  if (found == 0) {
    stderr.writeln('Coverage report contains no line data.');
    exitCode = 1;
    return;
  }

  final percent = hit / found * 100;
  stdout.writeln(
    'Frontend line coverage: ${percent.toStringAsFixed(1)}% '
    '($hit/$found), gate ${threshold.toStringAsFixed(1)}%',
  );

  if (percent < threshold) {
    stderr.writeln('Coverage gate failed.');
    exitCode = 1;
  }
}
