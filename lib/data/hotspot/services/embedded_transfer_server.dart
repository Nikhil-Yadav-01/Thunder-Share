import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../domain/apps/entities/device_app_info.dart';
import '../../../domain/sharing/entities/share_payload.dart';

class EmbeddedTransferServer {
  HttpServer? _server;
  List<SharePayload> _hostedPayloads = [];
  Map<String, Uint8List> _appIcons = {};
  int _downloadCount = 0;

  int get port => _server?.port ?? 8080;
  bool get isRunning => _server != null;
  int get downloadCount => _downloadCount;
  List<SharePayload> get hostedPayloads => _hostedPayloads;

  /// Starts the embedded HTTP server.
  /// On Web, runs in safe simulation preview without attempting socket binding.
  Future<int> start({
    List<DeviceAppInfo> apps = const [],
    List<SharePayload>? payloads,
    Map<String, Uint8List> appIcons = const {},
    int port = 8080,
  }) async {
    await stop();

    // Map apps to extensible SharePayloads if payloads not explicitly provided
    if (payloads != null) {
      _hostedPayloads = payloads;
    } else {
      _hostedPayloads = apps
          .map((app) => AppSharePayload(
                appInfo: app,
                iconBytes: appIcons[app.packageName],
              ))
          .toList();
    }

    _appIcons = appIcons;
    _downloadCount = 0;

    // Web browsers cannot bind raw TCP listening sockets
    if (kIsWeb) {
      return port;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } catch (e) {
      // If preferred port is busy, bind to any available ephemeral port
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    }

    _server!.listen(_handleRequest, onError: (e) {
      debugPrint('EmbeddedTransferServer error: $e');
    });

    return _server!.port;
  }

  Future<void> stop() async {
    if (kIsWeb) {
      _hostedPayloads = [];
      _appIcons = {};
      return;
    }
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _hostedPayloads = [];
    _appIcons = {};
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final response = request.response;

    // CORS headers for local network compatibility
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    try {
      if (path == '/' || path == '/index.html') {
        _serveWebPortal(response);
      } else if (path == '/api/apps' || path == '/api/files') {
        _servePayloadsJson(response);
      } else if (path == '/api/ping') {
        response.headers.contentType = ContentType.json;
        response.write(jsonEncode({'status': 'ok', 'count': _hostedPayloads.length}));
        await response.close();
      } else if (path.startsWith('/download/')) {
        final id = path.replaceFirst('/download/', '');
        await _serveDownload(id, response);
      } else if (path.startsWith('/icon/')) {
        final pkg = path.replaceFirst('/icon/', '');
        _serveIcon(pkg, response);
      } else {
        response.statusCode = HttpStatus.notFound;
        response.write('Not found');
        await response.close();
      }
    } catch (e) {
      debugPrint('Error serving request $path: $e');
      try {
        response.statusCode = HttpStatus.internalServerError;
        response.write('Internal Server Error: $e');
        await response.close();
      } catch (_) {}
    }
  }

  void _servePayloadsJson(HttpResponse response) {
    response.headers.contentType = ContentType.json;
    final list = _hostedPayloads.map((p) => p.toJson()).toList();
    response.write(jsonEncode(list));
    response.close();
  }

  Future<void> _serveDownload(String id, HttpResponse response) async {
    final payload = _hostedPayloads.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Item not found: $id'),
    );

    String? filePath;
    String downloadFileName = '${payload.name}.apk';

    if (payload is AppSharePayload) {
      filePath = payload.apkFilePath;
      downloadFileName = '${payload.name.replaceAll(' ', '_')}.apk';
    } else if (payload is FileSharePayload) {
      filePath = payload.localPath;
      downloadFileName = payload.name;
    }

    if (filePath == null) {
      response.statusCode = HttpStatus.notFound;
      response.write('File path not available');
      await response.close();
      return;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      response.statusCode = HttpStatus.notFound;
      response.write('File not found on host storage: $filePath');
      await response.close();
      return;
    }

    final length = file.lengthSync();
    _downloadCount++;

