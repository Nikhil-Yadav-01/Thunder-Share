import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission/data/hotspot/services/embedded_transfer_server.dart';
import 'package:permission/data/hotspot/services/hotspot_service.dart';
import 'package:permission/domain/apps/entities/device_app_info.dart';
import 'package:permission/presentation/features/hotspot/pages/hotspot_receiver_screen.dart';

void main() {
  test('HotspotInfo formats Wi-Fi QR payload and Web Portal URL correctly', () {
    const info = HotspotInfo(
      ssid: 'DIRECT-MyPhone',
      password: 'mypassword123',
      ipAddress: '192.168.43.1',
      port: 8080,
    );

    expect(info.wifiQrPayload, 'WIFI:T:WPA;S:DIRECT-MyPhone;P:mypassword123;;');
    expect(info.webPortalUrl, 'http://192.168.43.1:8080');
  });

  test('EmbeddedTransferServer starts and serves /api/apps JSON and / Web Portal', () async {
    final server = EmbeddedTransferServer();
    final apps = [
      const DeviceAppInfo(
        name: 'Test App',
        packageName: 'com.example.test',
        versionName: '1.0.0',
        versionCode: 1,
        apkFilePath: '',
        apkSizeBytes: 1048576,
        installedTimestamp: 0,
        updatedTimestamp: 0,
        minSdk: 21,
        targetSdk: 34,
        isSystemApp: false,
      ),
    ];

    final port = await server.start(apps: apps, port: 0);
    expect(server.isRunning, isTrue);

    final client = HttpClient();

    // Test Web Portal HTML
    final webReq = await client.getUrl(Uri.parse('http://127.0.0.1:$port/'));
    final webRes = await webReq.close();
    expect(webRes.statusCode, 200);
    expect(webRes.headers.contentType?.mimeType, 'text/html');
    final html = await webRes.transform(utf8.decoder).join();
    expect(html, contains('DirectShare Portal'));
    expect(html, contains('Test App'));

    // Test /api/apps JSON
    final apiReq = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/apps'));
    final apiRes = await apiReq.close();
    expect(apiRes.statusCode, 200);
    expect(apiRes.headers.contentType?.mimeType, 'application/json');
    final jsonStr = await apiRes.transform(utf8.decoder).join();
    final List<dynamic> list = jsonDecode(jsonStr);
    expect(list.length, 1);
    expect(list[0]['packageName'], 'com.example.test');

    await server.stop();
    expect(server.isRunning, isFalse);
  });

  testWidgets('HotspotReceiverScreen renders instructions and server input',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HotspotReceiverScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Receive via Hotspot'), findsOneWidget);
    expect(find.text('How to connect & receive'), findsOneWidget);
    expect(find.text('Sender Server Address'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });
}
