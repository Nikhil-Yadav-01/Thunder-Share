import 'package:flutter/material.dart';

enum PermissionRequestArchetype {
  systemModal('System In-App Dialog'),
  settingsRedirect('Settings Redirect Intent'),
  multiStep('Progressive Multi-Step');

  final String label;
  const PermissionRequestArchetype(this.label);
}

enum AppPermissionCategory {
  connectivity('Bluetooth & Network'),
  communication('Contacts & Comms'),
  location('Location & Motion'),
  hardware('Device & Sensors'),
  media('Photos & Media'),
  storage('Files & Storage'),
  system('Apps & System');

  final String label;
  const AppPermissionCategory(this.label);
}

enum AppPermissionType {
  // Device & Sensors
  camera,
  microphone,
  sensors,
  sensorsAlways,

  // Location & Motion
  location,
  locationAlways,
  activityRecognition,

  // Photos & Media
  photos,
  videos,
  audio,
  mediaLibrary,
  accessMediaLocation,

  // Files & Storage
  storage,
  manageExternalStorage,

  // Bluetooth & Network
  bluetoothScan,
  bluetoothConnect,
  bluetoothAdvertise,
  nearbyWifiDevices,
  bluetooth,

  // Contacts & Communication
  contacts,
  calendar,
  reminders,
  phone,
  sms,
  speech,

  // Apps, System & Special Access
  notification,
  scheduleExactAlarm,
  systemAlertWindow,
  requestInstallPackages,
  ignoreBatteryOptimizations,
  accessNotificationPolicy,
  appTrackingTransparency;

  String get displayName {
    switch (this) {
      case AppPermissionType.camera:
        return 'Camera';
      case AppPermissionType.microphone:
        return 'Microphone';
      case AppPermissionType.sensors:
        return 'Body Sensors';
      case AppPermissionType.sensorsAlways:
        return 'Background Body Sensors';
      case AppPermissionType.location:
        return 'Location (When In Use)';
      case AppPermissionType.locationAlways:
        return 'Location (Always / Background)';
      case AppPermissionType.activityRecognition:
        return 'Activity Recognition / Motion';
      case AppPermissionType.photos:
        return 'Photos / Gallery';
      case AppPermissionType.videos:
        return 'Videos';
      case AppPermissionType.audio:
        return 'Audio / Music';
      case AppPermissionType.mediaLibrary:
        return 'Media Library';
      case AppPermissionType.accessMediaLocation:
        return 'Media Location (Exif GPS)';
      case AppPermissionType.storage:
        return 'Storage (Legacy Read / Write)';
      case AppPermissionType.manageExternalStorage:
        return 'Manage All Files';
      case AppPermissionType.bluetoothScan:
        return 'Bluetooth Scan';
      case AppPermissionType.bluetoothConnect:
        return 'Bluetooth Connect';
      case AppPermissionType.bluetoothAdvertise:
        return 'Bluetooth Advertise';
      case AppPermissionType.nearbyWifiDevices:
        return 'Nearby Wi-Fi Devices';
      case AppPermissionType.bluetooth:
        return 'Bluetooth (Legacy / General)';
      case AppPermissionType.contacts:
        return 'Contacts / Address Book';
      case AppPermissionType.calendar:
        return 'Calendar Events';
      case AppPermissionType.reminders:
        return 'Reminders';
      case AppPermissionType.phone:
        return 'Phone & Calls';
      case AppPermissionType.sms:
        return 'SMS Messages';
      case AppPermissionType.speech:
        return 'Speech Recognition';
      case AppPermissionType.notification:
        return 'Push Notifications';
      case AppPermissionType.scheduleExactAlarm:
        return 'Schedule Exact Alarms';
      case AppPermissionType.systemAlertWindow:
        return 'Display Over Other Apps';
      case AppPermissionType.requestInstallPackages:
        return 'Install Unknown Apps';
      case AppPermissionType.ignoreBatteryOptimizations:
        return 'Ignore Battery Optimization';
      case AppPermissionType.accessNotificationPolicy:
        return 'Do Not Disturb Policy';
      case AppPermissionType.appTrackingTransparency:
        return 'App Tracking Transparency';
    }
  }

