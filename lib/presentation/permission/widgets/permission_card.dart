import 'package:flutter/material.dart';

import '../../../domain/permission/entities/app_permission.dart';

class PermissionCard extends StatelessWidget {
  final AppPermissionType permissionType;
  final AppPermissionStatus status;
  final bool isRequesting;
  final VoidCallback onRequest;
  final VoidCallback? onCheckStatus;
  final VoidCallback? onOpenDemo;

  const PermissionCard({
    super.key,
    required this.permissionType,
    required this.status,
    required this.onRequest,
    this.isRequesting = false,
    this.onCheckStatus,
    this.onOpenDemo,
  });

  Color get statusColor {
    switch (status) {
      case AppPermissionStatus.granted:
        return Colors.green;
      case AppPermissionStatus.limited:
        return Colors.teal;
      case AppPermissionStatus.permanentlyDenied:
        return Colors.deepOrange;
      case AppPermissionStatus.restricted:
        return Colors.orange;
      case AppPermissionStatus.denied:
        return Colors.red;
      case AppPermissionStatus.provisional:
        return Colors.indigo;
      case AppPermissionStatus.unknown:
        return Colors.grey;
      case AppPermissionStatus.notApplicable:
        return Colors.blueGrey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case AppPermissionStatus.granted:
        return Icons.check_circle_rounded;
      case AppPermissionStatus.limited:
        return Icons.adjust_rounded;
      case AppPermissionStatus.permanentlyDenied:
        return Icons.block_rounded;
      case AppPermissionStatus.restricted:
        return Icons.lock_outline_rounded;
      case AppPermissionStatus.denied:
        return Icons.cancel_outlined;
      case AppPermissionStatus.provisional:
        return Icons.hourglass_top_rounded;
      case AppPermissionStatus.unknown:
        return Icons.help_outline_rounded;
      case AppPermissionStatus.notApplicable:
        return Icons.do_not_disturb_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: status == AppPermissionStatus.granted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    permissionType.icon,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            permissionType.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (permissionType.platformTag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                permissionType.platformTag!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        permissionType.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (onCheckStatus != null) ...[
                  IconButton(
                    tooltip: 'Check current status',
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: isRequesting ? null : onCheckStatus,
                  ),
                  const SizedBox(width: 4),
                ],
                if (onOpenDemo != null) ...[
                  IconButton.filledTonal(
                    tooltip: 'Open Feature Demo',
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    onPressed: onOpenDemo,
                  ),
                  const SizedBox(width: 6),
                ],
                // Trigger Button
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: isRequesting ? null : onRequest,
                  child: isRequesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          status == AppPermissionStatus.granted
                              ? 'Recheck'
                              : status == AppPermissionStatus.notApplicable
                                  ? 'Info'
                                  : 'Request',
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

