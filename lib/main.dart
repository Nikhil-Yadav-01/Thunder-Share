import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/permission/pages/permission_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PermissionMasteryApp(),
    ),
  );
}

class PermissionMasteryApp extends StatelessWidget {
  const PermissionMasteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Permission Mastery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PermissionScreen(),
    );
  }
}
