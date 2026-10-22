import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HotspotInfo {
  final String ssid;
  final String password;
  final String ipAddress;
  final int port;

  const HotspotInfo({
    required this.ssid,
    required this.password,
    required this.ipAddress,
    this.port = 8080,
  });

  /// Standard Wi-Fi quick connect format recognizable by Android & iOS cameras
  String get wifiQrPayload => 'WIFI:T:WPA;S:$ssid;P:$password;;';

  /// Direct browser download portal URL
  String get webPortalUrl => 'http://$ipAddress:$port';

  HotspotInfo copyWith({
    String? ssid,
    String? password,
    String? ipAddress,
    int? port,
  }) {
    return HotspotInfo(
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
    );
  }
}

class HotspotService {
  static const MethodChannel _channel =
      MethodChannel('com.r.permission/hotspot_manager');

  /// Starts the Android LocalOnlyHotspot or returns simulated data on desktop
  Future<HotspotInfo> startHotspot({int port = 8080}) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result = await _channel.invokeMapMethod<String, dynamic>('startHotspot');
        if (result != null) {
          final ssid = result['ssid'] as String? ?? 'DirectShare-AP';
          final password = result['password'] as String? ?? '';
          final ip = result['ipAddress'] as String? ?? '192.168.43.1';
          return HotspotInfo(
            ssid: ssid,
            password: password,
            ipAddress: ip,
            port: port,
          );
        }
      } catch (e) {
        debugPrint('HotspotService start error: $e');
        rethrow;
      }
    }

    // Desktop / Web simulation for development preview
    return HotspotInfo(
      ssid: 'DIRECT-xy-DirectShare',
      password: 'share${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      ipAddress: '192.168.43.1',
      port: port,
    );
  }

  /// Stops the active Android LocalOnlyHotspot
  Future<void> stopHotspot() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<bool>('stopHotspot');
      } catch (e) {
        debugPrint('HotspotService stop error: $e');
      }
    }
  }

  /// Checks if hotspot is actively running
  Future<bool> isHotspotActive() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final active = await _channel.invokeMethod<bool>('getHotspotStatus');
        return active ?? false;
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}
