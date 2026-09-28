import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/permission_providers.dart';
import '../../../domain/permission/entities/app_permission.dart';

class PermissionState {
  final AppPermissionStatus cameraStatus;
  final AppPermissionStatus microphoneStatus;
  final AppPermissionStatus locationStatus;
  final bool isLoading;

  const PermissionState({
    this.cameraStatus = AppPermissionStatus.denied,
    this.microphoneStatus = AppPermissionStatus.denied,
    this.locationStatus = AppPermissionStatus.denied,
    this.isLoading = false,
  });

  PermissionState copyWith({
    AppPermissionStatus? cameraStatus,
    AppPermissionStatus? microphoneStatus,
    AppPermissionStatus? locationStatus,
    bool? isLoading,
  }) {
    return PermissionState(
      cameraStatus: cameraStatus ?? this.cameraStatus,
      microphoneStatus: microphoneStatus ?? this.microphoneStatus,
      locationStatus: locationStatus ?? this.locationStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PermissionNotifier extends Notifier<PermissionState> {
  @override
  PermissionState build() {
    return const PermissionState();
  }

  Future<void> loadStatuses() async {
    state = state.copyWith(isLoading: true);

    final getStatus = ref.read(getPermissionStatusUseCaseProvider);
    final camera = await getStatus(AppPermissionType.camera);
    final mic = await getStatus(AppPermissionType.microphone);
    final location = await getStatus(AppPermissionType.location);

    state = state.copyWith(
      cameraStatus: camera,
      microphoneStatus: mic,
      locationStatus: location,
      isLoading: false,
    );
  }

  Future<AppPermissionStatus> requestPermission(AppPermissionType type) async {
    state = state.copyWith(isLoading: true);

    final request = ref.read(requestPermissionUseCaseProvider);
    final status = await request(type);

    switch (type) {
      case AppPermissionType.camera:
        state = state.copyWith(cameraStatus: status, isLoading: false);
        break;
      case AppPermissionType.microphone:
        state = state.copyWith(microphoneStatus: status, isLoading: false);
        break;
      case AppPermissionType.location:
        state = state.copyWith(locationStatus: status, isLoading: false);
        break;
    }
    return status;
  }

  Future<bool> openSettings() async {
    final openAppSettings = ref.read(openAppSettingsUseCaseProvider);
    return await openAppSettings();
  }
}

final permissionControllerProvider =
    NotifierProvider<PermissionNotifier, PermissionState>(
  PermissionNotifier.new,
);
