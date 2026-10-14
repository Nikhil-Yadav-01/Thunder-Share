import 'dart:typed_data';

class DeviceAppInfo {
  final String name;
  final String packageName;
  final String versionName;
  final int versionCode;
  final String apkFilePath;
  final int apkSizeBytes;
  final int installedTimestamp;
  final int updatedTimestamp;
  final int minSdk;
  final int targetSdk;
  final bool isSystemApp;
  final List<String> permissions;
  final Uint8List? iconBytes;

  const DeviceAppInfo({
    required this.name,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.apkFilePath,
    required this.apkSizeBytes,
    required this.installedTimestamp,
    required this.updatedTimestamp,
    required this.minSdk,
    required this.targetSdk,
    required this.isSystemApp,
    this.permissions = const [],
    this.iconBytes,
  });

  DeviceAppInfo copyWith({
    String? name,
    String? packageName,
    String? versionName,
    int? versionCode,
    String? apkFilePath,
    int? apkSizeBytes,
    int? installedTimestamp,
    int? updatedTimestamp,
    int? minSdk,
    int? targetSdk,
    bool? isSystemApp,
    List<String>? permissions,
    Uint8List? iconBytes,
  }) {
    return DeviceAppInfo(
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      apkFilePath: apkFilePath ?? this.apkFilePath,
      apkSizeBytes: apkSizeBytes ?? this.apkSizeBytes,
      installedTimestamp: installedTimestamp ?? this.installedTimestamp,
      updatedTimestamp: updatedTimestamp ?? this.updatedTimestamp,
      minSdk: minSdk ?? this.minSdk,
      targetSdk: targetSdk ?? this.targetSdk,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      permissions: permissions ?? this.permissions,
      iconBytes: iconBytes ?? this.iconBytes,
    );
  }

  factory DeviceAppInfo.fromMap(Map<dynamic, dynamic> map, {Uint8List? iconBytes}) {
    return DeviceAppInfo(
      name: (map['name'] as String?)?.isNotEmpty == true
          ? map['name'] as String
          : (map['packageName'] as String? ?? 'Unknown App'),
      packageName: map['packageName'] as String? ?? '',
      versionName: map['versionName'] as String? ?? '',
      versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
      apkFilePath: map['apkFilePath'] as String? ?? '',
      apkSizeBytes: (map['apkSizeBytes'] as num?)?.toInt() ?? 0,
      installedTimestamp: (map['installedTimestamp'] as num?)?.toInt() ?? 0,
      updatedTimestamp: (map['updatedTimestamp'] as num?)?.toInt() ?? 0,
      minSdk: (map['minSdk'] as num?)?.toInt() ?? 0,
      targetSdk: (map['targetSdk'] as num?)?.toInt() ?? 0,
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      permissions: (map['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      iconBytes: iconBytes,
    );
  }

  String get formattedSize {
    if (apkSizeBytes <= 0) return 'Unknown size';
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (apkSizeBytes >= gb) {
      return '${(apkSizeBytes / gb).toStringAsFixed(2)} GB';
    } else if (apkSizeBytes >= mb) {
      return '${(apkSizeBytes / mb).toStringAsFixed(1)} MB';
    } else {
      return '${(apkSizeBytes / kb).toStringAsFixed(1)} KB';
    }
  }

  String get formattedInstallDate {
    if (installedTimestamp <= 0) return 'Pre-installed';
    final date = DateTime.fromMillisecondsSinceEpoch(installedTimestamp);
    return _formatDate(date);
  }

  String get formattedUpdateDate {
    if (updatedTimestamp <= 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(updatedTimestamp);
    return _formatDate(date);
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day $m $y, $h:$min';
  }

  String get playStoreUrl =>
      'https://play.google.com/store/apps/details?id=$packageName';

  bool get hasValidApk => apkFilePath.isNotEmpty && apkSizeBytes > 0;
}
