import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/permission/entities/app_permission.dart';
import '../../permission/controllers/permission_controller.dart';

class RealCapturedItem {
  final String path;
  final String name;
  final bool isVideo;
  final int sizeInBytes;
  final DateTime timestamp;

  const RealCapturedItem({
    required this.path,
    required this.name,
    required this.isVideo,
    required this.sizeInBytes,
    required this.timestamp,
  });
}

class CameraDemoScreen extends ConsumerStatefulWidget {
  const CameraDemoScreen({super.key});

  @override
  ConsumerState<CameraDemoScreen> createState() => _CameraDemoScreenState();
}

class _CameraDemoScreenState extends ConsumerState<CameraDemoScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<RealCapturedItem> _capturedItems = [];
  bool _isProcessing = false;
  CameraDevice _preferredCamera = CameraDevice.rear;
  bool _isVideoMode = false;

  Future<void> _captureMedia() async {
    setState(() => _isProcessing = true);

    try {
      if (_isVideoMode) {
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.camera,
          preferredCameraDevice: _preferredCamera,
          maxDuration: const Duration(minutes: 2),
        );

        if (video != null) {
          final file = File(video.path);
          final bytes = await file.length();
          final newItem = RealCapturedItem(
            path: video.path,
            name: video.name,
            isVideo: true,
            sizeInBytes: bytes,
            timestamp: DateTime.now(),
          );
          setState(() {
            _capturedItems.insert(0, newItem);
          });
        }
      } else {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: _preferredCamera,
          imageQuality: 95,
        );

        if (photo != null) {
          final file = File(photo.path);
          final bytes = await file.length();
          final newItem = RealCapturedItem(
            path: photo.path,
            name: photo.name,
            isVideo: false,
            sizeInBytes: bytes,
            timestamp: DateTime.now(),
          );
          setState(() {
            _capturedItems.insert(0, newItem);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera capture error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _toggleCameraLens() {
    setState(() {
      _preferredCamera = _preferredCamera == CameraDevice.rear
          ? CameraDevice.front
          : CameraDevice.rear;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preferred lens: ${_preferredCamera == CameraDevice.rear ? "Rear Camera" : "Front Selfie Camera"}',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImagePreview(RealCapturedItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                title: Text(item.name, style: const TextStyle(fontSize: 14)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.isVideo
                    ? Container(
                        height: 280,
                        color: Colors.grey.shade900,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.videocam, size: 64, color: Colors.redAccent),
                              const SizedBox(height: 8),
                              Text(
                                'Video recorded on disk:\n${item.path}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                          child: Icon(Icons.broken_image, size: 60, color: Colors.white),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(item.sizeInBytes / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      item.timestamp.toLocal().toString().substring(0, 19),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
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
    final isCameraGranted = state.isGranted(AppPermissionType.camera);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Real Device Camera'),
        actions: [
          if (isCameraGranted)
            IconButton(
              icon: Icon(
                _preferredCamera == CameraDevice.rear
                    ? Icons.camera_rear
                    : Icons.camera_front,
              ),
              tooltip: 'Switch Lens Preference',
              onPressed: _toggleCameraLens,
            ),
        ],
      ),
      body: !isCameraGranted
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.red.withValues(alpha: 0.2),
                      child: const Icon(Icons.videocam_off, size: 40, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Permission Needed',
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To launch the real physical camera and take device photos, grant Camera access.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Grant Camera Access'),
                      onPressed: () {
                        ref
                            .read(permissionControllerProvider.notifier)
                            .requestPermission(AppPermissionType.camera);
                      },
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Top Live Viewfinder Preview Box
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_capturedItems.isNotEmpty && !_capturedItems.first.isVideo)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(23),
                              child: Image.file(
                                File(_capturedItems.first.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isVideoMode ? Icons.videocam : Icons.camera_alt,
                                size: 80,
                                color: Colors.white24,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isVideoMode
                                    ? 'Tap below to launch Camera & Record Video'
                                    : 'Tap below to launch Camera & Take Real Photo',
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lens: ${_preferredCamera == CameraDevice.rear ? "Rear Camera" : "Front Camera"}',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        if (_isProcessing)
                          Container(
                            color: Colors.black45,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Middle Captured Strip
                if (_capturedItems.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _capturedItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = _capturedItems[index];
                        return GestureDetector(
                          onTap: () => _showImagePreview(item),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white38),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: item.isVideo
                                ? Container(
                                    color: Colors.red.shade900,
                                    child: const Center(
                                      child: Icon(Icons.play_circle_fill,
                                          color: Colors.white, size: 30),
                                    ),
                                  )
                                : Image.file(
                                    File(item.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image, color: Colors.white),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),

                // Bottom Controls
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('PHOTO'),
                            selected: !_isVideoMode,
                            onSelected: (val) => setState(() => _isVideoMode = false),
                          ),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Text('VIDEO'),
                            selected: _isVideoMode,
                            onSelected: (val) => setState(() => _isVideoMode = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                            tooltip: 'Flip Lens',
                            onPressed: _toggleCameraLens,
                          ),
                          GestureDetector(
                            onTap: _isProcessing ? null : _captureMedia,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isVideoMode ? Colors.red : Colors.white,
                                ),
                                child: Center(
                                  child: Icon(
                                    _isVideoMode ? Icons.videocam : Icons.camera_alt,
                                    color: _isVideoMode ? Colors.white : Colors.black,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Badge(
                            label: Text('${_capturedItems.length}'),
                            isLabelVisible: _capturedItems.isNotEmpty,
                            child: IconButton(
                              icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                              tooltip: 'Captured Count',
                              onPressed: _capturedItems.isEmpty
                                  ? null
                                  : () => _showImagePreview(_capturedItems.first),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
