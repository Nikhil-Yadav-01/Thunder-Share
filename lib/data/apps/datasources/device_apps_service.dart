import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/apps/entities/device_app_info.dart';

class DeviceAppsService {
  static const MethodChannel _channel =
      MethodChannel('com.r.permission/app_manager');

  /// Fetches installed apps from native Android, or returns mock data on desktop/web
  Future<List<DeviceAppInfo>> getInstalledApps() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result =
            await _channel.invokeListMethod<Map<dynamic, dynamic>>('getInstalledApps');
        if (result == null) return [];
        return result.map((m) => DeviceAppInfo.fromMap(m)).toList();
      } catch (e) {
        debugPrint('DeviceAppsService error: $e');
        return _getMockApps();
      }
    } else {
      // Graceful fallback for Windows/desktop/web development
      return _getMockApps();
    }
  }

  /// Fetches app icon bytes for a specific package
  Future<Uint8List?> getAppIcon(String packageName) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bytes = await _channel.invokeMethod<Uint8List>(
          'getAppIcon',
          {'packageName': packageName},
        );
        return bytes;
      } catch (e) {
        debugPrint('Error getting icon for $packageName: $e');
        return null;
      }
    }
    return null;
  }

  /// Fetches permissions requested by an installed package
  Future<List<String>> getAppPermissions(String packageName) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final list = await _channel.invokeListMethod<String>(
          'getAppPermissions',
          {'packageName': packageName},
        );
        return list ?? [];
      } catch (e) {
        debugPrint('Error getting permissions for $packageName: $e');
        return [];
      }
    } else {
      final mock = _getMockApps().firstWhere(
        (a) => a.packageName == packageName,
        orElse: () => _getMockApps().first,
      );
      return mock.permissions;
    }
  }

  /// Launches an installed app
  Future<bool> launchApp(String packageName) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final success = await _channel.invokeMethod<bool>(
          'launchApp',
          {'packageName': packageName},
        );
        return success ?? false;
      } catch (e) {
        debugPrint('Error launching app: $e');
        return false;
      }
    }
    return false;
  }

  /// Opens the system App Details / Settings page for a package
  Future<bool> openAppSettings(String packageName) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final success = await _channel.invokeMethod<bool>(
          'openAppSettings',
          {'packageName': packageName},
        );
        return success ?? false;
      } catch (e) {
        debugPrint('Error opening app settings: $e');
        return false;
      }
    }
    return false;
  }

  /// Shares one or multiple APK files using native share sheet
  Future<void> shareApks(List<DeviceAppInfo> apps) async {
    if (apps.isEmpty) return;

    final xFiles = <XFile>[];
    for (final app in apps) {
      if (app.apkFilePath.isNotEmpty) {
        final file = File(app.apkFilePath);
        if (file.existsSync()) {
          xFiles.add(XFile(app.apkFilePath, name: '${app.name}.apk'));
        }
      }
    }

    if (xFiles.isNotEmpty) {
      final names = apps.map((a) => a.name).join(', ');
      await SharePlus.instance.share(
        ShareParams(
          files: xFiles,
          subject: 'Sharing App APK: $names',
          text: 'Sharing ${apps.length} app(s): $names',
        ),
      );
    } else {
      // Fallback: Share links if APK files are not directly readable or on desktop
      await shareAppLinks(apps);
    }
  }

  /// Shares Google Play links and app summaries
  Future<void> shareAppLinks(List<DeviceAppInfo> apps) async {
    if (apps.isEmpty) return;

    if (apps.length == 1) {
      final app = apps.first;
      final text = 'Check out "${app.name}" (v${app.versionName}):\n'
          '${app.playStoreUrl}';
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'App Link: ${app.name}',
        ),
      );
    } else {
      final buffer = StringBuffer('Sharing ${apps.length} Recommended Apps:\n\n');
      for (final app in apps) {
        buffer.writeln('• ${app.name} (${app.formattedSize})');
        buffer.writeln('  ${app.playStoreUrl}\n');
      }
      await SharePlus.instance.share(
        ShareParams(
          text: buffer.toString(),
          subject: '${apps.length} Apps Shared',
        ),
      );
    }
  }

  /// Realistic mock applications for testing outside physical Android device
  List<DeviceAppInfo> _getMockApps() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneWeekAgo = now - (7 * 86400 * 1000);
    final oneMonthAgo = now - (30 * 86400 * 1000);

    return [
      DeviceAppInfo(
        name: 'WhatsApp Messenger',
        packageName: 'com.whatsapp',
        versionName: '2.24.18.75',
        versionCode: 241875001,
        apkFilePath: '/data/app/~~wa/com.whatsapp/base.apk',
        apkSizeBytes: 54320000, // ~51.8 MB
        installedTimestamp: oneMonthAgo,
        updatedTimestamp: oneWeekAgo,
        minSdk: 21,
        targetSdk: 34,
        isSystemApp: false,
        permissions: [
          'android.permission.CAMERA',
          'android.permission.RECORD_AUDIO',
          'android.permission.READ_CONTACTS',
          'android.permission.WRITE_CONTACTS',
          'android.permission.READ_MEDIA_IMAGES',
          'android.permission.READ_MEDIA_VIDEO',
          'android.permission.ACCESS_FINE_LOCATION',
          'android.permission.POST_NOTIFICATIONS',
        ],
      ),
      DeviceAppInfo(
        name: 'Google Chrome',
        packageName: 'com.android.chrome',
        versionName: '128.0.6613.88',
        versionCode: 661308802,
        apkFilePath: '/system/app/Chrome/Chrome.apk',
        apkSizeBytes: 135400000, // ~129 MB
        installedTimestamp: oneMonthAgo,
        updatedTimestamp: now - (2 * 86400 * 1000),
        minSdk: 26,
        targetSdk: 34,
        isSystemApp: true,
        permissions: [
          'android.permission.INTERNET',
          'android.permission.ACCESS_FINE_LOCATION',
          'android.permission.CAMERA',
          'android.permission.RECORD_AUDIO',
          'android.permission.POST_NOTIFICATIONS',
        ],
      ),
      DeviceAppInfo(
        name: 'Spotify: Music & Podcasts',
        packageName: 'com.spotify.music',
        versionName: '8.9.68.468',
        versionCode: 104258291,
        apkFilePath: '/data/app/~~sp/com.spotify.music/base.apk',
        apkSizeBytes: 42100000, // ~40.1 MB
        installedTimestamp: oneMonthAgo,
        updatedTimestamp: oneWeekAgo,
        minSdk: 23,
        targetSdk: 34,
        isSystemApp: false,
        permissions: [
          'android.permission.INTERNET',
          'android.permission.RECORD_AUDIO',
          'android.permission.BLUETOOTH_CONNECT',
          'android.permission.POST_NOTIFICATIONS',
          'android.permission.WAKE_LOCK',
        ],
      ),
      DeviceAppInfo(
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        versionName: '19.34.42',
        versionCode: 1544837888,
        apkFilePath: '/system/app/YouTube/YouTube.apk',
        apkSizeBytes: 98400000, // ~93.8 MB
        installedTimestamp: oneMonthAgo,
        updatedTimestamp: now - (3 * 86400 * 1000),
        minSdk: 26,
        targetSdk: 34,
        isSystemApp: true,
        permissions: [
          'android.permission.INTERNET',
          'android.permission.RECORD_AUDIO',
          'android.permission.CAMERA',
          'android.permission.ACCESS_FINE_LOCATION',
          'android.permission.POST_NOTIFICATIONS',
        ],
      ),
      DeviceAppInfo(
        name: 'Telegram',
        packageName: 'org.telegram.messenger',
        versionName: '11.0.0',
        versionCode: 51230,
        apkFilePath: '/data/app/~~tg/org.telegram.messenger/base.apk',
        apkSizeBytes: 71200000, // ~67.9 MB
        installedTimestamp: oneMonthAgo,
        updatedTimestamp: now - (1 * 86400 * 1000),
        minSdk: 21,
        targetSdk: 34,
        isSystemApp: false,
        permissions: [
          'android.permission.CAMERA',
          'android.permission.RECORD_AUDIO',
          'android.permission.READ_CONTACTS',
          'android.permission.ACCESS_FINE_LOCATION',
          'android.permission.POST_NOTIFICATIONS',
          'android.permission.READ_MEDIA_IMAGES',
        ],
      ),
      DeviceAppInfo(
        name: 'Files by Google',
        packageName: 'com.google.android.apps.nbu.files',
        versionName: '1.4582.0',
        versionCode: 649201,
        apkFilePath: '/data/app/~~files/com.google.android.apps.nbu.files/base.apk',
        apkSizeBytes: 18900000, // ~18 MB
        installedTimestamp: oneMonthAgo,
        updatedTimestamp: oneWeekAgo,
        minSdk: 26,
        targetSdk: 34,
        isSystemApp: false,
        permissions: [
          'android.permission.MANAGE_EXTERNAL_STORAGE',
          'android.permission.ACCESS_FINE_LOCATION',
          'android.permission.NEARBY_WIFI_DEVICES',
          'android.permission.BLUETOOTH_CONNECT',
        ],
      ),
      DeviceAppInfo(
        name: 'Android System Settings',
        packageName: 'com.android.settings',
        versionName: '14',
        versionCode: 34,
        apkFilePath: '/system/priv-app/Settings/Settings.apk',
        apkSizeBytes: 31200000, // ~29.7 MB
        installedTimestamp: 0,
        updatedTimestamp: 0,
        minSdk: 34,
        targetSdk: 34,
        isSystemApp: true,
        permissions: [
          'android.permission.WRITE_SETTINGS',
          'android.permission.MANAGE_USERS',
          'android.permission.STATUS_BAR',
        ],
      ),
      DeviceAppInfo(
        name: 'Camera System',
        packageName: 'com.android.camera2',
        versionName: '3.1.043',
        versionCode: 3104300,
        apkFilePath: '/system/priv-app/GoogleCamera/GoogleCamera.apk',
        apkSizeBytes: 62400000, // ~59.5 MB
        installedTimestamp: 0,
        updatedTimestamp: 0,
        minSdk: 28,
        targetSdk: 34,
        isSystemApp: true,
        permissions: [
          'android.permission.CAMERA',
          'android.permission.RECORD_AUDIO',
          'android.permission.ACCESS_FINE_LOCATION',
        ],
      ),
    ];
  }
}
