import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/hotspot/services/embedded_transfer_server.dart';
import '../../../../data/hotspot/services/hotspot_service.dart';
import '../../../../domain/apps/entities/device_app_info.dart';
import '../../../../domain/sharing/entities/share_payload.dart';

enum HotspotStatus { idle, starting, active, error }

class HotspotSharingState {
  final HotspotStatus status;
  final HotspotInfo? hotspotInfo;
  final List<DeviceAppInfo> hostedApps;
  final List<SharePayload> hostedPayloads;
  final String? errorMessage;
  final int downloadCount;
  final SharingNetworkMode mode;

  const HotspotSharingState({
    this.status = HotspotStatus.idle,
    this.hotspotInfo,
    this.hostedApps = const [],
    this.hostedPayloads = const [],
    this.errorMessage,
    this.downloadCount = 0,
    this.mode = SharingNetworkMode.wifiLan,
  });

  bool get isActive => status == HotspotStatus.active;
  bool get isStarting => status == HotspotStatus.starting;
  bool get isLanMode => mode == SharingNetworkMode.wifiLan;

  HotspotSharingState copyWith({
    HotspotStatus? status,
    HotspotInfo? hotspotInfo,
    List<DeviceAppInfo>? hostedApps,
    List<SharePayload>? hostedPayloads,
    String? errorMessage,
    int? downloadCount,
    SharingNetworkMode? mode,
  }) {
    return HotspotSharingState(
      status: status ?? this.status,
      hotspotInfo: hotspotInfo ?? this.hotspotInfo,
      hostedApps: hostedApps ?? this.hostedApps,
      hostedPayloads: hostedPayloads ?? this.hostedPayloads,
      errorMessage: errorMessage,
      downloadCount: downloadCount ?? this.downloadCount,
      mode: mode ?? this.mode,
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
    SharingNetworkMode mode = SharingNetworkMode.wifiLan,
  }) async {
    if (apps.isEmpty) return false;

    state = state.copyWith(
      status: HotspotStatus.starting,
      hostedApps: apps,
      mode: mode,
      errorMessage: null,
    );

    try {
      // 1. Start embedded HTTP server
      final port = await _server.start(apps: apps, appIcons: appIcons);

      // 2. Start transport based on selected network mode
      final HotspotInfo info;
      if (mode == SharingNetworkMode.wifiLan) {
        info = await _hotspotService.startLanSharing(port: port);
      } else {
        info = await _hotspotService.startHotspot(port: port);
      }

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
        errorMessage: 'Failed to start sharing: $e',
      );
      return false;
    }
  }

  Future<void> switchMode({
    required SharingNetworkMode newMode,
    Map<String, Uint8List> appIcons = const {},
  }) async {
    if (state.hostedApps.isEmpty) return;
    await stopSharing();
    await startSharing(
      apps: state.hostedApps,
      appIcons: appIcons,
      mode: newMode,
    );
  }

  Future<void> stopSharing() async {
    await _server.stop();
    await _hotspotService.stopHotspot();
    state = const HotspotSharingState(status: HotspotStatus.idle);
  }
}
