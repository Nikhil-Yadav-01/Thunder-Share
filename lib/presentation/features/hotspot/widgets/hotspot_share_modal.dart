import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../data/hotspot/services/hotspot_service.dart';
import '../../../../domain/apps/entities/device_app_info.dart';
import '../../../../domain/permission/entities/app_permission.dart';
import '../../../../shared/utils/permission_helper.dart';
import '../controllers/hotspot_sharing_controller.dart';

class HotspotShareModal extends ConsumerStatefulWidget {
  final List<DeviceAppInfo> apps;
  final Map<String, Uint8List> appIcons;

  const HotspotShareModal({
    super.key,
    required this.apps,
    this.appIcons = const {},
  });

  static Future<void> show(
    BuildContext context, {
    required List<DeviceAppInfo> apps,
    Map<String, Uint8List> appIcons = const {},
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => HotspotShareModal(apps: apps, appIcons: appIcons),
    );
  }

  @override
  ConsumerState<HotspotShareModal> createState() => _HotspotShareModalState();
}

class _HotspotShareModalState extends ConsumerState<HotspotShareModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SharingNetworkMode _selectedMode = SharingNetworkMode.wifiLan;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Default to Wi-Fi LAN mode for frictionless cross-platform sharing
    Future.microtask(() {
      _startSharingInMode(_selectedMode);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startSharingInMode(SharingNetworkMode mode) async {
    // If selecting offline hotspot on Android, perform pre-flight permission check
    if (mode == SharingNetworkMode.offlineHotspot &&
        !kIsWeb &&
        Platform.isAndroid) {
      final status = await AppPermissionHelper.request(
        AppPermissionType.nearbyWifiDevices,
      );

      if (status == AppPermissionStatus.denied ||
          status == AppPermissionStatus.permanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Nearby Devices permission is required for Offline Hotspot. Using Wi-Fi LAN instead.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: AppPermissionHelper.openSettings,
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        mode = SharingNetworkMode.wifiLan;
        setState(() {
          _selectedMode = SharingNetworkMode.wifiLan;
        });
      }
    }

    ref.read(hotspotSharingControllerProvider.notifier).startSharing(
          apps: widget.apps,
          appIcons: widget.appIcons,
          mode: mode,
        );
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotspotSharingControllerProvider);
    final notifier = ref.read(hotspotSharingControllerProvider.notifier);
    final theme = Theme.of(context);
    final info = state.hotspotInfo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _selectedMode == SharingNetworkMode.wifiLan
                      ? Icons.wifi
                      : Icons.wifi_tethering,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedMode == SharingNetworkMode.wifiLan
                          ? 'Local Wi-Fi Network Share'
                          : 'Direct Offline Hotspot Share',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      state.isActive
                          ? 'Sharing ${widget.apps.length} app(s) • Ready for transfer'
                          : 'Preparing local share server...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: state.isActive
                            ? Colors.green.shade700
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            state.isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await notifier.stopSharing();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Network Mode Switcher (Wi-Fi LAN vs Offline Hotspot)
          SegmentedButton<SharingNetworkMode>(
            segments: const [
              ButtonSegment<SharingNetworkMode>(
                value: SharingNetworkMode.wifiLan,
                icon: Icon(Icons.wifi, size: 16),
                label: Text('Same Wi-Fi (LAN)'),
              ),
              ButtonSegment<SharingNetworkMode>(
                value: SharingNetworkMode.offlineHotspot,
                icon: Icon(Icons.wifi_tethering, size: 16),
                label: Text('Offline Hotspot'),
              ),
            ],
            selected: {_selectedMode},
            onSelectionChanged: (Set<SharingNetworkMode> selection) {
              final newMode = selection.first;
              setState(() {
                _selectedMode = newMode;
              });
              _startSharingInMode(newMode);
            },
          ),

          if (kIsWeb) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Web Preview Mode: Browser client preview active.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (state.isStarting) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Starting local file server & preparing APKs...'),
                ],
              ),
            ),
          ] else if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Unable to start ${_selectedMode == SharingNetworkMode.wifiLan ? "Wi-Fi" : "Hotspot"} sharing',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () => _startSharingInMode(_selectedMode),
                  child: const Text('Retry'),
                ),
                if (_selectedMode == SharingNetworkMode.offlineHotspot) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: AppPermissionHelper.openSettings,
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Open App Settings'),
                  ),
                ],
              ],
            ),
          ] else if (info != null) ...[
            // In Offline Hotspot mode, show both Wi-Fi Connect QR & Web Portal QR
            // In Wi-Fi LAN mode, show Web Portal QR directly
            if (!info.isLanMode) ...[
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.wifi, size: 18), text: '1. Connect Wi-Fi'),
                  Tab(icon: Icon(Icons.language, size: 18), text: '2. Download Portal'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Wi-Fi Quick Connect QR
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: info.wifiQrPayload ?? info.webPortalUrl,
                              version: QrVersions.auto,
                              size: 160,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan with camera to connect to Wi-Fi automatically',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Browser Download Portal QR
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: info.webPortalUrl,
                              version: QrVersions.auto,
                              size: 160,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Open in Chrome / Safari on any device (Android, iPhone, PC)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Wi-Fi LAN mode: Single prominent QR code for the download portal
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: info.webPortalUrl,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Scan to download on any device connected to the same Wi-Fi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Credentials / Connection Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildCredentialRow(
                      theme,
                      icon: Icons.wifi,
                      label: info.isLanMode ? 'Network Type' : 'Hotspot (SSID)',
                      value: info.ssid,
                      onCopy: () => _copy(info.ssid, 'Network SSID'),
                    ),
                    if (info.password.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildCredentialRow(
                        theme,
                        icon: Icons.lock_outline,
                        label: 'Hotspot Password',
                        value: info.password,
                        onCopy: () => _copy(info.password, 'Password'),
                      ),
                    ],
                    const Divider(height: 16),
                    _buildCredentialRow(
                      theme,
                      icon: Icons.link,
                      label: 'Download Web Portal',
                      value: info.webPortalUrl,
                      onCopy: () => _copy(info.webPortalUrl, 'Portal URL'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Button
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                await notifier.stopSharing();
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(
                info.isLanMode ? 'Stop Sharing' : 'Stop Sharing & Shutdown Hotspot',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCredentialRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: onCopy,
          tooltip: 'Copy',
        ),
      ],
    );
  }
}
