import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/permission/entities/app_permission.dart';
import '../controllers/permission_controller.dart';
import '../widgets/permission_card.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial load
    Future.microtask(() {
      ref.read(permissionControllerProvider.notifier).loadStatuses();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionControllerProvider.notifier).loadStatuses();
    }
  }

  Future<void> _handleRequest(
    AppPermissionType type,
    String permissionName,
  ) async {
    final status =
        await ref.read(permissionControllerProvider.notifier).requestPermission(type);
    if (!mounted) return;

    switch (status) {
      case AppPermissionStatus.granted:
        _showMessage('$permissionName permission granted.');
        break;
      case AppPermissionStatus.denied:
        _showRationaleDialog(type: type, permissionName: permissionName);
        break;
      case AppPermissionStatus.permanentlyDenied:
        _showPermanentDenialDialog(permissionName: permissionName);
        break;
      case AppPermissionStatus.restricted:
        _showMessage('$permissionName permission is restricted.');
        break;
      case AppPermissionStatus.limited:
        _showMessage('$permissionName permission is limited.');
        break;
      default:
        _showMessage('$permissionName status: ${status.name}');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showRationaleDialog({
    required AppPermissionType type,
    required String permissionName,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$permissionName permission needed'),
          content: Text(
            'This feature requires $permissionName permission. '
            'Please allow it when requested.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleRequest(type, permissionName);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPermanentDenialDialog({
    required String permissionName,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permission required'),
          content: Text(
            '$permissionName permission has been permanently denied. '
            'Enable it from app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(permissionControllerProvider.notifier).openSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionControllerProvider);
    final controller = ref.read(permissionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Permission Manager')),
      body: RefreshIndicator(
        onRefresh: controller.loadStatuses,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PermissionCard(
              title: 'Camera',
              status: state.cameraStatus.name,
              onRequest: state.isLoading
                  ? () {}
                  : () => _handleRequest(AppPermissionType.camera, 'Camera'),
            ),
            const SizedBox(height: 16),
            PermissionCard(
              title: 'Microphone',
              status: state.microphoneStatus.name,
              onRequest: state.isLoading
                  ? () {}
                  : () => _handleRequest(
                        AppPermissionType.microphone,
                        'Microphone',
                      ),
            ),
            const SizedBox(height: 16),
            PermissionCard(
              title: 'Location',
              status: state.locationStatus.name,
              onRequest: state.isLoading
                  ? () {}
                  : () => _handleRequest(
                        AppPermissionType.location,
                        'Location',
                      ),
            ),
            if (state.isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
