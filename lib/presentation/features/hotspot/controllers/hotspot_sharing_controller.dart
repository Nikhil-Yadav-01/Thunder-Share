import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/hotspot/services/embedded_transfer_server.dart';
import '../../../../data/hotspot/services/hotspot_service.dart';
import '../../../../domain/apps/entities/device_app_info.dart';

enum HotspotStatus { idle, starting, active, error }

class HotspotSharingState {
  final HotspotStatus status;
  final HotspotInfo? hotspotInfo;
  final List<DeviceAppInfo> hostedApps;
  final String? errorMessage;
  final int downloadCount;

  const HotspotSharingState({
    this.status = HotspotStatus.idle,
    this.hotspotInfo,
    this.hostedApps = const [],
    this.errorMessage,
    this.downloadCount = 0,
  });

  bool get isActive => status == HotspotStatus.active;
  bool get isStarting => status == HotspotStatus.starting;

  HotspotSharingState copyWith({
    HotspotStatus? status,
    HotspotInfo? hotspotInfo,
    List<DeviceAppInfo>? hostedApps,
    String? errorMessage,
    int? downloadCount,
  }) {
    return HotspotSharingState(
      status: status ?? this.status,
      hotspotInfo: hotspotInfo ?? this.hotspotInfo,
      hostedApps: hostedApps ?? this.hostedApps,
      errorMessage: errorMessage,
      downloadCount: downloadCount ?? this.downloadCount,
    );
  }
}

final hotspotServiceProvider = Provider<HotspotService>((ref) {
  return HotspotService();
});

final embeddedServerProvider = Provider<EmbeddedTransferServer>((ref) {
  final server = EmbeddedTransferServer();
  ref.onDispose(() => server.stop());
  return server;
});

final hotspotSharingControllerProvider =
    NotifierProvider<HotspotSharingNotifier, HotspotSharingState>(
  HotspotSharingNotifier.new,
);

class HotspotSharingNotifier extends Notifier<HotspotSharingState> {
  HotspotService get _hotspotService => ref.read(hotspotServiceProvider);
  EmbeddedTransferServer get _server => ref.read(embeddedServerProvider);

  @override
  HotspotSharingState build() {
    ref.onDispose(() {
      stopSharing();
    });
    return const HotspotSharingState();
  }

  Future<bool> startSharing({
    required List<DeviceAppInfo> apps,
    Map<String, Uint8List> appIcons = const {},
  }) async {
    if (apps.isEmpty) return false;

    state = state.copyWith(
      status: HotspotStatus.starting,
      hostedApps: apps,
      errorMessage: null,
    );

    try {
      // 1. Start embedded HTTP server
      final port = await _server.start(apps: apps, appIcons: appIcons);

      // 2. Start native Android LocalOnlyHotspot
      final info = await _hotspotService.startHotspot(port: port);

      state = state.copyWith(
        status: HotspotStatus.active,
        hotspotInfo: info,
      );
      return true;
    } catch (e) {
      await _server.stop();
      await _hotspotService.stopHotspot();
      state = state.copyWith(
        status: HotspotStatus.error,
        errorMessage: 'Failed to start hotspot: $e',
      );
      return false;
    }
  }

  Future<void> stopSharing() async {
    await _server.stop();
    await _hotspotService.stopHotspot();
    state = const HotspotSharingState(status: HotspotStatus.idle);
  }
}
