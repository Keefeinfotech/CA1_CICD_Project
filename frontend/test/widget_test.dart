import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('welcome screen exposes the main entry points', (tester) async {
    await tester.pumpWidget(const AuxiliaApp());

    expect(find.text('Auxilia'), findsOneWidget);
    expect(find.text('Open my tasks'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Try the AI assistant'), findsOneWidget);
  });

  testWidgets('welcome screen states that tasks work offline', (tester) async {
    await tester.pumpWidget(const AuxiliaApp());

    expect(
      find.textContaining('Tasks are stored on this device'),
      findsOneWidget,
    );
  });
}
