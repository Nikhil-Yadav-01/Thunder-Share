import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to detect active local IPv4 network addresses across platforms.
/// Enables Wi-Fi LAN sharing without requiring internet access.
class LanNetworkService {
  LanNetworkService._();

  /// Discovers local network IPv4 addresses on Android, Windows, macOS, and Linux
  static Future<List<String>> getLocalIpAddresses() async {
    if (kIsWeb) return ['127.0.0.1'];

    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        // Skip virtual or pseudo adapters if possible
        final name = interface.name.toLowerCase();
        if (name.contains('virtual') || name.contains('vethernet') || name.contains('vmnet')) {
          continue;
        }

        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;
            if (!ips.contains(ip)) {
              ips.add(ip);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('LanNetworkService error discovering IP addresses: $e');
    }

    return ips;
  }

  /// Returns the most appropriate primary local IP address.
  /// Prioritizes standard local subnets (192.168.x.x, 10.x.x.x, 172.16-31.x.x).
  static Future<String> getPrimaryIp({String fallback = '192.168.43.1'}) async {
    if (kIsWeb) return '127.0.0.1';

    final ips = await getLocalIpAddresses();
    if (ips.isEmpty) return fallback;

    // Prefer 192.168.43.1 if acting as Android hotspot
    if (ips.contains('192.168.43.1')) return '192.168.43.1';

    // Prefer standard LAN subnets
    final standardLan = ips.firstWhere(
      (ip) =>
          ip.startsWith('192.168.') ||
          ip.startsWith('10.') ||
          (ip.startsWith('172.') && _isClassBPrivate(ip)),
      orElse: () => ips.first,
    );

    return standardLan;
  }

  static bool _isClassBPrivate(String ip) {
    try {
      final parts = ip.split('.');
      if (parts.length >= 2) {
        final secondOctet = int.tryParse(parts[1]) ?? 0;
        return secondOctet >= 16 && secondOctet <= 31;
      }
    } catch (_) {}
    return false;
  }
}
