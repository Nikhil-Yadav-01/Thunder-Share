import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/permission/mappers/permission_mapper.dart';
import '../../domain/permission/entities/app_permission.dart';

/// A standalone, plug-and-play helper for permission checks and requests.
/// Can easily be copied or imported into any Flutter application.
class AppPermissionHelper {
  AppPermissionHelper._();

  /// Check current status of any permission.
  static Future<AppPermissionStatus> checkStatus(
    AppPermissionType type,
  ) async {
    if (!type.isSupportedOnPlatform(defaultTargetPlatform, isWeb: kIsWeb)) {
      return AppPermissionStatus.notApplicable;
    }
    final permission = PermissionMapper.toHandlerPermission(type);
    final status = await permission.status;
    return PermissionMapper.toDomainStatus(status);
  }

  /// Check if a specific permission is already granted.
  static Future<bool> isGranted(AppPermissionType type) async {
    final permission = PermissionMapper.toHandlerPermission(type);
    return await permission.isGranted;
  }

  /// Request a specific permission directly.
  static Future<AppPermissionStatus> request(AppPermissionType type) async {
    if (!type.isSupportedOnPlatform(defaultTargetPlatform, isWeb: kIsWeb)) {
      return AppPermissionStatus.notApplicable;
    }
    final permission = PermissionMapper.toHandlerPermission(type);
    final status = await permission.request();
    return PermissionMapper.toDomainStatus(status);
  }

  /// Open application system settings.
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  // ---------------------------------------------------------------------------
  // Unified Trigger with Context (Dialogs, Rationales, SnackBars, Callbacks)
  // ---------------------------------------------------------------------------

  /// Checks and requests any permission with customizable user dialogs,
  /// rationale explanations, and settings fallback.
  static Future<AppPermissionStatus> checkAndRequestWithUI(
    BuildContext context, {
    required AppPermissionType type,
    String? rationaleMessage,
    VoidCallback? onGranted,
    VoidCallback? onDenied,
    VoidCallback? onPermanentlyDenied,
    bool isRetry = false,
  }) async {
    // Check platform compatibility first
    if (!type.isSupportedOnPlatform(defaultTargetPlatform, isWeb: kIsWeb)) {
      if (context.mounted) {
        await _showUnsupportedDialog(context: context, type: type);
      }
      return AppPermissionStatus.notApplicable;
    }

    final status = await request(type);

    if (!context.mounted) return status;

    switch (status) {
      case AppPermissionStatus.granted:
      case AppPermissionStatus.limited:
        onGranted?.call();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${type.displayName} permission granted!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        break;

      case AppPermissionStatus.denied:
        onDenied?.call();
        if (isRetry) {
          // Break recursive rationale loop if the OS returns denied again
          if (type == AppPermissionType.storage &&
              defaultTargetPlatform == TargetPlatform.android) {
            await _showStorageAlternativeDialog(context: context);
          } else {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    '${type.displayName} was not granted. Please enable it in Settings.',
                  ),
                  backgroundColor: Colors.red.shade700,
                  action: SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: openSettings,
                  ),
                ),
              );
          }
        } else {
          await _showRationaleDialog(
            context: context,
            type: type,
            message: rationaleMessage ??
                '${type.displayName} permission is needed to continue. ${type.description}',
            onRetry: () => checkAndRequestWithUI(
              context,
              type: type,
              rationaleMessage: rationaleMessage,
              onGranted: onGranted,
              onDenied: onDenied,
              onPermanentlyDenied: onPermanentlyDenied,
              isRetry: true,
            ),
          );
        }
        break;

      case AppPermissionStatus.permanentlyDenied:
        onPermanentlyDenied?.call();
        await _showSettingsDialog(
          context: context,
          type: type,
        );
        break;

      case AppPermissionStatus.notApplicable:
        await _showUnsupportedDialog(context: context, type: type);
        break;

      case AppPermissionStatus.restricted:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '${type.displayName} access is restricted by parental or system controls.',
              ),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        break;

      default:
        break;
    }

    return status;
  }

  // ---------------------------------------------------------------------------
  // Individual Standalone Triggers (Plug-and-play shortcuts for any app)
  // ---------------------------------------------------------------------------

  /// Trigger for Photos / Gallery permission
  static Future<AppPermissionStatus> requestPhotos(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.photos,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Videos permission
  static Future<AppPermissionStatus> requestVideos(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.videos,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Media Library (Apple Music / Media playback) permission
  static Future<AppPermissionStatus> requestMediaLibrary(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.mediaLibrary,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Audio / Music tracks permission
  static Future<AppPermissionStatus> requestAudio(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.audio,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Storage (Read/Write) permission
  static Future<AppPermissionStatus> requestStorage(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.storage,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Manage All Files Access (Android 11+)
  static Future<AppPermissionStatus> requestManageExternalStorage(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.manageExternalStorage,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for App Tracking Transparency (iOS)
  static Future<AppPermissionStatus> requestAppTracking(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.appTrackingTransparency,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Display Over Other Apps (System Alert Window)
  static Future<AppPermissionStatus> requestSystemAlertWindow(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.systemAlertWindow,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Install Unknown Apps (Package Installer)
  static Future<AppPermissionStatus> requestInstallPackages(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.requestInstallPackages,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Push Notifications
  static Future<AppPermissionStatus> requestNotification(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.notification,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Camera
  static Future<AppPermissionStatus> requestCamera(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.camera,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Microphone
  static Future<AppPermissionStatus> requestMicrophone(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.microphone,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  /// Trigger for Location
  static Future<AppPermissionStatus> requestLocation(
    BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) =>
      checkAndRequestWithUI(
        context,
        type: AppPermissionType.location,
        onGranted: onGranted,
        onDenied: onDenied,
      );

  // ---------------------------------------------------------------------------
  // Internal UI Dialog Helpers
  // ---------------------------------------------------------------------------

  static Future<void> _showRationaleDialog({
    required BuildContext context,
    required AppPermissionType type,
    required String message,
    required VoidCallback onRetry,
  }) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(type.icon, size: 36, color: Theme.of(ctx).colorScheme.primary),
        title: Text('${type.displayName} Permission Needed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRetry();
            },
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showUnsupportedDialog({
    required BuildContext context,
    required AppPermissionType type,
  }) async {
    if (!context.mounted) return;

    final explanation = type.unsupportedExplanation(defaultTargetPlatform) ??
        '${type.displayName} is not supported on this platform.';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.info_outline,
          size: 36,
          color: Theme.of(ctx).colorScheme.primary,
        ),
        title: Text('${type.displayName} Not Supported'),
        content: Text(explanation),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showStorageAlternativeDialog({
    required BuildContext context,
  }) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.folder_special_outlined,
          size: 36,
          color: Theme.of(ctx).colorScheme.primary,
        ),
        title: const Text('Android 13+ Storage Notice'),
        content: const Text(
          'On modern Android versions (Android 13 / API 33+), traditional '
          'Storage (Read / Write) is deprecated and ignored by the OS.\n\n'
          'Instead, please use:\n'
          '• Granular Media Permissions: Photos, Videos, and Audio\n'
          '• Manage All Files: For full device filesystem access',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await requestManageExternalStorage(context);
            },
            child: const Text('Manage All Files'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showSettingsDialog({
    required BuildContext context,
    required AppPermissionType type,
  }) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.settings_outlined, size: 36, color: Colors.orange),
        title: Text('${type.displayName} Permission Blocked'),
        content: Text(
          '${type.displayName} permission is permanently denied. '
          'Please enable it in App Settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new, size: 16),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openSettings();
            },
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
