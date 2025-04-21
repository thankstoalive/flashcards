import 'package:flutter/material.dart';

/// Stub implementation for backup/import on non-web platforms.
class BackupService {
  /// Show a message that backup is only supported on mobile/desktop.
  static Future<void> exportBackup(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Backup is supported on mobile/desktop only.')),
    );
  }

  /// Show a message that import is only supported on mobile/desktop.
  static Future<void> importBackup(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Import is supported on mobile/desktop only.')),
    );
  }
}