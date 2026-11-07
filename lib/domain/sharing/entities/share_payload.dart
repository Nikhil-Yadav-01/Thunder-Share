import 'dart:typed_data';
import '../../../domain/apps/entities/device_app_info.dart';

/// Base abstract entity for anything that can be shared across the local network.
/// Designed for easy future expansion to Photos, Videos, Documents, and Folders.
abstract class SharePayload {
  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;
  final Uint8List? iconBytes;

  const SharePayload({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    this.iconBytes,
  });

  String get formattedSize {
    if (sizeBytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = sizeBytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Map<String, dynamic> toJson();
}

/// Active implementation: Installed Device App (APK)
class AppSharePayload extends SharePayload {
  final DeviceAppInfo appInfo;

  AppSharePayload({
    required this.appInfo,
    super.iconBytes,
  }) : super(
          id: appInfo.packageName,
          name: appInfo.name,
          sizeBytes: appInfo.apkSizeBytes,
          mimeType: 'application/vnd.android.package-archive',
        );

  String get packageName => appInfo.packageName;
  String get versionName => appInfo.versionName;
  int get versionCode => appInfo.versionCode;
  String get apkFilePath => appInfo.apkFilePath;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'app',
      'name': name,
      'packageName': packageName,
      'versionName': versionName,
      'versionCode': versionCode,
      'sizeBytes': sizeBytes,
      'sizeFormatted': formattedSize,
      'downloadUrl': '/download/$packageName',
      'iconUrl': '/icon/$packageName',
    };
  }
}

/// Extensible implementation for future media/file sharing
class FileSharePayload extends SharePayload {
  final String localPath;

  const FileSharePayload({
    required super.id,
    required super.name,
    required super.sizeBytes,
    required super.mimeType,
    required this.localPath,
    super.iconBytes,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'file',
      'name': name,
      'sizeBytes': sizeBytes,
      'sizeFormatted': formattedSize,
      'downloadUrl': '/download/$id',
      'mimeType': mimeType,
    };
  }
}
