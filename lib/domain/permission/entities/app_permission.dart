import 'package:flutter/material.dart';

enum AppPermissionCategory {
  hardware('Device & Hardware'),
  media('Photos & Media'),
  system('Apps & System');

  final String label;
  const AppPermissionCategory(this.label);
}

enum AppPermissionType {
  // Device & Hardware
  camera,
  microphone,
  location,

  // Photos & Media
  photos,
  videos,
  mediaLibrary,
  audio,
  storage,
  manageExternalStorage,

  // Apps & System
  appTrackingTransparency,
  systemAlertWindow,
  requestInstallPackages,
  notification;

  String get displayName {
    switch (this) {
      case AppPermissionType.camera:
        return 'Camera';
      case AppPermissionType.microphone:
        return 'Microphone';
      case AppPermissionType.location:
        return 'Location';
      case AppPermissionType.photos:
        return 'Photos / Gallery';
      case AppPermissionType.videos:
        return 'Videos';
      case AppPermissionType.mediaLibrary:
        return 'Media Library';
      case AppPermissionType.audio:
        return 'Audio / Music';
      case AppPermissionType.storage:
        return 'Storage (Read / Write)';
      case AppPermissionType.manageExternalStorage:
        return 'Manage All Files';
      case AppPermissionType.appTrackingTransparency:
        return 'App Tracking Transparency';
      case AppPermissionType.systemAlertWindow:
        return 'Display Over Other Apps';
      case AppPermissionType.requestInstallPackages:
        return 'Install Unknown Apps';
      case AppPermissionType.notification:
        return 'Push Notifications';
    }
  }

  String get description {
    switch (this) {
      case AppPermissionType.camera:
        return 'Allows capturing photos, recording video, and scanning codes.';
      case AppPermissionType.microphone:
        return 'Allows recording audio, voice notes, and voice communication.';
      case AppPermissionType.location:
        return 'Allows access to precise and approximate device location.';
      case AppPermissionType.photos:
        return 'Allows browsing and selecting images from the device gallery.';
      case AppPermissionType.videos:
        return 'Allows selecting and playing video files from device storage.';
      case AppPermissionType.mediaLibrary:
        return 'Allows access to Apple Music, playback queue, and media items.';
      case AppPermissionType.audio:
        return 'Allows accessing audio tracks and music files on the device.';
      case AppPermissionType.storage:
        return 'Allows reading and writing files in external storage.';
      case AppPermissionType.manageExternalStorage:
        return 'Allows broad access to manage and modify files across storage.';
      case AppPermissionType.appTrackingTransparency:
        return 'Allows tracking app activity for personalized user experience.';
      case AppPermissionType.systemAlertWindow:
        return 'Allows drawing floating overlays on top of other running applications.';
      case AppPermissionType.requestInstallPackages:
        return 'Allows initiating APK installation packages directly from the app.';
      case AppPermissionType.notification:
        return 'Allows sending alert banners, sound notifications, and badges.';
    }
  }

  IconData get icon {
    switch (this) {
      case AppPermissionType.camera:
        return Icons.camera_alt_outlined;
      case AppPermissionType.microphone:
        return Icons.mic_none_outlined;
      case AppPermissionType.location:
        return Icons.location_on_outlined;
      case AppPermissionType.photos:
        return Icons.photo_library_outlined;
      case AppPermissionType.videos:
        return Icons.video_library_outlined;
      case AppPermissionType.mediaLibrary:
        return Icons.perm_media_outlined;
      case AppPermissionType.audio:
        return Icons.library_music_outlined;
      case AppPermissionType.storage:
        return Icons.folder_outlined;
      case AppPermissionType.manageExternalStorage:
        return Icons.manage_accounts_outlined;
      case AppPermissionType.appTrackingTransparency:
        return Icons.track_changes_outlined;
      case AppPermissionType.systemAlertWindow:
        return Icons.picture_in_picture_alt_outlined;
      case AppPermissionType.requestInstallPackages:
        return Icons.apps_outlined;
      case AppPermissionType.notification:
        return Icons.notifications_active_outlined;
    }
  }

