import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/session_store.dart';
import 'package:frontend/services/task_repository.dart';
import 'package:frontend/services/task_store.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService(this.restored);

  final Session? restored;

  @override
  Future<Session?> restore() async => restored;
}

void main() {
  testWidgets('restores a saved session straight into the dashboard', (
    tester,
  ) async {
    const session = Session(
      token: 'token',
      email: 'student@example.com',
      name: 'Sam',
    );
    final store = TaskStore(
      repository: InMemoryTaskRepository(),
      ownerId: session.email,
    );
    addTearDown(store.dispose);

    await tester.pumpWidget(
      AuxiliaApp(auth: _FakeAuthService(session), store: store),
    );
    await tester.pumpAndSettle();

    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Open my tasks'), findsNothing);
  });

  testWidgets('falls back to the welcome screen without a session', (
    tester,
  ) async {
    await tester.pumpWidget(AuxiliaApp(auth: _FakeAuthService(null)));
    await tester.pumpAndSettle();

    expect(find.text('Open my tasks'), findsOneWidget);
    expect(find.text('WELCOME BACK'), findsNothing);
  });
}
