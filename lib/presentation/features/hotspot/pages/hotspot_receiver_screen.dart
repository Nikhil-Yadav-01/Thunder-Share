import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class IncomingApp {
  final String name;
  final String packageName;
  final String versionName;
  final String sizeFormatted;
  final String downloadUrl;
  final String iconUrl;
  double progress;
  bool isDownloading;
  bool isDownloaded;
  String? localPath;

  IncomingApp({
    required this.name,
    required this.packageName,
    required this.versionName,
    required this.sizeFormatted,
    required this.downloadUrl,
    required this.iconUrl,
    this.progress = 0.0,
    this.isDownloading = false,
    this.isDownloaded = false,
    this.localPath,
  });

  factory IncomingApp.fromJson(Map<String, dynamic> json) {
    return IncomingApp(
      name: json['name'] as String? ?? 'App',
      packageName: json['packageName'] as String? ?? '',
      versionName: json['versionName'] as String? ?? '1.0',
      sizeFormatted: json['sizeFormatted'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
    );
  }
}

class HotspotReceiverScreen extends StatefulWidget {
  const HotspotReceiverScreen({super.key});

  @override
  State<HotspotReceiverScreen> createState() => _HotspotReceiverScreenState();
}

class _HotspotReceiverScreenState extends State<HotspotReceiverScreen> {
  final TextEditingController _ipController =
      TextEditingController(text: '192.168.43.1:8080');
  bool _isConnecting = false;
  String? _errorMessage;
  List<IncomingApp> _availableApps = [];

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _fetchSharedApps() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    if (kIsWeb) {
      setState(() {
        _isConnecting = false;
        _errorMessage =
            'On Web, navigate directly to http://${_ipController.text} in your browser to download files with native browser download management.';
      });
      return;
    }

    try {
      final host = _ipController.text.trim();
      final uri = Uri.parse('http://$host/api/apps');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final List<dynamic> list = jsonDecode(body);
        setState(() {
          _availableApps = list.map((e) => IncomingApp.fromJson(e)).toList();
          _isConnecting = false;
        });
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage =
            'Could not reach sender at ${_ipController.text}. Please make sure you are connected to the sender\'s Wi-Fi hotspot.';
      });
    }
  }

  Future<void> _downloadApk(IncomingApp app) async {
    setState(() {
      app.isDownloading = true;
      app.progress = 0.0;
    });

    try {
      final host = _ipController.text.trim();
      final uri = Uri.parse('http://$host${app.downloadUrl}');

      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${app.name.replaceAll(' ', '_')}.apk');
      final sink = file.openWrite();

      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0 && mounted) {
          setState(() {
            app.progress = receivedBytes / totalBytes;
          });
        }
      }

      await sink.flush();
      await sink.close();

      if (mounted) {
        setState(() {
          app.isDownloading = false;
          app.isDownloaded = true;
          app.localPath = file.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${app.name} APK downloaded successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          app.isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive via Hotspot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.wifi, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'How to connect & receive',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Connect to the same Wi-Fi network or sender\'s Hotspot on this device.'),
                    const SizedBox(height: 4),
                    const Text('2. Tap "Connect to Sender" below to load the shared APKs.'),
                    const SizedBox(height: 4),
                    const Text('3. Download files directly at 30–80 MB/s offline without internet!'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Server Address Input & Connect Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'Sender Server Address',
                      prefixIcon: const Icon(Icons.dns_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isConnecting ? null : _fetchSharedApps,
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync),
                  label: const Text('Connect'),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Shared Apps List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Files (${_availableApps.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_availableApps.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: () {
                      for (final app in _availableApps) {
                        if (!app.isDownloading && !app.isDownloaded) {
                          _downloadApk(app);
                        }
                      }
                    },
                    child: const Text('Download All'),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (_availableApps.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_download_outlined,
                        size: 56,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No files fetched yet.\nConnect to sender\'s hotspot and tap Connect.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _availableApps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final app = _availableApps[index];
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    'http://${_ipController.text.trim()}${app.iconUrl}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.android,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${app.sizeFormatted} • v${app.versionName}',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (app.isDownloaded)
                                const Chip(
                                  avatar: Icon(Icons.check, size: 16, color: Colors.green),
                                  label: Text('Saved', style: TextStyle(color: Colors.green)),
                                  backgroundColor: Colors.transparent,
                                )
                              else if (app.isDownloading)
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    value: app.progress > 0 ? app.progress : null,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              else
                                FilledButton(
                                  onPressed: () => _downloadApk(app),
                                  child: const Text('Download'),
                                ),
                            ],
                          ),
                          if (app.isDownloading && app.progress > 0) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: app.progress,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ],
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
