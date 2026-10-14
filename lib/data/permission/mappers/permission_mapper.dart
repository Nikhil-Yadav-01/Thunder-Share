import 'package:permission_handler/permission_handler.dart';

import '../../../domain/permission/entities/app_permission.dart';

class PermissionMapper {
  static Permission toHandlerPermission(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.camera:
        return Permission.camera;
      case AppPermissionType.microphone:
        return Permission.microphone;
      case AppPermissionType.sensors:
        return Permission.sensors;
      case AppPermissionType.sensorsAlways:
        return Permission.sensorsAlways;
      case AppPermissionType.location:
        return Permission.location;
      case AppPermissionType.locationAlways:
        return Permission.locationAlways;
      case AppPermissionType.activityRecognition:
        return Permission.activityRecognition;
      case AppPermissionType.photos:
        return Permission.photos;
      case AppPermissionType.videos:
        return Permission.videos;
      case AppPermissionType.mediaLibrary:
        return Permission.mediaLibrary;
      case AppPermissionType.audio:
        return Permission.audio;
      case AppPermissionType.accessMediaLocation:
        return Permission.accessMediaLocation;
      case AppPermissionType.storage:
        return Permission.storage;
      case AppPermissionType.manageExternalStorage:
        return Permission.manageExternalStorage;
      case AppPermissionType.bluetoothScan:
        return Permission.bluetoothScan;
      case AppPermissionType.bluetoothConnect:
        return Permission.bluetoothConnect;
      case AppPermissionType.bluetoothAdvertise:
        return Permission.bluetoothAdvertise;
      case AppPermissionType.nearbyWifiDevices:
        return Permission.nearbyWifiDevices;
      case AppPermissionType.bluetooth:
        return Permission.bluetooth;
      case AppPermissionType.contacts:
        return Permission.contacts;
      case AppPermissionType.calendar:
        return Permission.calendarFullAccess;
      case AppPermissionType.reminders:
        return Permission.reminders;
      case AppPermissionType.phone:
        return Permission.phone;
      case AppPermissionType.sms:
        return Permission.sms;
      case AppPermissionType.speech:
        return Permission.speech;
      case AppPermissionType.notification:
        return Permission.notification;
      case AppPermissionType.scheduleExactAlarm:
        return Permission.scheduleExactAlarm;
      case AppPermissionType.systemAlertWindow:
        return Permission.systemAlertWindow;
      case AppPermissionType.requestInstallPackages:
        return Permission.requestInstallPackages;
      case AppPermissionType.ignoreBatteryOptimizations:
        return Permission.ignoreBatteryOptimizations;
      case AppPermissionType.accessNotificationPolicy:
        return Permission.accessNotificationPolicy;
      case AppPermissionType.appTrackingTransparency:
        return Permission.appTrackingTransparency;
    }
  }

  static AppPermissionStatus toDomainStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return AppPermissionStatus.granted;
      case PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
      case PermissionStatus.limited:
        return AppPermissionStatus.limited;
      case PermissionStatus.provisional:
        return AppPermissionStatus.provisional;
    }
  }
}
