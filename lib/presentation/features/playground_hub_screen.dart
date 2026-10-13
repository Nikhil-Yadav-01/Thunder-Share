import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/permission/entities/app_permission.dart';
import '../permission/controllers/permission_controller.dart';
import 'audio/audio_recorder_demo_screen.dart';
import 'camera/camera_demo_screen.dart';
import 'files/files_demo_screen.dart';
import 'gallery/gallery_demo_screen.dart';
import 'location/location_demo_screen.dart';
import 'system/app_details_demo_screen.dart';

class PlaygroundItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final AppPermissionType permissionType;
  final Widget Function() screenBuilder;

  const PlaygroundItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.permissionType,
    required this.screenBuilder,
  });
}

class PlaygroundHubScreen extends ConsumerWidget {
  const PlaygroundHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(permissionControllerProvider);
    final theme = Theme.of(context);

    final items = [
      PlaygroundItem(
        title: 'Camera & Video Capture',
        subtitle: 'Live viewfinder, flip camera, photo capture & video recorder.',
        icon: Icons.camera_alt_outlined,
        color: Colors.blue,
        permissionType: AppPermissionType.camera,
        screenBuilder: () => const CameraDemoScreen(),
      ),
      PlaygroundItem(
        title: 'Audio Recorder Studio',
        subtitle: 'Live audio waveform, voice memo recorder & playback list.',
        icon: Icons.mic_none_outlined,
        color: Colors.redAccent,
        permissionType: AppPermissionType.microphone,
        screenBuilder: () => const AudioRecorderDemoScreen(),
      ),
      PlaygroundItem(
        title: 'Photos & Media Gallery',
        subtitle: 'Browse device photos & videos, preview resolutions and metadata.',
        icon: Icons.photo_library_outlined,
        color: Colors.purple,
        permissionType: AppPermissionType.photos,
        screenBuilder: () => const GalleryDemoScreen(),
      ),
      PlaygroundItem(
        title: 'Storage & File Manager',
        subtitle: 'Real device file explorer, create and inspect text files with dart:io.',
        icon: Icons.folder_outlined,
        color: Colors.amber.shade800,
        permissionType: AppPermissionType.storage,
        screenBuilder: () => const FilesDemoScreen(),
      ),
      PlaygroundItem(
        title: 'Location & GPS Radar',
        subtitle: 'GPS sensor coordinates, altitude, bearing, and waypoint logs.',
        icon: Icons.location_on_outlined,
        color: Colors.teal,
        permissionType: AppPermissionType.location,
        screenBuilder: () => const LocationDemoScreen(),
      ),
      PlaygroundItem(
        title: 'App Details & System Tools',
        subtitle: 'Inspect package specs, test notification triggers & floating overlays.',
        icon: Icons.settings_system_daydream_outlined,
        color: Colors.indigo,
        permissionType: AppPermissionType.notification,
        screenBuilder: () => const AppDetailsDemoScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Playground'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final isGranted = state.isGranted(item.permissionType);

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isGranted
                    ? Colors.green.withValues(alpha: 0.3)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => item.screenBuilder()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: item.color.withValues(alpha: 0.12),
                      child: Icon(item.icon, color: item.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isGranted
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isGranted ? 'Ready' : 'Restricted',
                                  style: TextStyle(
                                    color: isGranted ? Colors.green : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