  String get description {
    switch (this) {
      case AppPermissionType.camera:
        return 'Allows capturing photos, recording video, and scanning barcodes.';
      case AppPermissionType.microphone:
        return 'Allows recording voice notes and microphone audio streams.';
      case AppPermissionType.sensors:
        return 'Allows accessing body sensors such as heart rate monitors.';
      case AppPermissionType.sensorsAlways:
        return 'Allows collecting body sensor data while running in the background.';
      case AppPermissionType.location:
        return 'Allows access to approximate and precise GPS device location.';
      case AppPermissionType.locationAlways:
        return 'Allows background geofencing and continuous location tracking.';
      case AppPermissionType.activityRecognition:
        return 'Allows detecting physical activity like walking, biking, and driving.';
      case AppPermissionType.photos:
        return 'Allows browsing and selecting pictures from the device gallery.';
      case AppPermissionType.videos:
        return 'Allows selecting and playing video files from device storage.';
      case AppPermissionType.audio:
        return 'Allows reading and playing music and audio tracks on device.';
      case AppPermissionType.mediaLibrary:
        return 'Allows access to Apple Music library and playback queue.';
      case AppPermissionType.accessMediaLocation:
        return 'Allows reading geographic metadata (Exif GPS coordinates) in images.';
      case AppPermissionType.storage:
        return 'Allows reading and writing files in external storage (Android ≤ 12).';
      case AppPermissionType.manageExternalStorage:
        return 'Allows broad access to manage, rename, and delete all device files.';
      case AppPermissionType.bluetoothScan:
        return 'Allows discovering nearby Bluetooth Low Energy peripherals without location.';
      case AppPermissionType.bluetoothConnect:
        return 'Allows connecting and communicating with paired Bluetooth devices.';
      case AppPermissionType.bluetoothAdvertise:
        return 'Allows broadcasting this device as a Bluetooth peripheral.';
      case AppPermissionType.nearbyWifiDevices:
        return 'Allows discovering and connecting to nearby local Wi-Fi devices directly.';
      case AppPermissionType.bluetooth:
        return 'General Bluetooth access for Android ≤ 11 and iOS devices.';
      case AppPermissionType.contacts:
        return 'Allows reading and managing device contacts and address book.';
      case AppPermissionType.calendar:
        return 'Allows viewing, adding, and scheduling calendar events.';
      case AppPermissionType.reminders:
        return 'Allows reading and adding to user reminders and task lists.';
      case AppPermissionType.phone:
        return 'Allows placing phone calls and reading current cellular telephony status.';
      case AppPermissionType.sms:
        return 'Allows sending, reading, and receiving SMS text messages.';
      case AppPermissionType.speech:
        return 'Allows transcribing live spoken speech into text.';
      case AppPermissionType.notification:
        return 'Allows posting alert banners, sounds, and lockscreen badges.';
      case AppPermissionType.scheduleExactAlarm:
        return 'Allows scheduling precise time-sensitive reminders and alarm timers.';
      case AppPermissionType.systemAlertWindow:
        return 'Allows drawing floating overlays and bubbles on top of other applications.';
      case AppPermissionType.requestInstallPackages:
        return 'Allows initiating APK installation packages directly from within the app.';
      case AppPermissionType.ignoreBatteryOptimizations:
        return 'Prevents OS from killing background tasks during deep sleep (Doze mode).';
      case AppPermissionType.accessNotificationPolicy:
        return 'Allows reading and toggling Do Not Disturb mode and audio priorities.';
      case AppPermissionType.appTrackingTransparency:
        return 'Allows tracking app activity across other apps and websites (Apple ATT).';
    }
  }

