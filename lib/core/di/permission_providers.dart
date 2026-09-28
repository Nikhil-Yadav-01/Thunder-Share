import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/permission/datasources/permission_service.dart';
import '../../data/permission/repositories/permission_repository_impl.dart';
import '../../domain/permission/repositories/permission_repository.dart';
import '../../domain/permission/usecases/get_permission_status.dart';
import '../../domain/permission/usecases/open_app_settings.dart';
import '../../domain/permission/usecases/request_permission.dart';

// Data Layer Providers
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final permissionRepositoryProvider = Provider<PermissionRepository>((ref) {
  final dataSource = ref.watch(permissionServiceProvider);
  return PermissionRepositoryImpl(dataSource: dataSource);
});

// Domain Layer Use Case Providers
final getPermissionStatusUseCaseProvider =
    Provider<GetPermissionStatusUseCase>((ref) {
  final repository = ref.watch(permissionRepositoryProvider);
  return GetPermissionStatusUseCase(repository);
});

final requestPermissionUseCaseProvider =
    Provider<RequestPermissionUseCase>((ref) {
  final repository = ref.watch(permissionRepositoryProvider);
  return RequestPermissionUseCase(repository);
});

final openAppSettingsUseCaseProvider = Provider<OpenAppSettingsUseCase>((ref) {
  final repository = ref.watch(permissionRepositoryProvider);
  return OpenAppSettingsUseCase(repository);
});