    response.statusCode = HttpStatus.ok;
    response.headers.set(
      HttpHeaders.contentTypeHeader,
      payload.mimeType,
    );
    response.headers.set(HttpHeaders.contentLengthHeader, length.toString());
    response.headers.set(
      'Content-Disposition',
      'attachment; filename="$downloadFileName"',
    );

    await response.addStream(file.openRead());
    await response.close();
  }

  void _serveIcon(String packageName, HttpResponse response) {
    final bytes = _appIcons[packageName];
    if (bytes != null && bytes.isNotEmpty) {
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType('image', 'png');
      response.add(bytes);
      response.close();
    } else {
      response.statusCode = HttpStatus.notFound;
      response.close();
    }
  }

  void _serveWebPortal(HttpResponse response) {
    response.headers.contentType = ContentType.html;

    final rowsHtml = _hostedPayloads.map((payload) {
      final subtitle = payload is AppSharePayload
          ? '${payload.packageName} • v${payload.versionName}'
          : payload.mimeType;

      return '''
      <div class="card">
        <div class="icon-wrap">
          <img src="/icon/${payload.id}" alt="${payload.name}" onerror="this.src='data:image/svg+xml;utf8,<svg xmlns=\\'http://www.w3.org/2000/svg\\' viewBox=\\'0 0 24 24\\' fill=\\'%236200ee\\'><path d=\\'M12 2a10 10 0 100 20 10 10 0 000-20zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z\\'/></svg>'"/>
        </div>
        <div class="meta">
          <div class="title">${payload.name}</div>
          <div class="subtitle">$subtitle</div>
          <div class="badge">${payload.formattedSize}</div>
        </div>
        <a class="btn-download" href="/download/${payload.id}" download>
          Download APK
        </a>
      </div>
      ''';
    }).join('\n');

    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DirectShare Offline Portal</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    body { background: #0f172a; color: #f8fafc; padding: 20px 16px 40px; }
    .header { text-align: center; margin-bottom: 24px; padding-top: 10px; }
    .header h1 { font-size: 24px; font-weight: 800; color: #38bdf8; display: flex; align-items: center; justify-content: center; gap: 8px; }
    .header p { color: #94a3b8; font-size: 13px; margin-top: 6px; }
    .summary { background: #1e293b; border-radius: 12px; padding: 12px 16px; margin-bottom: 20px; font-size: 13px; color: #cbd5e1; display: flex; justify-content: space-between; border: 1px solid #334155; }
    .card { background: #1e293b; border: 1px solid #334155; border-radius: 16px; padding: 14px; margin-bottom: 12px; display: flex; align-items: center; gap: 14px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.2); }
    .icon-wrap { width: 52px; height: 52px; border-radius: 12px; background: #334155; overflow: hidden; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
    .icon-wrap img { width: 100%; height: 100%; object-fit: cover; }
    .meta { flex: 1; min-width: 0; }
    .title { font-weight: 700; font-size: 15px; color: #ffffff; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .subtitle { font-size: 11px; color: #94a3b8; margin: 2px 0 4px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .badge { display: inline-block; background: #0284c7; color: #ffffff; font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: 6px; }
    .btn-download { background: #38bdf8; color: #0f172a; font-weight: 700; font-size: 12px; text-decoration: none; padding: 10px 14px; border-radius: 10px; flex-shrink: 0; display: inline-block; text-align: center; }
    .btn-download:hover { background: #7dd3fc; }
    .footer { text-align: center; margin-top: 28px; color: #64748b; font-size: 12px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>⚡ DirectShare Portal</h1>
    <p>High-speed offline file transfer via local Wi-Fi / Hotspot</p>
  </div>
  <div class="summary">
    <span>Ready to transfer: <strong>${_hostedPayloads.length} Items</strong></span>
    <span>No internet needed</span>
  </div>
  <div class="apps-list">
    $rowsHtml
  </div>
  <div class="footer">
    Connected to sender • Download directly to this device
  </div>
</body>
</html>
    ''';

    response.write(html);
    response.close();
  }
}
