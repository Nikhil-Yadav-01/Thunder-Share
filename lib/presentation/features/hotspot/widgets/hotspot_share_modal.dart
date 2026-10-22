import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../domain/apps/entities/device_app_info.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(hotspotSharingControllerProvider.notifier).startSharing(
            apps: widget.apps,
            appIcons: widget.appIcons,
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  Icons.wifi_tethering,
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
                      'Direct Wi-Fi Hotspot Share',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      state.isActive
                          ? 'Sharing ${widget.apps.length} app(s) • Offline AP active'
                          : 'Starting local hotspot...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: state.isActive
                            ? Colors.green.shade700
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: state.isActive ? FontWeight.bold : FontWeight.normal,
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

          const SizedBox(height: 16),

          if (state.isStarting) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Starting offline Wi-Fi AP & hosting APKs...'),
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
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => notifier.startSharing(
                apps: widget.apps,
                appIcons: widget.appIcons,
              ),
              child: const Text('Retry Hotspot'),
            ),
          ] else if (info != null) ...[
            // Tab Switcher for QR Codes
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
                            data: info.wifiQrPayload,
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

            const SizedBox(height: 14),

            // Credentials Card
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
                      label: 'Network (SSID)',
                      value: info.ssid,
                      onCopy: () => _copy(info.ssid, 'Hotspot SSID'),
                    ),
                    if (info.password.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildCredentialRow(
                        theme,
                        icon: Icons.lock_outline,
                        label: 'Password',
                        value: info.password,
                        onCopy: () => _copy(info.password, 'Password'),
                      ),
                    ],
                    const Divider(height: 16),
                    _buildCredentialRow(
                      theme,
                      icon: Icons.link,
                      label: 'Portal Link',
                      value: info.webPortalUrl,
                      onCopy: () => _copy(info.webPortalUrl, 'Portal URL'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
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
              label: const Text('Stop Sharing & Shutdown Hotspot'),
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
