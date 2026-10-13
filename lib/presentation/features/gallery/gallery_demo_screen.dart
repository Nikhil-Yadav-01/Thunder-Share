import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/permission/entities/app_permission.dart';
import '../../permission/controllers/permission_controller.dart';

class RealMediaItem {
  final String path;
  final String name;
  final bool isVideo;
  final int sizeInBytes;
  final DateTime dateAdded;

  const RealMediaItem({
    required this.path,
    required this.name,
    required this.isVideo,
    required this.sizeInBytes,
    required this.dateAdded,
  });
}

class GalleryDemoScreen extends ConsumerStatefulWidget {
  const GalleryDemoScreen({super.key});

  @override
  ConsumerState<GalleryDemoScreen> createState() => _GalleryDemoScreenState();
}

class _GalleryDemoScreenState extends ConsumerState<GalleryDemoScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<RealMediaItem> _galleryItems = [];
  bool _isLoading = false;

  Future<void> _pickImagesFromGallery() async {
    setState(() => _isLoading = true);

    try {
      final List<XFile> images = await _picker.pickMultiImage();
      for (final img in images) {
        final file = File(img.path);
        final bytes = await file.length();
        _galleryItems.insert(
          0,
          RealMediaItem(
            path: img.path,
            name: img.name,
            isVideo: false,
            sizeInBytes: bytes,
            dateAdded: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick gallery items: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickVideoFromGallery() async {
    setState(() => _isLoading = true);

    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final file = File(video.path);
        final bytes = await file.length();
        _galleryItems.insert(
          0,
          RealMediaItem(
            path: video.path,
            name: video.name,
            isVideo: true,
            sizeInBytes: bytes,
            dateAdded: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openFullImageView(RealMediaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${(item.sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB • ${item.isVideo ? "Video" : "Photo"}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.isVideo
                    ? Container(
                        height: 240,
                        color: Colors.black87,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_circle_fill, size: 64, color: Colors.redAccent),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  item.path,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Image.file(
                        File(item.path),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Icon(Icons.broken_image, size: 60),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Path: ${item.path}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionControllerProvider);
    final hasMediaAccess = state.isGranted(AppPermissionType.photos) ||
        state.isGranted(AppPermissionType.videos) ||
        state.isGranted(AppPermissionType.storage);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Device Gallery'),
        actions: [
          if (hasMediaAccess) ...[
            IconButton(
              icon: const Icon(Icons.video_library_outlined),
              tooltip: 'Pick Device Video',
              onPressed: _pickVideoFromGallery,
            ),
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: 'Pick Real Photos',
              onPressed: _pickImagesFromGallery,
            ),
          ],
        ],
      ),
      body: !hasMediaAccess
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.orange.withValues(alpha: 0.12),
                      child: const Icon(Icons.no_photography_outlined,
                          size: 40, color: Colors.orange),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Photos Access Needed',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To pick and display genuine device images from your photo gallery, grant Photos permission.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Grant Photos Access'),
                      onPressed: () {
                        ref
                            .read(permissionControllerProvider.notifier)
                            .requestPermission(AppPermissionType.photos);
                      },
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Top Action Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Pick Photos'),
                          onPressed: _isLoading ? null : _pickImagesFromGallery,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Pick Video'),
                          onPressed: _isLoading ? null : _pickVideoFromGallery,
                        ),
                      ),
                    ],
                  ),
                ),

                // Gallery Grid
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _galleryItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.photo_album_outlined,
                                      size: 64,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No device photos loaded yet.\nTap "Pick Photos" above to import from your device.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: _galleryItems.length,
                              itemBuilder: (context, index) {
                                final item = _galleryItems[index];
                                return GestureDetector(
                                  onTap: () => _openFullImageView(item),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (item.isVideo)
                                          Container(
                                            color: Colors.grey.shade900,
                                            child: const Center(
                                              child: Icon(Icons.play_circle_fill,
                                                  color: Colors.white, size: 36),
                                            ),
                                          )
                                        else
                                          Image.file(
                                            File(item.path),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image),
                                          ),
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${(item.sizeInBytes / 1024).toStringAsFixed(0)}KB',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
