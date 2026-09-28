import '../entities/app_permission.dart';
import '../repositories/permission_repository.dart';

class RequestPermissionUseCase {
  final PermissionRepository repository;

  RequestPermissionUseCase(this.repository);

  Future<AppPermissionStatus> call(AppPermissionType permission) async {
    return await repository.requestPermission(permission);
  }
}
