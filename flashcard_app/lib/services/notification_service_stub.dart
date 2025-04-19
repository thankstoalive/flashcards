/// Stub NotificationService for unsupported platforms (e.g., web)
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  /// Initialization stub
  Future<void> init() async {}

  /// Stub for scheduling daily reminder
  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {}

  /// Stub for showing a test notification immediately
  Future<void> showTestNotification() async {}
}