import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/network/lan_network_service.dart';

enum SharingNetworkMode {
  wifiLan,
  offlineHotspot,
}

class HotspotInfo {
  final String ssid;
  final String password;
  final String ipAddress;
  final int port;
  final SharingNetworkMode mode;

  const HotspotInfo({
    required this.ssid,
    required this.password,
    required this.ipAddress,
    this.port = 8080,
    this.mode = SharingNetworkMode.offlineHotspot,
  });

  bool get isLanMode => mode == SharingNetworkMode.wifiLan;

  /// Standard Wi-Fi quick connect format recognizable by Android & iOS cameras
  /// Only applies when broadcasting an offline Wi-Fi hotspot
  String? get wifiQrPayload =>
      isLanMode ? null : 'WIFI:T:WPA;S:$ssid;P:$password;;';

  /// Direct browser download portal URL
  String get webPortalUrl => 'http://$ipAddress:$port';

  HotspotInfo copyWith({
    String? ssid,
    String? password,
    String? ipAddress,
    int? port,
    SharingNetworkMode? mode,
  }) {
    return HotspotInfo(
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      mode: mode ?? this.mode,
    );
  }
}

class HotspotService {
  static const MethodChannel _channel =
      MethodChannel('com.r.permission/hotspot_manager');

  /// Starts sharing over the current Wi-Fi LAN without creating a hotspot.
  /// Works across Android, Windows, macOS, Linux, and Web.
  Future<HotspotInfo> startLanSharing({int port = 8080}) async {
    final ip = await LanNetworkService.getPrimaryIp();
    return HotspotInfo(
      ssid: 'Local Wi-Fi Network',
      password: '',
      ipAddress: ip,
      port: port,
      mode: SharingNetworkMode.wifiLan,
    );
  }

  /// Starts the Android LocalOnlyHotspot or returns simulated data on desktop/web
  Future<HotspotInfo> startHotspot({int port = 8080}) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final result =
            await _channel.invokeMapMethod<String, dynamic>('startHotspot');
        if (result != null) {
          final ssid = result['ssid'] as String? ?? 'DirectShare-AP';
          final password = result['password'] as String? ?? '';
          final ip = result['ipAddress'] as String? ?? '192.168.43.1';
          return HotspotInfo(
            ssid: ssid,
            password: password,
            ipAddress: ip,
            port: port,
            mode: SharingNetworkMode.offlineHotspot,
          );
        }
      } catch (e) {
        debugPrint('HotspotService start error: $e');
        rethrow;
      }
    }

    // Desktop / Web simulation for development preview
    final simulatedIp = await LanNetworkService.getPrimaryIp();
    return HotspotInfo(
      ssid: 'DIRECT-xy-DirectShare',
      password: 'share${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      ipAddress: simulatedIp,
      port: port,
      mode: SharingNetworkMode.offlineHotspot,
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
