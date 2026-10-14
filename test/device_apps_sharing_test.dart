import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission/presentation/features/apps/pages/device_apps_sharing_screen.dart';

void main() {
  testWidgets('DeviceAppsSharingScreen displays apps, filter chips, and allows searching',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DeviceAppsSharingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Device Apps & Sharing'), findsOneWidget);

    // Verify filter chips
    expect(find.textContaining('All Apps'), findsOneWidget);
    expect(find.textContaining('User Apps'), findsOneWidget);
    expect(find.textContaining('System'), findsOneWidget);

    // Verify mock apps rendered (WhatsApp, Google Chrome)
    expect(find.text('WhatsApp Messenger'), findsOneWidget);
    expect(find.text('Google Chrome'), findsOneWidget);

    // Tap search icon
    await tester.tap(find.byTooltip('Search apps'));
    await tester.pumpAndSettle();

    // Enter search text
    await tester.enterText(find.byType(TextField), 'Spotify');
    await tester.pumpAndSettle();

    expect(find.text('Spotify: Music & Podcasts'), findsOneWidget);
    expect(find.text('WhatsApp Messenger'), findsNothing);

    // Tap the app card to open AppDetailBottomSheet
    await tester.tap(find.text('Spotify: Music & Podcasts'));
    await tester.pumpAndSettle();

    // Verify bottom sheet content
    expect(find.text('App Specifications'), findsOneWidget);
    expect(find.text('Requested Permissions'), findsOneWidget);
    expect(find.text('Share APK'), findsOneWidget);
  });
}
