import '../entities/app_permission.dart';

abstract class PermissionRepository {
  Future<AppPermissionStatus> getPermissionStatus(AppPermissionType permission);

  Future<AppPermissionStatus> requestPermission(AppPermissionType permission);

  Future<bool> openAppSettings();
}
