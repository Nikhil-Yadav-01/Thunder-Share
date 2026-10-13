import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission/main.dart';

void main() {
  testWidgets('Permission screen renders with tabs and permission cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PermissionMasteryApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('Permission Manager'), findsOneWidget);

    // Verify category tabs
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Photos & Media'), findsOneWidget);
    expect(find.text('Apps & System'), findsOneWidget);
    expect(find.text('Hardware'), findsOneWidget);

    // Verify initial Hardware permissions on first page
    expect(find.text('Camera'), findsWidgets);
    expect(find.text('Microphone'), findsWidgets);

    // Switch to Photos & Media tab
    await tester.tap(find.text('Photos & Media'));
    await tester.pumpAndSettle();

    // Verify Photos & Media permissions
    expect(find.text('Photos / Gallery'), findsWidgets);
    expect(find.text('Videos'), findsWidgets);

    // Switch to Apps & System tab
    await tester.tap(find.text('Apps & System'));
    await tester.pumpAndSettle();

    // Verify Apps & System permissions
    expect(find.text('App Tracking Transparency'), findsWidgets);
    expect(find.text('Display Over Other Apps'), findsWidgets);

    // Scroll down in current tab to ensure bottom items render
    await tester.drag(find.text('Display Over Other Apps'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Push Notifications'), findsWidgets);
  });
}