  IconData get icon {
    switch (this) {
      case AppPermissionType.camera:
        return Icons.camera_alt_outlined;
      case AppPermissionType.microphone:
        return Icons.mic_none_outlined;
      case AppPermissionType.sensors:
        return Icons.favorite_border_rounded;
      case AppPermissionType.sensorsAlways:
        return Icons.monitor_heart_outlined;
      case AppPermissionType.location:
        return Icons.location_on_outlined;
      case AppPermissionType.locationAlways:
        return Icons.share_location_outlined;
      case AppPermissionType.activityRecognition:
        return Icons.directions_run_outlined;
      case AppPermissionType.photos:
        return Icons.photo_library_outlined;
      case AppPermissionType.videos:
        return Icons.video_library_outlined;
      case AppPermissionType.audio:
        return Icons.library_music_outlined;
      case AppPermissionType.mediaLibrary:
        return Icons.perm_media_outlined;
      case AppPermissionType.accessMediaLocation:
        return Icons.add_location_alt_outlined;
      case AppPermissionType.storage:
        return Icons.folder_outlined;
      case AppPermissionType.manageExternalStorage:
        return Icons.manage_accounts_outlined;
      case AppPermissionType.bluetoothScan:
        return Icons.bluetooth_searching;
      case AppPermissionType.bluetoothConnect:
        return Icons.bluetooth_connected;
      case AppPermissionType.bluetoothAdvertise:
        return Icons.settings_input_antenna_outlined;
      case AppPermissionType.nearbyWifiDevices:
        return Icons.wifi_tethering_outlined;
      case AppPermissionType.bluetooth:
        return Icons.bluetooth;
      case AppPermissionType.contacts:
        return Icons.contacts_outlined;
      case AppPermissionType.calendar:
        return Icons.calendar_month_outlined;
      case AppPermissionType.reminders:
        return Icons.checklist_outlined;
      case AppPermissionType.phone:
        return Icons.phone_outlined;
      case AppPermissionType.sms:
        return Icons.sms_outlined;
      case AppPermissionType.speech:
        return Icons.record_voice_over_outlined;
      case AppPermissionType.notification:
        return Icons.notifications_active_outlined;
      case AppPermissionType.scheduleExactAlarm:
        return Icons.alarm_outlined;
      case AppPermissionType.systemAlertWindow:
        return Icons.picture_in_picture_alt_outlined;
      case AppPermissionType.requestInstallPackages:
        return Icons.apps_outlined;
      case AppPermissionType.ignoreBatteryOptimizations:
        return Icons.battery_saver_outlined;
      case AppPermissionType.accessNotificationPolicy:
        return Icons.do_not_disturb_on_outlined;
      case AppPermissionType.appTrackingTransparency:
        return Icons.track_changes_outlined;
    }
  }

  AppPermissionCategory get category {
    switch (this) {
      case AppPermissionType.camera:
      case AppPermissionType.microphone:
      case AppPermissionType.sensors:
      case AppPermissionType.sensorsAlways:
        return AppPermissionCategory.hardware;

      case AppPermissionType.location:
      case AppPermissionType.locationAlways:
      case AppPermissionType.activityRecognition:
        return AppPermissionCategory.location;

      case AppPermissionType.photos:
      case AppPermissionType.videos:
      case AppPermissionType.audio:
      case AppPermissionType.mediaLibrary:
      case AppPermissionType.accessMediaLocation:
        return AppPermissionCategory.media;

      case AppPermissionType.storage:
      case AppPermissionType.manageExternalStorage:
        return AppPermissionCategory.storage;

      case AppPermissionType.bluetoothScan:
      case AppPermissionType.bluetoothConnect:
      case AppPermissionType.bluetoothAdvertise:
      case AppPermissionType.nearbyWifiDevices:
      case AppPermissionType.bluetooth:
        return AppPermissionCategory.connectivity;

      case AppPermissionType.contacts:
      case AppPermissionType.calendar:
      case AppPermissionType.reminders:
      case AppPermissionType.phone:
      case AppPermissionType.sms:
      case AppPermissionType.speech:
        return AppPermissionCategory.communication;

      case AppPermissionType.notification:
      case AppPermissionType.scheduleExactAlarm:
      case AppPermissionType.systemAlertWindow:
      case AppPermissionType.requestInstallPackages:
      case AppPermissionType.ignoreBatteryOptimizations:
      case AppPermissionType.accessNotificationPolicy:
      case AppPermissionType.appTrackingTransparency:
        return AppPermissionCategory.system;
    }
  }

