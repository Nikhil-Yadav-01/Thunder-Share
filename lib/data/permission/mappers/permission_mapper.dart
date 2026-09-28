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
      default:
        return AppPermissionStatus.unknown;
    }
  }
}
