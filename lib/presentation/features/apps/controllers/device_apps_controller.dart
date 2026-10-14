import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/apps/datasources/device_apps_service.dart';
import '../../../../domain/apps/entities/device_app_info.dart';

enum AppFilter { all, user, system }

enum AppSortOption {
  nameAsc,
  nameDesc,
  sizeDesc,
  sizeAsc,
  dateDesc,
  dateAsc,
}

extension AppSortOptionExt on AppSortOption {
  String get displayName {
    switch (this) {
      case AppSortOption.nameAsc:
        return 'Name (A to Z)';
      case AppSortOption.nameDesc:
        return 'Name (Z to A)';
      case AppSortOption.sizeDesc:
        return 'Size (Largest first)';
      case AppSortOption.sizeAsc:
        return 'Size (Smallest first)';
      case AppSortOption.dateDesc:
        return 'Date (Recently updated)';
      case AppSortOption.dateAsc:
        return 'Date (Oldest updated)';
    }
  }
}

class DeviceAppsState {
  final List<DeviceAppInfo> apps;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final AppFilter filter;
  final AppSortOption sortOption;
  final Set<String> selectedPackageNames;
  final Map<String, Uint8List> appIcons;

  const DeviceAppsState({
    this.apps = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.filter = AppFilter.all,
    this.sortOption = AppSortOption.sizeDesc,
    this.selectedPackageNames = const {},
    this.appIcons = const {},
  });

  DeviceAppsState copyWith({
    List<DeviceAppInfo>? apps,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    AppFilter? filter,
    AppSortOption? sortOption,
    Set<String>? selectedPackageNames,
    Map<String, Uint8List>? appIcons,
  }) {
    return DeviceAppsState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      sortOption: sortOption ?? this.sortOption,
      selectedPackageNames: selectedPackageNames ?? this.selectedPackageNames,
      appIcons: appIcons ?? this.appIcons,
    );
  }

  List<DeviceAppInfo> get filteredApps {
    var result = apps;

    // Filter by type
    if (filter == AppFilter.user) {
      result = result.where((app) => !app.isSystemApp).toList();
    } else if (filter == AppFilter.system) {
      result = result.where((app) => app.isSystemApp).toList();
    }

    // Search query
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((app) {
        return app.name.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query);
      }).toList();
    }

    // Sort
    result = List.of(result);
    switch (sortOption) {
      case AppSortOption.nameAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case AppSortOption.nameDesc:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case AppSortOption.sizeDesc:
        result.sort((a, b) => b.apkSizeBytes.compareTo(a.apkSizeBytes));
        break;
      case AppSortOption.sizeAsc:
        result.sort((a, b) => a.apkSizeBytes.compareTo(b.apkSizeBytes));
        break;
      case AppSortOption.dateDesc:
        result.sort((a, b) => b.updatedTimestamp.compareTo(a.updatedTimestamp));
        break;
      case AppSortOption.dateAsc:
        result.sort((a, b) => a.updatedTimestamp.compareTo(b.updatedTimestamp));
        break;
    }

    return result;
  }

  int get totalAppCount => apps.length;
  int get userAppCount => apps.where((a) => !a.isSystemApp).length;
  int get systemAppCount => apps.where((a) => a.isSystemApp).length;

  int get totalUserAppsSizeBytes {
    return apps
        .where((a) => !a.isSystemApp)
        .fold(0, (sum, a) => sum + a.apkSizeBytes);
  }

  String get formattedTotalUserSize {
    const mb = 1024 * 1024;
    const gb = mb * 1024;
    final total = totalUserAppsSizeBytes;
    if (total >= gb) {
      return '${(total / gb).toStringAsFixed(1)} GB';
    } else {
      return '${(total / mb).toStringAsFixed(1)} MB';
    }
  }

  List<DeviceAppInfo> get selectedApps {
    return apps.where((a) => selectedPackageNames.contains(a.packageName)).toList();
  }

  int get selectedCount => selectedPackageNames.length;

  int get selectedTotalSizeBytes {
    return selectedApps.fold(0, (sum, a) => sum + a.apkSizeBytes);
  }

  String get formattedSelectedSize {
    const mb = 1024 * 1024;
    const gb = mb * 1024;
    final total = selectedTotalSizeBytes;
    if (total >= gb) {
      return '${(total / gb).toStringAsFixed(1)} GB';
    } else if (total >= mb) {
      return '${(total / mb).toStringAsFixed(1)} MB';
    } else {
      return '${(total / 1024).toStringAsFixed(0)} KB';
    }
  }

  bool isSelected(String packageName) =>
      selectedPackageNames.contains(packageName);
}

