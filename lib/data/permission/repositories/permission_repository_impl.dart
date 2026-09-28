import '../../../domain/permission/entities/app_permission.dart';
import '../../../domain/permission/repositories/permission_repository.dart';
import '../datasources/permission_service.dart';
import '../mappers/permission_mapper.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  final PermissionService dataSource;

  PermissionRepositoryImpl({required this.dataSource});

  @override
  Future<AppPermissionStatus> getPermissionStatus(
    AppPermissionType permission,
  ) async {
    final handlerPermission = PermissionMapper.toHandlerPermission(permission);
    final status = await dataSource.getStatus(handlerPermission);
    return PermissionMapper.toDomainStatus(status);
  }

  @override
  Future<AppPermissionStatus> requestPermission(
    AppPermissionType permission,
  ) async {
    final handlerPermission = PermissionMapper.toHandlerPermission(permission);
    final status = await dataSource.requestPermission(handlerPermission);
    return PermissionMapper.toDomainStatus(status);
  }

  @override
  Future<bool> openAppSettings() async {
    return await dataSource.openSettings();
  }
}
