import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../domain/permission/entities/app_permission.dart';
import '../../permission/controllers/permission_controller.dart';

class LocationDemoScreen extends ConsumerStatefulWidget {
  const LocationDemoScreen({super.key});

  @override
  ConsumerState<LocationDemoScreen> createState() => _LocationDemoScreenState();
}

class _LocationDemoScreenState extends ConsumerState<LocationDemoScreen> {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<Position>? _positionStreamSub;
  bool _isStreaming = false;

  final List<Position> _positionHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchRealGpsPosition();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchRealGpsPosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Device Location / GPS Service is turned off in device settings.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission was denied by the user.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission is permanently denied. Please enable in App Settings.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _currentPosition = position;
        _positionHistory.insert(0, position);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error querying device GPS: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleLiveGpsStream() {
    if (_isStreaming) {
      _positionStreamSub?.cancel();
      setState(() => _isStreaming = false);
    } else {
      setState(() => _isStreaming = true);
      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        ),
      ).listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _positionHistory.insert(0, position);
            });
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _isStreaming = false;
              _errorMessage = 'GPS Stream Error: $e';
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionControllerProvider);
    final isLocationGranted = state.isGranted(AppPermissionType.location);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real GPS & Coordinates'),
        actions: [
          if (isLocationGranted) ...[
            IconButton(
              icon: Icon(_isStreaming ? Icons.satellite_alt : Icons.satellite_outlined),
              tooltip: _isStreaming ? 'Stop Live GPS Stream' : 'Start Live GPS Stream',
              color: _isStreaming ? Colors.green : null,
              onPressed: _toggleLiveGpsStream,
            ),
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              tooltip: 'Query Real GPS',
              onPressed: _isLoading ? null : _fetchRealGpsPosition,
            ),
          ],
        ],
      ),
      body: !isLocationGranted
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.teal.withValues(alpha: 0.12),
                      child: const Icon(Icons.location_off_outlined,
                          size: 40, color: Colors.teal),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Location Permission Needed',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To read authentic GPS coordinates, altitude, and heading from device sensors, allow Location access.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(Icons.location_on),
                      label: const Text('Grant Location Access'),
                      onPressed: () async {
                        await ref
                            .read(permissionControllerProvider.notifier)
                            .requestPermission(AppPermissionType.location);
                        _fetchRealGpsPosition();
                      },
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Real GPS Coordinates Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.surfaceContainerHighest,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _currentPosition != null
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.orange.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.satellite_alt,
                                    size: 16,
                                    color: _currentPosition != null
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _currentPosition != null
                                      ? (_isStreaming ? 'STREAMING REAL GPS' : 'LOCKED GPS FIX')
                                      : 'ACQUIRING...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _currentPosition != null
                                        ? Colors.green
                                        : Colors.orange,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            if (_currentPosition != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '±${_currentPosition!.accuracy.toStringAsFixed(1)}m precision',
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Coordinates Display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _CoordinateCard(
                              label: 'LATITUDE',
                              value: _currentPosition != null
                                  ? '${_currentPosition!.latitude.toStringAsFixed(6)}°'
                                  : '--.------°',
                              icon: Icons.north,
                            ),
                            _CoordinateCard(
                              label: 'LONGITUDE',
                              value: _currentPosition != null
                                  ? '${_currentPosition!.longitude.toStringAsFixed(6)}°'
                                  : '--.------°',
                              icon: Icons.east,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _CoordinateCard(
                              label: 'ALTITUDE',
                              value: _currentPosition != null
                                  ? '${_currentPosition!.altitude.toStringAsFixed(1)} m'
                                  : '--.- m',
                              icon: Icons.terrain,
                            ),
                            _CoordinateCard(
                              label: 'SPEED',
                              value: _currentPosition != null
                                  ? '${_currentPosition!.speed.toStringAsFixed(1)} m/s'
                                  : '--.- m/s',
                              icon: Icons.speed,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Device GPS History (${_positionHistory.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Read GPS Now'),
                        onPressed: _fetchRealGpsPosition,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_positionHistory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No GPS fixes logged yet. Tap "Read GPS Now" above.'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _positionHistory.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final pos = _positionHistory[index];
                        return Card(
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(Icons.place_outlined,
                                  color: theme.colorScheme.primary, size: 20),
                            ),
                            title: Text(
                              '${pos.latitude.toStringAsFixed(5)}°, ${pos.longitude.toStringAsFixed(5)}°',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              'Alt: ${pos.altitude.toStringAsFixed(1)}m • Precision: ±${pos.accuracy.toStringAsFixed(1)}m',
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: Text(
                              '${pos.timestamp.hour.toString().padLeft(2, '0')}:${pos.timestamp.minute.toString().padLeft(2, '0')}:${pos.timestamp.second.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _CoordinateCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CoordinateCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
