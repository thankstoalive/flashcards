/// Conditional export for backup service:
/// - Uses web implementation when running on web (dart:html available)
/// - Falls back to stub for other platforms
export 'backup_service_stub.dart'
    if (dart.library.html) 'backup_service_web.dart';