  PermissionRequestArchetype get requestArchetype {
    switch (this) {
      case AppPermissionType.manageExternalStorage:
      case AppPermissionType.scheduleExactAlarm:
      case AppPermissionType.systemAlertWindow:
      case AppPermissionType.requestInstallPackages:
      case AppPermissionType.ignoreBatteryOptimizations:
      case AppPermissionType.accessNotificationPolicy:
        return PermissionRequestArchetype.settingsRedirect;

      case AppPermissionType.locationAlways:
      case AppPermissionType.sensorsAlways:
        return PermissionRequestArchetype.multiStep;

      default:
        return PermissionRequestArchetype.systemModal;
    }
  }

  String? get platformTag {
    switch (this) {
      case AppPermissionType.bluetoothScan:
      case AppPermissionType.bluetoothConnect:
      case AppPermissionType.bluetoothAdvertise:
      case AppPermissionType.scheduleExactAlarm:
        return 'Android 12+';
      case AppPermissionType.nearbyWifiDevices:
      case AppPermissionType.sensorsAlways:
        return 'Android 13+';
      case AppPermissionType.manageExternalStorage:
        return 'Android 11+';
      case AppPermissionType.locationAlways:
      case AppPermissionType.activityRecognition:
      case AppPermissionType.accessMediaLocation:
        return 'Android 10+ / iOS';
      case AppPermissionType.storage:
        return 'Android ≤ 12';
      case AppPermissionType.bluetooth:
        return 'Android ≤ 11 / iOS';
      case AppPermissionType.reminders:
      case AppPermissionType.mediaLibrary:
        return 'iOS Only';
      case AppPermissionType.appTrackingTransparency:
        return 'iOS 14.5+';
      case AppPermissionType.systemAlertWindow:
      case AppPermissionType.requestInstallPackages:
      case AppPermissionType.ignoreBatteryOptimizations:
      case AppPermissionType.accessNotificationPolicy:
      case AppPermissionType.sms:
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
      case AppPermissionType.reminders:
        return platform == TargetPlatform.iOS;

      case AppPermissionType.systemAlertWindow:
      case AppPermissionType.requestInstallPackages:
      case AppPermissionType.manageExternalStorage:
      case AppPermissionType.scheduleExactAlarm:
      case AppPermissionType.ignoreBatteryOptimizations:
      case AppPermissionType.accessNotificationPolicy:
      case AppPermissionType.bluetoothScan:
      case AppPermissionType.bluetoothConnect:
      case AppPermissionType.bluetoothAdvertise:
      case AppPermissionType.nearbyWifiDevices:
      case AppPermissionType.sms:
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
    if ((this == AppPermissionType.mediaLibrary ||
            this == AppPermissionType.reminders) &&
        platform == TargetPlatform.android) {
      return '$displayName is an Apple iOS exclusive feature and is not available on Android.';
    }
    if ((this == AppPermissionType.systemAlertWindow ||
            this == AppPermissionType.requestInstallPackages ||
            this == AppPermissionType.manageExternalStorage ||
            this == AppPermissionType.scheduleExactAlarm ||
            this == AppPermissionType.ignoreBatteryOptimizations ||
            this == AppPermissionType.accessNotificationPolicy ||
            this == AppPermissionType.bluetoothScan ||
            this == AppPermissionType.bluetoothConnect ||
            this == AppPermissionType.bluetoothAdvertise ||
            this == AppPermissionType.nearbyWifiDevices ||
            this == AppPermissionType.sms) &&
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