final deviceAppsServiceProvider = Provider<DeviceAppsService>((ref) {
  return DeviceAppsService();
});

final deviceAppsControllerProvider =
    NotifierProvider<DeviceAppsNotifier, DeviceAppsState>(DeviceAppsNotifier.new);

class DeviceAppsNotifier extends Notifier<DeviceAppsState> {
  DeviceAppsService get _service => ref.read(deviceAppsServiceProvider);

  @override
  DeviceAppsState build() {
    Future.microtask(() => loadApps());
    return const DeviceAppsState();
  }

  Future<void> loadApps() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apps = await _service.getInstalledApps();
      state = state.copyWith(
        apps: apps,
        isLoading: false,
      );

      // Lazily pre-fetch icons for top 15 user apps for smooth instant display
      for (final app in apps.take(20)) {
        loadAppIcon(app.packageName);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load apps: $e',
      );
    }
  }

  Future<Uint8List?> loadAppIcon(String packageName) async {
    if (state.appIcons.containsKey(packageName)) {
      return state.appIcons[packageName];
    }

    final bytes = await _service.getAppIcon(packageName);
    if (bytes != null) {
      final updatedIcons = Map<String, Uint8List>.from(state.appIcons);
      updatedIcons[packageName] = bytes;
      state = state.copyWith(appIcons: updatedIcons);
    }
    return bytes;
  }

  Future<List<String>> fetchAppPermissions(String packageName) async {
    final perms = await _service.getAppPermissions(packageName);
    // Cache permissions in app entity if found
    final index = state.apps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      final updatedApp = state.apps[index].copyWith(permissions: perms);
      final updatedList = List<DeviceAppInfo>.from(state.apps);
      updatedList[index] = updatedApp;
      state = state.copyWith(apps: updatedList);
    }
    return perms;
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(AppFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSortOption(AppSortOption sortOption) {
    state = state.copyWith(sortOption: sortOption);
  }

  void toggleSelection(String packageName) {
    final updated = Set<String>.from(state.selectedPackageNames);
    if (updated.contains(packageName)) {
      updated.remove(packageName);
    } else {
      updated.add(packageName);
    }
    state = state.copyWith(selectedPackageNames: updated);
  }

  void selectAll() {
    final allKeys = state.filteredApps.map((a) => a.packageName).toSet();
    state = state.copyWith(selectedPackageNames: allKeys);
  }

  void clearSelection() {
    state = state.copyWith(selectedPackageNames: {});
  }

  Future<void> shareSelectedApks() async {
    final selected = state.selectedApps;
    if (selected.isNotEmpty) {
      await _service.shareApks(selected);
    }
  }

  Future<void> shareSelectedLinks() async {
    final selected = state.selectedApps;
    if (selected.isNotEmpty) {
      await _service.shareAppLinks(selected);
    }
  }

  Future<void> shareSingleApk(DeviceAppInfo app) async {
    await _service.shareApks([app]);
  }

  Future<void> shareSingleLink(DeviceAppInfo app) async {
    await _service.shareAppLinks([app]);
  }

  Future<bool> launchApp(String packageName) async {
    return await _service.launchApp(packageName);
  }

  Future<bool> openAppSettings(String packageName) async {
    return await _service.openAppSettings(packageName);
  }
}
