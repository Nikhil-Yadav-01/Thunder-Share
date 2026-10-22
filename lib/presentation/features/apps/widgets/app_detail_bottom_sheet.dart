import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/apps/entities/device_app_info.dart';
import '../../hotspot/widgets/hotspot_share_modal.dart';
import '../controllers/device_apps_controller.dart';

class AppDetailBottomSheet extends ConsumerStatefulWidget {
  final DeviceAppInfo app;

  const AppDetailBottomSheet({super.key, required this.app});

  static Future<void> show(BuildContext context, DeviceAppInfo app) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AppDetailBottomSheet(app: app),
    );
  }

  @override
  ConsumerState<AppDetailBottomSheet> createState() =>
      _AppDetailBottomSheetState();
}

class _AppDetailBottomSheetState extends ConsumerState<AppDetailBottomSheet> {
  List<String>? _permissions;
  bool _isLoadingPermissions = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final notifier = ref.read(deviceAppsControllerProvider.notifier);
    if (widget.app.permissions.isNotEmpty) {
      if (mounted) {
        setState(() {
          _permissions = widget.app.permissions;
          _isLoadingPermissions = false;
        });
      }
    } else {
      final perms = await notifier.fetchAppPermissions(widget.app.packageName);
      if (mounted) {
        setState(() {
          _permissions = perms;
          _isLoadingPermissions = false;
        });
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
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
    final theme = Theme.of(context);
    final notifier = ref.read(deviceAppsControllerProvider.notifier);
    final state = ref.watch(deviceAppsControllerProvider);
    final iconBytes = state.appIcons[widget.app.packageName] ?? widget.app.iconBytes;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // App Header Card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: iconBytes != null
                              ? Image.memory(
                                  iconBytes,
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.android,
                                  size: 38,
                                  color: theme.colorScheme.primary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.app.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () => _copyToClipboard(
                                context,
                                widget.app.packageName,
                                'Package Name',
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.app.packageName,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'v${widget.app.versionName} (${widget.app.versionCode})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.app.isSystemApp
                                        ? Colors.orange.withValues(alpha: 0.14)
                                        : Colors.green.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.app.isSystemApp ? 'System App' : 'User App',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: widget.app.isSystemApp
                                          ? Colors.orange.shade800
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons Row (Launch, Settings, Share APK, Share Link)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final launched = await notifier.launchApp(widget.app.packageName);
                            if (!context.mounted) return;
                            if (!launched) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cannot launch this system component'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                          label: const Text('Launch'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => notifier.openAppSettings(widget.app.packageName),
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Settings'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => notifier.shareSingleApk(widget.app),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share APK'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      HotspotShareModal.show(
                        context,
                        apps: [widget.app],
                        appIcons: state.appIcons,
                      );
                    },
                    icon: const Icon(Icons.wifi_tethering, size: 18),
                    label: const Text('Share via Offline Hotspot (No Internet)'),
                  ),

                  const SizedBox(height: 20),

                  // Technical Specs Section
                  Text(
                    'App Specifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSpecRow(
                            theme,
                            icon: Icons.sd_storage_outlined,
                            label: 'APK File Size',
                            value: widget.app.formattedSize,
                          ),
                          const Divider(height: 20),
                          _buildSpecRow(
                            theme,
                            icon: Icons.calendar_today_outlined,
                            label: 'First Installed',
                            value: widget.app.formattedInstallDate,
                          ),
                          const Divider(height: 20),
                          _buildSpecRow(
                            theme,
                            icon: Icons.update_outlined,
                            label: 'Last Updated',
                            value: widget.app.formattedUpdateDate,
                          ),
                          const Divider(height: 20),
                          _buildSpecRow(
                            theme,
                            icon: Icons.layers_outlined,
                            label: 'Target SDK / Min SDK',
                            value: 'Target: ${widget.app.targetSdk} | Min: ${widget.app.minSdk}',
                          ),
                          if (widget.app.apkFilePath.isNotEmpty) ...[
                            const Divider(height: 20),
                            InkWell(
                              onTap: () => _copyToClipboard(
                                context,
                                widget.app.apkFilePath,
                                'APK Path',
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.folder_open_outlined,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'APK Source Path',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.app.apkFilePath,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.copy, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Permissions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Requested Permissions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_permissions != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_permissions!.length} permissions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_isLoadingPermissions)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_permissions == null || _permissions!.isEmpty)
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No special permissions requested by this package.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _permissions!.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final perm = _permissions![index];
                          final cleanName = perm.replaceFirst('android.permission.', '');
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              _getIconForPermission(cleanName),
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(
                              cleanName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              perm,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpecRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForPermission(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('camera')) return Icons.camera_alt_outlined;
    if (lower.contains('audio') || lower.contains('record')) return Icons.mic_none_outlined;
    if (lower.contains('location')) return Icons.location_on_outlined;
    if (lower.contains('bluetooth')) return Icons.bluetooth_outlined;
    if (lower.contains('wifi') || lower.contains('network') || lower.contains('internet')) {
      return Icons.wifi;
    }
    if (lower.contains('storage') || lower.contains('media')) return Icons.folder_outlined;
    if (lower.contains('contact')) return Icons.contacts_outlined;
    if (lower.contains('sms') || lower.contains('phone')) return Icons.phone_outlined;
    if (lower.contains('sensor')) return Icons.sensors_outlined;
    if (lower.contains('notification')) return Icons.notifications_none_outlined;
    return Icons.security_outlined;
  }
}
