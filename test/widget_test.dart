import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission/main.dart';

void main() {
  testWidgets('Permission screen renders with 8 tabs and permission cards',
      (WidgetTester tester) async {
    // Set larger screen size so tabs and cards render cleanly
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: PermissionMasteryApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('Permission Manager'), findsOneWidget);

    // Verify category tabs exist
    expect(find.text('All (30)'), findsOneWidget);
    expect(find.text('Bluetooth & Network'), findsOneWidget);
    expect(find.text('Contacts & Comms'), findsOneWidget);
    expect(find.text('Location & Motion'), findsOneWidget);

    // Verify initial permission card renders
    expect(find.text('Camera'), findsWidgets);

    // Switch to Photos & Media tab
    await tester.tap(find.text('Photos & Media'));
    await tester.pumpAndSettle();

    // Verify Photos & Media permissions
    expect(find.text('Photos / Gallery'), findsWidgets);
    expect(find.text('Videos'), findsWidgets);

    // Switch to Files & Storage tab
    await tester.tap(find.text('Files & Storage'));
    await tester.pumpAndSettle();

    // Verify Files & Storage permissions
    expect(find.text('Manage All Files'), findsWidgets);
  });
}
