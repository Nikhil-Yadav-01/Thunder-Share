import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../domain/permission/entities/app_permission.dart';
import '../../permission/controllers/permission_controller.dart';

class RealAudioRecording {
  final String path;
  final String filename;
  final int sizeInBytes;
  final DateTime createdAt;
  Duration duration;

  RealAudioRecording({
    required this.path,
    required this.filename,
    required this.sizeInBytes,
    required this.createdAt,
    this.duration = Duration.zero,
  });
}

class AudioRecorderDemoScreen extends ConsumerStatefulWidget {
  const AudioRecorderDemoScreen({super.key});

  @override
  ConsumerState<AudioRecorderDemoScreen> createState() =>
      _AudioRecorderDemoScreenState();
}

class _AudioRecorderDemoScreenState extends ConsumerState<AudioRecorderDemoScreen> {
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  Timer? _waveTimer;

  String? _currentlyPlayingPath;
  PlayerState _playerState = PlayerState.stopped;

  final List<double> _waveformHeights = List.generate(24, (_) => 10.0);
  final List<RealAudioRecording> _recordings = [];

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == PlayerState.completed || state == PlayerState.stopped) {
            _currentlyPlayingPath = null;
          }
        });
      }
    });

    _loadExistingRecordings();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _waveTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRecordings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final entities = dir.listSync();
      final List<RealAudioRecording> loaded = [];

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.m4a')) {
          final stat = entity.statSync();
          loaded.add(
            RealAudioRecording(
              path: entity.path,
              filename: entity.path.split(Platform.pathSeparator).last,
              sizeInBytes: stat.size,
              createdAt: stat.modified,
            ),
          );
        }
      }

      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _recordings.addAll(loaded);
        });
      }
    } catch (_) {}
  }

  Future<void> _startRealRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied by system')),
          );
        }
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.path}/recording_$timestamp.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });

      _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) {
          final rand = Random();
          setState(() {
            for (int i = 0; i < _waveformHeights.length; i++) {
              _waveformHeights[i] = 8.0 + rand.nextDouble() * 52.0;
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRealRecording() async {
    _recordTimer?.cancel();
    _waveTimer?.cancel();

    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        final bytes = await file.length();
        final newRec = RealAudioRecording(
          path: path,
          filename: path.split(Platform.pathSeparator).last,
          sizeInBytes: bytes,
          createdAt: DateTime.now(),
          duration: Duration(seconds: _recordSeconds),
        );

        setState(() {
          _recordings.insert(0, newRec);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio saved to disk: ${newRec.filename} (${(bytes / 1024).toStringAsFixed(1)} KB)'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordSeconds = 0;
          for (int i = 0; i < _waveformHeights.length; i++) {
            _waveformHeights[i] = 10.0;
          }
        });
      }
    }
  }

  Future<void> _playRecording(RealAudioRecording item) async {
    if (_currentlyPlayingPath == item.path && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      _currentlyPlayingPath = item.path;
      await _audioPlayer.play(DeviceFileSource(item.path));
    }
  }

  Future<void> _deleteRecording(RealAudioRecording item) async {
    if (_currentlyPlayingPath == item.path) {
      await _audioPlayer.stop();
    }

    try {
      final file = File(item.path);
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        _recordings.removeWhere((r) => r.path == item.path);
      });
    } catch (_) {}
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionControllerProvider);
    final isMicGranted = state.isGranted(AppPermissionType.microphone);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Audio Recorder'),
      ),
      body: !isMicGranted
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                      child: const Icon(Icons.mic_off, size: 40, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Microphone Access Needed',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To record genuine physical audio files and store them on your device, allow Microphone access.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(Icons.mic),
                      label: const Text('Grant Microphone Access'),
                      onPressed: () {
                        ref
                            .read(permissionControllerProvider.notifier)
                            .requestPermission(AppPermissionType.microphone);
                      },
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Real Recording Box
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isRecording
                          ? Colors.redAccent.withValues(alpha: 0.6)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _isRecording ? Colors.red : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isRecording ? 'LIVE RECORDING' : 'IDLE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isRecording
                                      ? Colors.red
                                      : theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatDuration(_recordSeconds),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Animated Waveform
                      SizedBox(
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: _waveformHeights.map((h) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 6,
                              height: h,
                              decoration: BoxDecoration(
                                color: _isRecording
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Record / Stop Button
                      GestureDetector(
                        onTap: _isRecording ? _stopRealRecording : _startRealRecording,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording ? Colors.red : theme.colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording
                                        ? Colors.red
                                        : theme.colorScheme.primary)
                                    .withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recorded Audio Files on Disk
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved Audio Files (${_recordings.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stored on device disk',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _recordings.isEmpty
                      ? Center(
                          child: Text(
                            'No recorded audio files on disk yet.\nTap mic to record physical audio.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _recordings.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _recordings[index];
                            final isPlayingThis =
                                _currentlyPlayingPath == item.path &&
                                _playerState == PlayerState.playing;

                            return Card(
                              elevation: 0,
                              color: theme.colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isPlayingThis
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isPlayingThis
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surfaceContainerHighest,
                                  child: IconButton(
                                    icon: Icon(
                                      isPlayingThis ? Icons.pause : Icons.play_arrow,
                                      color: isPlayingThis
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                    ),
                                    onPressed: () => _playRecording(item),
                                  ),
                                ),
                                title: Text(
                                  item.filename,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${(item.sizeInBytes / 1024).toStringAsFixed(1)} KB • ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  tooltip: 'Delete file from disk',
                                  onPressed: () => _deleteRecording(item),
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