  AppPermissionCategory get category {
    switch (this) {
      case AppPermissionType.camera:
      case AppPermissionType.microphone:
      case AppPermissionType.location:
        return AppPermissionCategory.hardware;
      case AppPermissionType.photos:
      case AppPermissionType.videos:
      case AppPermissionType.mediaLibrary:
      case AppPermissionType.audio:
      case AppPermissionType.storage:
      case AppPermissionType.manageExternalStorage:
        return AppPermissionCategory.media;
      case AppPermissionType.appTrackingTransparency:
      case AppPermissionType.systemAlertWindow:
      case AppPermissionType.requestInstallPackages:
      case AppPermissionType.notification:
        return AppPermissionCategory.system;
    }
  }

  String? get platformTag {
    switch (this) {
      case AppPermissionType.appTrackingTransparency:
        return 'iOS 14.5+';
      case AppPermissionType.mediaLibrary:
        return 'iOS Only';
      case AppPermissionType.storage:
        return 'Android ≤ 12';
      case AppPermissionType.manageExternalStorage:
        return 'Android 11+';
      case AppPermissionType.systemAlertWindow:
        return 'Android Only';
      case AppPermissionType.requestInstallPackages:
        return 'Android Only';
      default:
        return null;
    }
  }

  bool isSupportedOnPlatform(TargetPlatform platform, {bool isWeb = false}) {
    if (isWeb) return false;
    switch (this) {
      case AppPermissionType.appTrackingTransparency:
      case AppPermissionType.mediaLibrary:
        return platform == TargetPlatform.iOS;
      case AppPermissionType.systemAlertWindow:
      case AppPermissionType.requestInstallPackages:
      case AppPermissionType.manageExternalStorage:
        return platform == TargetPlatform.android;
      default:
        return true;
    }
  }

  String? unsupportedExplanation(TargetPlatform platform) {
    if (this == AppPermissionType.appTrackingTransparency &&
        platform == TargetPlatform.android) {
      return 'App Tracking Transparency is an Apple iOS exclusive feature (iOS 14.5+).\n\n'
          'Android does not use Apple\'s ATT framework, so this permission cannot be requested or granted on Android devices.';
    }
    if (this == AppPermissionType.mediaLibrary &&
        platform == TargetPlatform.android) {
      return 'Media Library (Apple Music) is an iOS exclusive permission.\n\n'
          'On Android, use the Audio / Music permission instead.';
    }
    if ((this == AppPermissionType.systemAlertWindow ||
            this == AppPermissionType.requestInstallPackages ||
            this == AppPermissionType.manageExternalStorage) &&
        platform == TargetPlatform.iOS) {
      return '$displayName is an Android-specific feature and is not available on iOS.';
    }
    return null;
  }
}

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
  unknown,
  notApplicable;

  String get label {
    switch (this) {
      case AppPermissionStatus.granted:
        return 'Granted';
      case AppPermissionStatus.denied:
        return 'Denied';
      case AppPermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case AppPermissionStatus.restricted:
        return 'Restricted';
      case AppPermissionStatus.limited:
        return 'Limited';
      case AppPermissionStatus.provisional:
        return 'Provisional';
      case AppPermissionStatus.unknown:
        return 'Unknown';
      case AppPermissionStatus.notApplicable:
        return 'Not Supported';
    }
  }
}

class AppPermission {
  final AppPermissionType type;
  final AppPermissionStatus status;

  const AppPermission({
    required this.type,
    required this.status,
  });

  bool get isGranted => status == AppPermissionStatus.granted;
  bool get isPermanentlyDenied =>
      status == AppPermissionStatus.permanentlyDenied;
  bool get isDenied => status == AppPermissionStatus.denied;
  bool get isLimited => status == AppPermissionStatus.limited;
  bool get isRestricted => status == AppPermissionStatus.restricted;
  bool get isNotApplicable => status == AppPermissionStatus.notApplicable;
}
