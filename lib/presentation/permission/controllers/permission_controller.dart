import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/permission_providers.dart';
import '../../../domain/permission/entities/app_permission.dart';

class PermissionState {
  final Map<AppPermissionType, AppPermissionStatus> statuses;
  final bool isLoading;
  final AppPermissionType? activeRequestingType;

  const PermissionState({
    this.statuses = const {},
    this.isLoading = false,
    this.activeRequestingType,
  });

  AppPermissionStatus statusOf(AppPermissionType type) {
    return statuses[type] ?? AppPermissionStatus.unknown;
  }

  bool isGranted(AppPermissionType type) {
    final status = statusOf(type);
    return status == AppPermissionStatus.granted ||
        status == AppPermissionStatus.limited;
  }

  PermissionState copyWith({
    Map<AppPermissionType, AppPermissionStatus>? statuses,
    bool? isLoading,
    AppPermissionType? activeRequestingType,
    bool clearActiveRequestingType = false,
  }) {
    return PermissionState(
      statuses: statuses ?? this.statuses,
      isLoading: isLoading ?? this.isLoading,
      activeRequestingType: clearActiveRequestingType
          ? null
          : (activeRequestingType ?? this.activeRequestingType),
    );
  }
}

class PermissionNotifier extends Notifier<PermissionState> {
  @override
  PermissionState build() {
    return const PermissionState();
  }

  /// Load status for all supported permissions.
  Future<void> loadStatuses() async {
    state = state.copyWith(isLoading: true);

    final getStatus = ref.read(getPermissionStatusUseCaseProvider);
    final newStatuses = <AppPermissionType, AppPermissionStatus>{};

    for (final type in AppPermissionType.values) {
      if (!type.isSupportedOnPlatform(defaultTargetPlatform, isWeb: kIsWeb)) {
        newStatuses[type] = AppPermissionStatus.notApplicable;
        continue;
      }

      try {
        final status = await getStatus(type);
        newStatuses[type] = status;
      } catch (_) {
        newStatuses[type] = AppPermissionStatus.unknown;
      }
    }

    state = state.copyWith(
      statuses: newStatuses,
      isLoading: false,
    );
  }

  /// Check status for a single permission type and update state.
  Future<AppPermissionStatus> checkStatus(AppPermissionType type) async {
    if (!type.isSupportedOnPlatform(defaultTargetPlatform, isWeb: kIsWeb)) {
      final updatedStatuses = Map<AppPermissionType, AppPermissionStatus>.from(
        state.statuses,
      );
      updatedStatuses[type] = AppPermissionStatus.notApplicable;
      state = state.copyWith(statuses: updatedStatuses);
      return AppPermissionStatus.notApplicable;
    }

    final getStatus = ref.read(getPermissionStatusUseCaseProvider);
    final status = await getStatus(type);

    final updatedStatuses = Map<AppPermissionType, AppPermissionStatus>.from(
      state.statuses,
    );
    updatedStatuses[type] = status;

    state = state.copyWith(statuses: updatedStatuses);
    return status;
  }

  /// Request any permission by type and update state.
  Future<AppPermissionStatus> requestPermission(AppPermissionType type) async {
    if (!type.isSupportedOnPlatform(defaultTargetPlatform, isWeb: kIsWeb)) {
      final updatedStatuses = Map<AppPermissionType, AppPermissionStatus>.from(
        state.statuses,
      );
      updatedStatuses[type] = AppPermissionStatus.notApplicable;
      state = state.copyWith(statuses: updatedStatuses);
      return AppPermissionStatus.notApplicable;
    }

    state = state.copyWith(
      isLoading: true,
      activeRequestingType: type,
    );

    final request = ref.read(requestPermissionUseCaseProvider);
    final status = await request(type);

    final updatedStatuses = Map<AppPermissionType, AppPermissionStatus>.from(
      state.statuses,
    );
    updatedStatuses[type] = status;

    state = state.copyWith(
      statuses: updatedStatuses,
      isLoading: false,
      clearActiveRequestingType: true,
    );
    return status;
  }

  // ---------------------------------------------------------------------------
  // Dedicated Triggers
  // ---------------------------------------------------------------------------

  /// Photos / Gallery trigger
  Future<AppPermissionStatus> requestPhotos() =>
      requestPermission(AppPermissionType.photos);

  /// Videos trigger
  Future<AppPermissionStatus> requestVideos() =>
      requestPermission(AppPermissionType.videos);

  /// Media Library trigger
  Future<AppPermissionStatus> requestMediaLibrary() =>
      requestPermission(AppPermissionType.mediaLibrary);

  /// Audio / Music trigger
  Future<AppPermissionStatus> requestAudio() =>
      requestPermission(AppPermissionType.audio);

  /// Storage trigger
  Future<AppPermissionStatus> requestStorage() =>
      requestPermission(AppPermissionType.storage);

  /// Manage All Files trigger
  Future<AppPermissionStatus> requestManageExternalStorage() =>
      requestPermission(AppPermissionType.manageExternalStorage);

  /// App Tracking Transparency trigger
  Future<AppPermissionStatus> requestAppTracking() =>
      requestPermission(AppPermissionType.appTrackingTransparency);

  /// Display Over Other Apps trigger
  Future<AppPermissionStatus> requestSystemAlertWindow() =>
      requestPermission(AppPermissionType.systemAlertWindow);

  /// Install Unknown Apps trigger
  Future<AppPermissionStatus> requestInstallPackages() =>
      requestPermission(AppPermissionType.requestInstallPackages);

  /// Push Notifications trigger
  Future<AppPermissionStatus> requestNotification() =>
      requestPermission(AppPermissionType.notification);

  /// Camera trigger
  Future<AppPermissionStatus> requestCamera() =>
      requestPermission(AppPermissionType.camera);

  /// Microphone trigger
  Future<AppPermissionStatus> requestMicrophone() =>
      requestPermission(AppPermissionType.microphone);

  /// Location trigger
  Future<AppPermissionStatus> requestLocation() =>
      requestPermission(AppPermissionType.location);

  /// Open device app settings
  Future<bool> openSettings() async {
    final openAppSettings = ref.read(openAppSettingsUseCaseProvider);
    return await openAppSettings();
  }
}

final permissionControllerProvider =
    NotifierProvider<PermissionNotifier, PermissionState>(
  PermissionNotifier.new,
);

