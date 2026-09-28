enum AppPermissionType {
  camera,
  microphone,
  location,
}

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  unknown,
}

class AppPermission {
  final AppPermissionType type;
  final AppPermissionStatus status;

  const AppPermission({
    required this.type,
    required this.status,
  });

  bool get isGranted => status == AppPermissionStatus.granted;
  bool get isPermanentlyDenied => status == AppPermissionStatus.permanentlyDenied;
  bool get isDenied => status == AppPermissionStatus.denied;
}
