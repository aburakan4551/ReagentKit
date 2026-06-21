import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:reagentkit/core/utils/logger.dart';
import 'package:reagentkit/core/services/safe_store_sanitizer.dart';
import 'package:reagentkit/features/reagent_testing/data/services/unified_data_service.dart';

class SafeStoreRestoreManager {
  static const String _backupListKey = 'scientific_mode_backups_list';

  /// Creates a complete backup of the original scientific data files and current caches.
  static Future<bool> createScientificBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      final backupId = 'sci_backup_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Read files from assets
      final reagentsJson = await rootBundle.loadString('assets/data/reagents.json');
      final referencesJson = await rootBundle.loadString('assets/data/references.json');
      final safetyJson = await rootBundle.loadString('assets/data/safety.json');

      // 2. Read current local scientific cache from SharedPreferences
      final localCache = prefs.getString('scientific_dataset_cache') ?? '{}';

      // 3. Assemble backup payload
      final Map<String, dynamic> payload = {
        'id': backupId,
        'timestamp': timestamp,
        'reagents': reagentsJson,
        'references': referencesJson,
        'safety': safetyJson,
        'scientific_data_cache': localCache,
        'remote_config_snapshot': prefs.getString('scientific_dataset_snapshot') ?? '',
      };

      final payloadString = jsonEncode(payload);

      // 4. Generate integrity hash (SHA-256)
      final hash = sha256.convert(utf8.encode(payloadString)).toString();
      
      final Map<String, dynamic> backupEnvelope = {
        'payload': payloadString,
        'hash': hash,
        'timestamp': timestamp,
      };

      // 5. Store locally
      await prefs.setString('scientific_backup_$backupId', jsonEncode(backupEnvelope));

      // 6. Register backup ID in list
      List<String> backupsList = prefs.getStringList(_backupListKey) ?? [];
      backupsList.add(backupId);
      await prefs.setStringList(_backupListKey, backupsList);

      Logger.info('💾 [SafeStoreRestoreManager] Created scientific backup: $backupId');

      // 7. Optional Firestore backup
      try {
        await FirebaseFirestore.instance.collection('scientific_backups').doc(backupId).set({
          'timestamp': FieldValue.serverTimestamp(),
          'reagents': reagentsJson,
          'references': referencesJson,
          'safety': safetyJson,
          'scientific_data_cache': localCache,
          'hash': hash,
          'source': 'iOS App Restore Manager',
        });
        Logger.info('☁️ [SafeStoreRestoreManager] Uploaded backup to Cloud Firestore');
      } catch (firestoreError) {
        Logger.warning('⚠️ [SafeStoreRestoreManager] Optional Cloud Firestore backup skipped: $firestoreError');
      }

      return true;
    } catch (e, st) {
      Logger.error('❌ [SafeStoreRestoreManager] Backup creation failed: $e', error: e, stackTrace: st);
      return false;
    }
  }

  /// Automatically restores the original scientific data, resets sanitizer flags,
  /// clears review caches, and reloads the pipeline to return to normal mode.
  static Future<bool> restoreOriginalScientificMode(UnifiedDataService dataService) async {
    try {
      Logger.info('🔄 [SafeStoreRestoreManager] Restoring original scientific mode...');

      // 1. Reset all safe store mode flags
      SafeStoreSanitizer.safeStoreMode = false;
      SafeStoreSanitizer.appStoreReviewMode = false;

      // 2. Wipe SharedPreferences caches to force asset reload
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('scientific_dataset_cache');
      await prefs.remove('scientific_dataset_cache_prev');
      await prefs.remove('scientific_dataset_snapshot');
      
      // Also clear cached AI results or analysis cache if any are stored in prefs
      await prefs.remove('cached_ai_analysis_results');
      
      Logger.info('🧹 [SafeStoreRestoreManager] Local caches and AI snapshots wiped');

      // 3. Force reload pipeline in UnifiedDataService
      // This will load from assets/data/reagents.json because appStoreReviewMode is false
      final snapshot = await dataService.loadPipeline(
        forceAssetReload: true,
        clearCache: true,
      );

      Logger.info('✅ [SafeStoreRestoreManager] Scientific mode restored. Dataset version: ${snapshot.version}');
      return true;
    } catch (e, st) {
      Logger.error('❌ [SafeStoreRestoreManager] Restoration failed: $e', error: e, stackTrace: st);
      return false;
    }
  }
}
