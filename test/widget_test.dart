import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission/main.dart';

void main() {
  testWidgets('Permission screen renders all permission cards smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PermissionMasteryApp(),
      ),
    );

    await tester.pump();

    // Verify AppBar title
    expect(find.text('Permission Manager'), findsOneWidget);

    // Verify all 3 permission titles are present
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);

    // Verify request buttons
    expect(find.text('Request Camera'), findsOneWidget);
    expect(find.text('Request Microphone'), findsOneWidget);
    expect(find.text('Request Location'), findsOneWidget);
  });
}
