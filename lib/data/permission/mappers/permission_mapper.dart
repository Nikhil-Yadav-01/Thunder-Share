import 'package:permission_handler/permission_handler.dart';

import '../../../domain/permission/entities/app_permission.dart';

class PermissionMapper {
  static Permission toHandlerPermission(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.camera:
        return Permission.camera;
      case AppPermissionType.microphone:
        return Permission.microphone;
      case AppPermissionType.location:
        return Permission.location;
      case AppPermissionType.photos:
        return Permission.photos;
      case AppPermissionType.videos:
        return Permission.videos;
      case AppPermissionType.mediaLibrary:
        return Permission.mediaLibrary;
      case AppPermissionType.audio:
        return Permission.audio;
      case AppPermissionType.storage:
        return Permission.storage;
      case AppPermissionType.manageExternalStorage:
        return Permission.manageExternalStorage;
      case AppPermissionType.appTrackingTransparency:
        return Permission.appTrackingTransparency;
      case AppPermissionType.systemAlertWindow:
        return Permission.systemAlertWindow;
      case AppPermissionType.requestInstallPackages:
        return Permission.requestInstallPackages;
      case AppPermissionType.notification:
        return Permission.notification;
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

