import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/apps/entities/device_app_info.dart';
import '../controllers/device_apps_controller.dart';
import '../widgets/app_detail_bottom_sheet.dart';

class DeviceAppsSharingScreen extends ConsumerStatefulWidget {
  const DeviceAppsSharingScreen({super.key});

  @override
  ConsumerState<DeviceAppsSharingScreen> createState() =>
      _DeviceAppsSharingScreenState();
}

class _DeviceAppsSharingScreenState extends ConsumerState<DeviceAppsSharingScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceAppsControllerProvider);
    final notifier = ref.read(deviceAppsControllerProvider.notifier);
    final theme = Theme.of(context);
    final filteredApps = state.filteredApps;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by app name or package...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                style: theme.textTheme.titleMedium,
                onChanged: notifier.setSearchQuery,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Device Apps & Sharing'),
                  Text(
                    '${state.totalAppCount} apps • ${state.formattedTotalUserSize} user data',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Close search' : 'Search apps',
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  notifier.setSearchQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          PopupMenuButton<AppSortOption>(
            tooltip: 'Sort Apps',
            icon: const Icon(Icons.sort),
            initialValue: state.sortOption,
            onSelected: notifier.setSortOption,
            itemBuilder: (context) => AppSortOption.values.map((option) {
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    if (state.sortOption == option)
                      Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(option.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            tooltip: 'Refresh apps',
            icon: const Icon(Icons.refresh),
            onPressed: notifier.loadApps,
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            onSelected: (val) {
              if (val == 'select_all') {
                notifier.selectAll();
              } else if (val == 'clear_all') {
                notifier.clearSelection();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'select_all',
                child: Row(
                  children: [
                    Icon(Icons.select_all, size: 18),
                    SizedBox(width: 10),
                    Text('Select All Filtered'),
                  ],
                ),
              ),
              if (state.selectedCount > 0)
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.deselect, size: 18),
                      SizedBox(width: 10),
                      Text('Clear Selection'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Apps (${state.totalAppCount})',
                  isSelected: state.filter == AppFilter.all,
                  onSelected: () => notifier.setFilter(AppFilter.all),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'User Apps (${state.userAppCount})',
                  isSelected: state.filter == AppFilter.user,
                  onSelected: () => notifier.setFilter(AppFilter.user),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'System (${state.systemAppCount})',
                  isSelected: state.filter == AppFilter.system,
                  onSelected: () => notifier.setFilter(AppFilter.system),
                ),
              ],
            ),
          ),

          // Main App List
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Reading device packages & APK storage...'),
                      ],
                    ),
                  )
                : filteredApps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.apps_outlined,
                              size: 64,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.searchQuery.isNotEmpty
                                  ? 'No apps match "${state.searchQuery}"'
                                  : 'No installed apps found',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (state.searchQuery.isNotEmpty)
                              FilledButton.tonal(
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.setSearchQuery('');
                                },
                                child: const Text('Clear Search'),
                              ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 8,
                          bottom: state.selectedCount > 0 ? 96 : 24,
                        ),
                        itemCount: filteredApps.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          final isSelected = state.isSelected(app.packageName);
                          final iconBytes = state.appIcons[app.packageName] ?? app.iconBytes;

                          // Trigger icon load if missing
                          if (iconBytes == null) {
                            notifier.loadAppIcon(app.packageName);
                          }

                          return _buildAppItemCard(
                            context,
                            app: app,
                            isSelected: isSelected,
                            iconBytes: iconBytes,
                            theme: theme,
                            onTap: () => AppDetailBottomSheet.show(context, app),
                            onToggleSelect: () => notifier.toggleSelection(app.packageName),
                            onShare: () => notifier.shareSingleApk(app),
                          );
                        },
                      ),
          ),
        ],
      ),

      // Floating Selection / Sharing Bar
      bottomSheet: state.selectedCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.selectedCount} app${state.selectedCount > 1 ? "s" : ""} selected',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            state.formattedSelectedSize,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Clear selection',
                      icon: const Icon(Icons.close),
                      onPressed: notifier.clearSelection,
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: notifier.shareSelectedLinks,
                      icon: const Icon(Icons.link, size: 16),
                      label: const Text('Links'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: notifier.shareSelectedApks,
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share APKs'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildAppItemCard(
    BuildContext context, {
    required DeviceAppInfo app,
    required bool isSelected,
    required Uint8List? iconBytes,
    required ThemeData theme,
    required VoidCallback onTap,
    required VoidCallback onToggleSelect,
    required VoidCallback onShare,
  }) {
    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onToggleSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Checkbox for Selection
              Checkbox(
                value: isSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (_) => onToggleSelect(),
              ),

              // App Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: iconBytes != null
                      ? Image.memory(
                          iconBytes,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.android,
                          size: 28,
                          color: theme.colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // App Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (app.isSystemApp)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'System',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.packageName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          app.formattedSize,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'v${app.versionName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Action Button: Share APK
              IconButton(
                tooltip: 'Share APK',
                icon: const Icon(Icons.share_outlined, size: 20),
                onPressed: onShare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
