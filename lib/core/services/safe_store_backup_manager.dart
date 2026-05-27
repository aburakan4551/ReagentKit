import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reagentkit/core/utils/logger.dart';

class SafeStoreBackupManager {
  static const String _backupListKey = 'safe_store_backups_list';
  
  /// Creates a timestamped and versioned backup of the current scientific datasets
  /// and config cache, storing them locally in SharedPreferences, and optionally in Firestore.
  static Future<bool> createBackup({
    required String reagentsData,
    required String safetyData,
    required String referencesData,
    required String version,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';

      final Map<String, dynamic> backupPayload = {
        'id': backupId,
        'timestamp': timestamp,
        'version': version,
        'reagents_data': reagentsData,
        'safety_instructions': safetyData,
        'references_data': referencesData,
      };

      final backupString = jsonEncode(backupPayload);
      
      // Save the backup payload locally
      await prefs.setString('safe_store_backup_$backupId', backupString);

      // Register the backup in the backup list
      List<String> backupsList = prefs.getStringList(_backupListKey) ?? [];
      backupsList.add(backupId);
      await prefs.setStringList(_backupListKey, backupsList);

      Logger.info('💾 [BackupManager] Local backup created successfully: $backupId (Version: $version)');

      // Optionally upload backup to Cloud Firestore under 'backups' collection for off-device safety
      try {
        await FirebaseFirestore.instance.collection('backups').doc(backupId).set({
          'timestamp': FieldValue.serverTimestamp(),
          'version': version,
          'reagents_data': reagentsData,
          'safety_instructions': safetyData,
          'references_data': referencesData,
          'source': 'iOS App Backup Manager',
        });
        Logger.info('☁️ [BackupManager] Backup uploaded to Firestore successfully: $backupId');
      } catch (firestoreError) {
        // Log firestore error but do not fail the backup process
        Logger.warning('⚠️ [BackupManager] Optional Firestore backup upload skipped/failed: $firestoreError');
      }

      return true;
    } catch (e, st) {
      Logger.error('❌ [BackupManager] Failed to create backup: $e', error: e, stackTrace: st);
      return false;
    }
  }

  /// Restores the dataset configurations from the latest available backup.
  /// Returns a map containing the restored data keys, or null if no backup exists.
  static Future<Map<String, String>?> restoreLatestBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupsList = prefs.getStringList(_backupListKey) ?? [];
      
      if (backupsList.isEmpty) {
        Logger.warning('⚠️ [BackupManager] No backups found for restoration');
        return null;
      }

      // Get the latest backup ID
      final latestBackupId = backupsList.last;
      final backupDataStr = prefs.getString('safe_store_backup_$latestBackupId');
      
      if (backupDataStr == null) {
        Logger.warning('⚠️ [BackupManager] Backup data for $latestBackupId is empty');
        return null;
      }

      final Map<String, dynamic> backupPayload = jsonDecode(backupDataStr);
      
      Logger.info('🔄 [BackupManager] Restoring latest backup from: ${backupPayload['timestamp']}');
      
      return {
        'reagents_data': backupPayload['reagents_data']?.toString() ?? '{}',
        'safety_instructions': backupPayload['safety_instructions']?.toString() ?? '{}',
        'references_data': backupPayload['references_data']?.toString() ?? '{}',
        'version': backupPayload['version']?.toString() ?? '1.0.0',
      };
    } catch (e, st) {
      Logger.error('❌ [BackupManager] Restore failed: $e', error: e, stackTrace: st);
      return null;
    }
  }

  /// Lists all locally saved backups
  static Future<List<Map<String, String>>> listBackups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupsList = prefs.getStringList(_backupListKey) ?? [];
      final List<Map<String, String>> result = [];

      for (final backupId in backupsList) {
        final backupDataStr = prefs.getString('safe_store_backup_$backupId');
        if (backupDataStr != null) {
          final Map<String, dynamic> payload = jsonDecode(backupDataStr);
          result.add({
            'id': payload['id']?.toString() ?? backupId,
            'timestamp': payload['timestamp']?.toString() ?? '',
            'version': payload['version']?.toString() ?? '',
          });
        }
      }
      return result;
    } catch (e) {
      Logger.error('❌ [BackupManager] Failed to list backups: $e');
      return [];
    }
  }
}
