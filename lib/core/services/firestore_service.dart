import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get scans left for an anonymous device (default is 3)
  Future<int> getDeviceScansLeft(String deviceId) async {
    try {
      final doc =
          await _firestore.collection('anonymous_devices').doc(deviceId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('scansLeft')) {
          return data['scansLeft'] as int;
        }
      }
      // If not set yet, initialize it
      await updateDeviceScansLeft(deviceId, 3);
      return 3;
    } catch (e) {
      Logger.error('Error getting device scans left: $e');
      return 3; // Fallback
    }
  }

  /// Update scans left for an anonymous device
  Future<void> updateDeviceScansLeft(String deviceId, int scansLeft) async {
    try {
      await _firestore.collection('anonymous_devices').doc(deviceId).set({
        'scansLeft': scansLeft,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Logger.info(
          '✅ FirestoreService: Updated scansLeft to $scansLeft for device $deviceId');
    } catch (e) {
      Logger.error('Error updating device scans left: $e');
      throw Exception('Failed to update scans left: $e');
    }
  }

  // Debug method to test Firestore connectivity
  Future<void> testFirestoreConnection() async {
    try {
      Logger.info('🔧 FirestoreService: Testing Firestore connection...');

      // Test write
      final testData = {
        'test': true,
        'timestamp': Timestamp.now(),
        'message': 'Firestore connection test',
      };

      await _firestore.collection('test').doc('connection_test').set(testData);
      Logger.info('✅ FirestoreService: Test write successful');

      // Test read
      final doc =
          await _firestore.collection('test').doc('connection_test').get();
      if (doc.exists) {
        Logger.info('✅ FirestoreService: Test read successful: ${doc.data()}');
      } else {
        Logger.info(
            '❌ FirestoreService: Test read failed - document not found');
      }

      // Clean up test document
      await _firestore.collection('test').doc('connection_test').delete();
      Logger.info('✅ FirestoreService: Test cleanup successful');
    } catch (e) {
      Logger.info('❌ FirestoreService: Connection test failed: $e');
      throw Exception('Firestore connection test failed: $e');
    }
  }
}
