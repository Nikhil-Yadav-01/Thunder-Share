import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/permission/entities/app_permission.dart';
import '../../../shared/utils/permission_helper.dart';
import '../../features/audio/audio_recorder_demo_screen.dart';
import '../../features/camera/camera_demo_screen.dart';
import '../../features/files/files_demo_screen.dart';
import '../../features/gallery/gallery_demo_screen.dart';
import '../../features/location/location_demo_screen.dart';
import '../../features/playground_hub_screen.dart';
import '../../features/system/app_details_demo_screen.dart';
import '../controllers/permission_controller.dart';
import '../widgets/permission_card.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);

    // Initial load
    Future.microtask(() {
      ref.read(permissionControllerProvider.notifier).loadStatuses();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionControllerProvider.notifier).loadStatuses();
    }
  }

  Future<void> _handlePermissionRequest(
    AppPermissionType type, {
    bool isRetry = false,
  }) async {
    // Check platform compatibility before requesting
    if (!type.isSupportedOnPlatform(defaultTargetPlatform, isWeb: kIsWeb)) {
      _showUnsupportedDialog(type);
      return;
    }

    final status = await ref
        .read(permissionControllerProvider.notifier)
        .requestPermission(type);

    if (!mounted) return;

    switch (status) {
      case AppPermissionStatus.granted:
      case AppPermissionStatus.limited:
        _showSnackBar(
          '${type.displayName} permission granted!',
          Colors.green.shade700,
        );
        break;

      case AppPermissionStatus.denied:
        if (isRetry) {
          // Break recursive rationale loop if the OS returns denied again
          if (type == AppPermissionType.storage &&
              defaultTargetPlatform == TargetPlatform.android) {
            _showStorageAlternativeDialog();
          } else {
            _showSnackBar(
              '${type.displayName} was not granted. You can enable it in Settings.',
              Colors.red.shade700,
              actionLabel: 'Settings',
              onAction: () => ref
                  .read(permissionControllerProvider.notifier)
                  .openSettings(),
            );
          }
        } else {
          _showRationaleDialog(type);
        }
        break;

      case AppPermissionStatus.permanentlyDenied:
        _showPermanentDenialDialog(type);
        break;

      case AppPermissionStatus.restricted:
        _showSnackBar(
          '${type.displayName} access is restricted by system policy.',
          Colors.orange.shade800,
        );
        break;

      case AppPermissionStatus.provisional:
        _showSnackBar(
          '${type.displayName} granted provisionally.',
          Colors.indigo,
        );
        break;

      case AppPermissionStatus.notApplicable:
        _showUnsupportedDialog(type);
        break;

      case AppPermissionStatus.unknown:
        _showSnackBar(
          '${type.displayName} status: Unknown / Not supported on this platform.',
          Colors.grey.shade700,
        );
        break;
    }
  }

  void _showSnackBar(
    String message,
    Color backgroundColor, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }

  Future<void> _showUnsupportedDialog(AppPermissionType type) async {
    if (!mounted) return;

    final explanation = type.unsupportedExplanation(defaultTargetPlatform) ??
        '${type.displayName} is not supported on this platform.';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            Icons.info_outline,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text('${type.displayName} Not Supported'),
          content: Text(explanation),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showStorageAlternativeDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            Icons.folder_special_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Android 13+ Storage Notice'),
          content: const Text(
            'On modern Android versions (Android 13 / API 33+), traditional '
            'Storage (Read / Write) is deprecated and ignored by the OS.\n\n'
            'Instead, Android provides:\n'
            '• Granular Media Permissions: Photos, Videos, and Audio\n'
            '• Manage All Files: For broad device-wide file access\n\n'
            'Which would you like to explore?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _tabController.animateTo(1); // Photos & Media tab
              },
              child: const Text('Photos & Media'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handlePermissionRequest(
                  AppPermissionType.manageExternalStorage,
                );
              },
              child: const Text('Manage All Files'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRationaleDialog(AppPermissionType type) async {
    if (!mounted) return;

    final isStorageOnAndroid = type == AppPermissionType.storage &&
        defaultTargetPlatform == TargetPlatform.android;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            type.icon,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text('${type.displayName} Permission Needed'),
          content: Text(
            isStorageOnAndroid
                ? 'On modern Android versions (Android 13+), broad external storage access is deprecated. '
                  'The OS may reject this request in favor of Granular Media permissions (Photos, Videos, Audio) '
                  'or Manage All Files access.\n\n'
                  'Would you like to try requesting this anyway?'
                : '${type.description}\n\nPlease allow this permission to use all features seamlessly.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (isStorageOnAndroid)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _tabController.animateTo(1);
                },
                child: const Text('Media Permissions'),
              ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handlePermissionRequest(type, isRetry: true);
              },
              child: const Text('Allow Permission'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPermanentDenialDialog(AppPermissionType type) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.settings_outlined,
            size: 32,
            color: Colors.deepOrange,
          ),
          title: Text('${type.displayName} Permanently Blocked'),
          content: Text(
            '${type.displayName} permission is permanently denied.\n\n'
            'Please enable it from App Settings to proceed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              onPressed: () async {
                Navigator.of(context).pop();
                await ref
                    .read(permissionControllerProvider.notifier)
                    .openSettings();
              },
              label: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  List<AppPermissionType> _filterPermissions(int tabIndex) {
    switch (tabIndex) {
      case 1: // Photos & Media
        return AppPermissionType.values
            .where((t) => t.category == AppPermissionCategory.media)
            .toList();
      case 2: // Apps & System
        return AppPermissionType.values
            .where((t) => t.category == AppPermissionCategory.system)
            .toList();
      case 3: // Hardware
        return AppPermissionType.values
            .where((t) => t.category == AppPermissionCategory.hardware)
            .toList();
      case 0: // All
      default:
        return AppPermissionType.values;
    }
  }

  void _openDemoForPermission(AppPermissionType type) {
    Widget screen;
    switch (type) {
      case AppPermissionType.camera:
        screen = const CameraDemoScreen();
        break;
      case AppPermissionType.microphone:
        screen = const AudioRecorderDemoScreen();
        break;
      case AppPermissionType.location:
        screen = const LocationDemoScreen();
        break;
      case AppPermissionType.photos:
      case AppPermissionType.videos:
      case AppPermissionType.mediaLibrary:
      case AppPermissionType.audio:
        screen = const GalleryDemoScreen();
        break;
      case AppPermissionType.storage:
      case AppPermissionType.manageExternalStorage:
        screen = const FilesDemoScreen();
        break;
      case AppPermissionType.appTrackingTransparency:
      case AppPermissionType.systemAlertWindow:
      case AppPermissionType.requestInstallPackages:
      case AppPermissionType.notification:
        screen = const AppDetailsDemoScreen();
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionControllerProvider);
    final controller = ref.read(permissionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Manager'),
        actions: [
          IconButton(
            tooltip: 'Feature Playground',
            icon: const Icon(Icons.explore_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PlaygroundHubScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'App Settings',
            icon: const Icon(Icons.settings),
            onPressed: controller.openSettings,
          ),
          IconButton(
            tooltip: 'Refresh All',
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadStatuses,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(icon: Icon(Icons.perm_media_outlined, size: 18), text: 'Photos & Media'),
            Tab(icon: Icon(Icons.apps_outlined, size: 18), text: 'Apps & System'),
            Tab(icon: Icon(Icons.devices_outlined, size: 18), text: 'Hardware'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (index) {
          final items = _filterPermissions(index);
          return RefreshIndicator(
            onRefresh: controller.loadStatuses,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, itemIndex) {
                final type = items[itemIndex];
                final status = state.statusOf(type);
                final isRequestingThis =
                    state.isLoading && state.activeRequestingType == type;

                return PermissionCard(
                  permissionType: type,
                  status: status,
                  isRequesting: isRequestingThis,
                  onRequest: () => _handlePermissionRequest(type),
                  onCheckStatus: () => controller.checkStatus(type),
                  onOpenDemo: () => _openDemoForPermission(type),
                );
              },
            ),
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Quick Photo Pick'),
                  onPressed: () => AppPermissionHelper.requestPhotos(
                    context,
                    onGranted: () => _showSnackBar(
                      'Ready to open Photo Picker!',
                      Colors.green.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.apps, size: 18),
                  label: const Text('App Tracking'),
                  onPressed: () => AppPermissionHelper.requestAppTracking(
                    context,
                    onGranted: () => _showSnackBar(
                      'App Tracking Authorized!',
                      Colors.indigo,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
