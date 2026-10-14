import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class RealFileItem {
  final String path;
  final String name;
  final int sizeInBytes;
  final DateTime lastModified;
  final bool isDirectory;

  const RealFileItem({
    required this.path,
    required this.name,
    required this.sizeInBytes,
    required this.lastModified,
    required this.isDirectory,
  });
}

class FilesDemoScreen extends ConsumerStatefulWidget {
  const FilesDemoScreen({super.key});

  @override
  ConsumerState<FilesDemoScreen> createState() => _FilesDemoScreenState();
}

class _FilesDemoScreenState extends ConsumerState<FilesDemoScreen> {
  final List<RealFileItem> _files = [];
  bool _isLoading = false;
  int _selectedDirectoryType = 0; // 0: Documents, 1: Temp, 2: External
  String _currentDirectoryPath = '';

  @override
  void initState() {
    super.initState();
    _loadDirectoryFiles();
  }

  Future<Directory> _getTargetDirectory() async {
    if (_selectedDirectoryType == 1) {
      return await getTemporaryDirectory();
    } else if (_selectedDirectoryType == 2 && !kIsWeb && Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      return ext ?? await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<void> _loadDirectoryFiles() async {
    setState(() => _isLoading = true);
    _files.clear();

    try {
      final dir = await _getTargetDirectory();
      _currentDirectoryPath = dir.path;

      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          final stat = entity.statSync();
          _files.add(
            RealFileItem(
              path: entity.path,
              name: entity.path.split(Platform.pathSeparator).last,
              sizeInBytes: stat.size,
              lastModified: stat.modified,
              isDirectory: stat.type == FileSystemEntityType.directory,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading directory files: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _createNewFile() {
    final titleController = TextEditingController(text: 'sample_doc.txt');
    final contentController = TextEditingController(
      text: 'Saved on physical device at ${DateTime.now().toLocal()}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Real File on Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Filename',
                hintText: 'my_file.txt',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'File Content',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final filename = titleController.text.trim();
              if (filename.isNotEmpty) {
                final dir = await _getTargetDirectory();
                final file = File('${dir.path}/$filename');
                await file.writeAsString(contentController.text);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (mounted) {
                  _loadDirectoryFiles();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('File created on disk: $filename'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Save to Disk'),
          ),
        ],
      ),
    );
  }

  void _viewFile(RealFileItem item) {
    String content = '';
    try {
      final file = File(item.path);
      content = file.readAsStringSync();
    } catch (e) {
      content = 'Could not read file contents: $e';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  content,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Full Path: ${item.path}\nSize: ${item.sizeInBytes} bytes\nLast Modified: ${item.lastModified.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_outline, size: 16),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final file = File(item.path);
                if (await file.exists()) {
                  await file.delete();
                }
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (mounted) {
                  _loadDirectoryFiles();
                }
              } catch (_) {}
            },
            label: const Text('Delete File'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalBytes = _files.fold<int>(0, (sum, f) => sum + f.sizeInBytes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Device Storage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadDirectoryFiles,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New File'),
        onPressed: _createNewFile,
      ),
      body: Column(
        children: [
          // Directory Selector Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('App Documents'),
                  selected: _selectedDirectoryType == 0,
                  onSelected: (_) {
                    setState(() => _selectedDirectoryType = 0);
                    _loadDirectoryFiles();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Temporary / Cache'),
                  selected: _selectedDirectoryType == 1,
                  onSelected: (_) {
                    setState(() => _selectedDirectoryType = 1);
                    _loadDirectoryFiles();
                  },
                ),
                if (!kIsWeb && Platform.isAndroid) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('External Storage'),
                    selected: _selectedDirectoryType == 2,
                    onSelected: (_) {
                      setState(() => _selectedDirectoryType = 2);
                      _loadDirectoryFiles();
                    },
                  ),
                ],
              ],
            ),
          ),

          // Current Path Header Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_open, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentDirectoryPath.isEmpty ? 'Loading...' : _currentDirectoryPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),

          // File Summary Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Physical Files (${_files.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(totalBytes / 1024).toStringAsFixed(1)} KB on disk',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // File List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? Center(
                        child: Text(
                          'No files in this folder.\nTap "New File" to create one on disk.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _files.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _files[index];
                          return Card(
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: item.isDirectory
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : Colors.blue.withValues(alpha: 0.2),
                                child: Icon(
                                  item.isDirectory
                                      ? Icons.folder
                                      : Icons.description_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              subtitle: Text(
                                '${item.sizeInBytes} bytes • ${item.lastModified.hour.toString().padLeft(2, '0')}:${item.lastModified.minute.toString().padLeft(2, '0')}',
                                style: theme.textTheme.bodySmall,
                              ),
                              trailing: const Icon(Icons.chevron_right, size: 20),
                              onTap: item.isDirectory ? null : () => _viewFile(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
