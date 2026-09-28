import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request any permission.
  Future<PermissionStatus> requestPermission(Permission permission) async {
    return await permission.request();
  }

  /// Get the current status without displaying a permission dialog.
  Future<PermissionStatus> getStatus(Permission permission) async {
    return await permission.status;
  }

  /// Check whether permission is granted.
  Future<bool> isGranted(Permission permission) async {
    return await permission.isGranted;
  }

  /// Check whether permission has been permanently denied.
  Future<bool> isPermanentlyDenied(Permission permission) async {
    return await permission.isPermanentlyDenied;
  }

  /// Check whether permission is denied.
  Future<bool> isDenied(Permission permission) async {
    return await permission.isDenied;
  }

  /// Request multiple permissions.
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  /// Open this application's Android settings page.
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
