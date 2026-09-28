import '../entities/app_permission.dart';
import '../repositories/permission_repository.dart';

class GetPermissionStatusUseCase {
  final PermissionRepository repository;

  GetPermissionStatusUseCase(this.repository);

  Future<AppPermissionStatus> call(AppPermissionType permission) async {
    return await repository.getPermissionStatus(permission);
  }
}
