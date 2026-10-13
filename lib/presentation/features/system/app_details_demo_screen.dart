import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../domain/permission/entities/app_permission.dart';
import '../../permission/controllers/permission_controller.dart';

class AppDetailsDemoScreen extends ConsumerStatefulWidget {
  const AppDetailsDemoScreen({super.key});

  @override
  ConsumerState<AppDetailsDemoScreen> createState() => _AppDetailsDemoScreenState();
}

class _AppDetailsDemoScreenState extends ConsumerState<AppDetailsDemoScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (_) {}
  }

  void _showTestNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.indigo.shade700,
        content: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permission System Alert',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Push Notification delivery verified successfully.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOverlayDemo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.picture_in_picture_alt, size: 36, color: Colors.purple),
        title: const Text('Floating Overlay Simulation'),
        content: const Text(
          'With "Display Over Other Apps" (SYSTEM_ALERT_WINDOW) enabled, '
          'apps can draw floating widgets, chat bubbles, or picture-in-picture windows '
          'above any screen on Android.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss Overlay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionControllerProvider);
    final theme = Theme.of(context);

    int grantedCount = 0;
    int deniedCount = 0;
    int unsupportedCount = 0;

    for (final type in AppPermissionType.values) {
      final status = state.statusOf(type);
      if (status == AppPermissionStatus.granted ||
          status == AppPermissionStatus.limited) {
        grantedCount++;
      } else if (status == AppPermissionStatus.notApplicable) {
        unsupportedCount++;
      } else {
        deniedCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real App & System Specs'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Spec Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.security, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _packageInfo?.appName.isNotEmpty == true
                                    ? _packageInfo!.appName
                                    : 'Permission Manager',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Package: ${_packageInfo?.packageName ?? "com.r.permission"}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Version: ${_packageInfo?.version ?? "1.0.0"} (Build ${_packageInfo?.buildNumber ?? "1"}) • ${kIsWeb ? "Web" : Platform.operatingSystem.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Granted',
                          value: '$grantedCount',
                          color: Colors.green,
                        ),
                        _StatItem(
                          label: 'Denied',
                          value: '$deniedCount',
                          color: Colors.red,
                        ),
                        _StatItem(
                          label: 'Platform Excluded',
                          value: '$unsupportedCount',
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Interactive System Features',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Notification Trigger Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.withValues(alpha: 0.15),
                  child: const Icon(Icons.notifications_active, color: Colors.indigo),
                ),
                title: const Text('Test Push Notification'),
                subtitle: const Text('Simulates local and background notification dispatch'),
                trailing: FilledButton.tonal(
                  onPressed: () => _showTestNotification(context),
                  child: const Text('Trigger'),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Floating Overlay Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withValues(alpha: 0.15),
                  child: const Icon(Icons.picture_in_picture_alt, color: Colors.purple),
                ),
                title: const Text('System Overlay Demo'),
                subtitle: const Text('Simulates drawing over other applications'),
                trailing: FilledButton.tonal(
                  onPressed: () => _showOverlayDemo(context),
                  child: const Text('Launch'),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'Live Permission Audit Log',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AppPermissionType.values.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final type = AppPermissionType.values[index];
                  final status = state.statusOf(type);

                  Color statusColor = Colors.grey;
                  if (status == AppPermissionStatus.granted ||
                      status == AppPermissionStatus.limited) {
                    statusColor = Colors.green;
                  } else if (status == AppPermissionStatus.notApplicable) {
                    statusColor = Colors.blueGrey;
                  } else if (status == AppPermissionStatus.denied) {
                    statusColor = Colors.red;
                  }

                  return ListTile(
                    leading: Icon(type.icon, size: 20, color: theme.colorScheme.primary),
                    title: Text(
                      type.displayName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: type.platformTag != null
                        ? Text(type.platformTag!, style: const TextStyle(fontSize: 11))
                        : null,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
