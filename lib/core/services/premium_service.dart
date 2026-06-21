import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firestore_service.dart';
import '../config/get_it_config.dart';
import '../utils/logger.dart';
import '../globals.dart' as globals;
import 'analytics_service.dart';

/// PremiumService handles secure Freemium limits (Firestore/Keychain synced) and RevenueCat subscriptions.
class PremiumService extends ChangeNotifier {
  static const String _freeScansKey = 'free_scans_left';
  static const String _premiumUserKey = 'is_premium_user';
  static const String _installationUuidKey = 'installation_uuid';
  static const String entitlementId = 'premium';
  
  final _secureStorage = const FlutterSecureStorage();
  final _firestoreService = getIt<FirestoreService>();
  StreamSubscription<User?>? _authSubscription;
  
  static bool get isPremiumReviewMode => globals.isPremiumReviewMode;

  bool _isPremium = false;
  int _freeScansLeft = 3;
  bool _isPurchasePending = false;
  String? _errorMessage;
  String? _deviceId;
  String? _currentUid;
  
  bool get isPremium => isPremiumReviewMode ? true : _isPremium;
  int get freeScansLeft => isPremiumReviewMode ? 999 : _freeScansLeft;
  bool get isPurchasePending => isPremiumReviewMode ? false : _isPurchasePending;
  String? get errorMessage => isPremiumReviewMode ? null : _errorMessage;
  bool get canAnalyze => isPremiumReviewMode ? true : (_isPremium || _freeScansLeft > 0);

  List<Package> _activeOfferings = [];
  List<Package> get activeOfferings => _activeOfferings;

  PremiumService() {
    _init();
  }

  Future<void> _init() async {
    if (isPremiumReviewMode) {
      _isPremium = true;
      _freeScansLeft = 999;
      notifyListeners();
      Logger.info('ℹ️ PremiumService initialized in Review Mode (automatic premium enabled)');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    // 1. Load basic local cache and secure storage for fast offline startup
    _isPremium = prefs.getBool(_premiumUserKey) ?? false;
    try {
      final secureScansStr = await _secureStorage.read(key: _freeScansKey);
      if (secureScansStr != null) {
        _freeScansLeft = int.tryParse(secureScansStr) ?? 3;
      } else {
        _freeScansLeft = prefs.getInt(_freeScansKey) ?? 3;
        await _secureStorage.write(key: _freeScansKey, value: _freeScansLeft.toString());
      }
    } catch (e) {
      Logger.error('Failed to read secure free scans: $e');
      _freeScansLeft = prefs.getInt(_freeScansKey) ?? 3;
    }
    notifyListeners();

    // 2. Load/Generate persistent device footprint (Keychain survives reinstall)
    try {
      _deviceId = await _secureStorage.read(key: _installationUuidKey);
      if (_deviceId == null) {
        _deviceId = _generateUniqueId();
        await _secureStorage.write(key: _installationUuidKey, value: _deviceId!);
      }
      Logger.info('🔑 Device Persistent ID: $_deviceId');
    } catch (e) {
      Logger.error('Failed to access secure storage: $e');
      _deviceId = prefs.getString(_installationUuidKey);
      if (_deviceId == null) {
        _deviceId = _generateUniqueId();
        await prefs.setString(_installationUuidKey, _deviceId!);
      }
    }

    // 3. Initialize RevenueCat
    await _initRevenueCat();

    // 4. Setup Auth State listener to sync scan counts
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    await _syncScansLimit();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      _currentUid = user?.uid;
      await _syncScansLimit();
    });
  }

  String _generateUniqueId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomVal = random.nextInt(1000000);
    return 'device_${timestamp}_$randomVal';
  }

  Future<void> _initRevenueCat() async {
    if (isPremiumReviewMode) return;
    try {
      // Load public API Keys from dotenv, or use mock keys
      final apiKeyIOS = dotenv.env['REVENUECAT_API_KEY_IOS'] ?? 'api_key_placeholder';
      final apiKeyAndroid = dotenv.env['REVENUECAT_API_KEY_ANDROID'] ?? 'api_key_placeholder';
      
      // Select appropriate key
      String apiKey = apiKeyAndroid;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        apiKey = apiKeyIOS;
      }
      
      await Purchases.setLogLevel(LogLevel.info);
      
      // Configure purchases_flutter
      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = _currentUid ?? _deviceId;
        
      await Purchases.configure(configuration);

      // Fetch customer info
      final customerInfo = await Purchases.getCustomerInfo();
      _updatePremiumStatus(customerInfo);

      // Listen for updates in real-time
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updatePremiumStatus(customerInfo);
      });

      // Load active offerings
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        _activeOfferings = offerings.current!.availablePackages;
        notifyListeners();
      }
      
      Logger.info('✅ RevenueCat initialized successfully.');
    } catch (e) {
      Logger.error('⚠️ RevenueCat initialization failed: $e. Using local cached fallback.');
      // Offline fallback: we keep whatever _isPremium was loaded from local preferences.
    }
  }

  void _updatePremiumStatus(CustomerInfo customerInfo) async {
    if (isPremiumReviewMode) return;
    final entitlementActive = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    if (_isPremium != entitlementActive) {
      _isPremium = entitlementActive;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumUserKey, _isPremium);
      notifyListeners();
    }
  }

  Future<void> _syncScansLimit() async {
    if (isPremiumReviewMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      int serverCount = 3;

      if (_currentUid != null) {
        // Logged-in user: get count from Firestore
        serverCount = await _firestoreService.getUserScansLeft(_currentUid!);
        
        // Anti-bypass check: If guest had fewer scans, sync guest's lower limit to the account
        final guestCount = prefs.getInt(_freeScansKey) ?? 3;
        if (guestCount < serverCount && guestCount >= 0) {
          serverCount = guestCount;
          await _firestoreService.updateUserScansLeft(_currentUid!, serverCount);
        }
      } else if (_deviceId != null) {
        // Guest user: get count from device collection in Firestore
        serverCount = await _firestoreService.getDeviceScansLeft(_deviceId!);
      }

      _freeScansLeft = serverCount;
      await prefs.setInt(_freeScansKey, _freeScansLeft);
      notifyListeners();
      Logger.info('🔄 Scans limit synced: $_freeScansLeft remaining.');
    } catch (e) {
      Logger.error('Failed to sync scans limit: $e. Falling back to local cache.');
    }
  }

  Future<void> consumeFreeScan() async {
    if (isPremiumReviewMode || _isPremium) return;
    
    if (_freeScansLeft > 0) {
      _freeScansLeft--;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_freeScansKey, _freeScansLeft);
      
      // Update secure keychain storage
      try {
        await _secureStorage.write(key: _freeScansKey, value: _freeScansLeft.toString());
      } catch (e) {
        Logger.error('Failed to write secure free scans: $e');
      }

      notifyListeners();

      // Sync asynchronously to Firestore
      try {
        if (_currentUid != null) {
          await _firestoreService.updateUserScansLeft(_currentUid!, _freeScansLeft);
        } else if (_deviceId != null) {
          await _firestoreService.updateDeviceScansLeft(_deviceId!, _freeScansLeft);
        }
        
        await AnalyticsService.logEvent(
          name: 'free_scan_consumed',
          parameters: {
            'scans_left': _freeScansLeft,
            'user_type': _currentUid != null ? 'registered' : 'guest'
          },
        );
      } catch (e) {
        Logger.error('Firestore limit sync deferred (offline/error): $e');
        // Firestore handles offline queuing internally, so the local decrement is safe.
      }
      
      Logger.info('Free scan consumed. $_freeScansLeft remaining.');
    }
  }

  Future<void> buyPremium(Package package) async {
    if (isPremiumReviewMode) {
      Logger.info('[Review Mode] Mock premium purchase bypassed.');
      return;
    }
    _isPurchasePending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _updatePremiumStatus(customerInfo);
      
      try {
        await AnalyticsService.logEvent(
          name: 'premium_purchase_success',
          parameters: {'package_id': package.identifier},
        );
      } catch (_) {}
      
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        _errorMessage = 'Purchase cancelled.';
      } else {
        _errorMessage = e.message ?? 'Purchase failed.';
      }
      Logger.error('Purchase failed: $errorCode - $e');
    } catch (e) {
      _errorMessage = 'Purchase failed: $e';
    } finally {
      _isPurchasePending = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (isPremiumReviewMode) {
      Logger.info('[Review Mode] Mock restore purchases bypassed.');
      return;
    }
    _isPurchasePending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updatePremiumStatus(customerInfo);
      
      if (_isPremium) {
        Logger.info('✅ Entitlements restored successfully.');
      } else {
        _errorMessage = 'No active subscriptions found to restore.';
      }
    } on PlatformException catch (e) {
      _errorMessage = e.message ?? 'Restore failed.';
      Logger.error('Restore failed: $e');
    } catch (e) {
      _errorMessage = 'Restore failed: $e';
    } finally {
      _isPurchasePending = false;
      notifyListeners();
    }
  }

  /// For simulator/sandbox testing fallback
  Future<void> simulatePremiumUnlock() async {
    if (isPremiumReviewMode) {
      Logger.info('[Review Mode] Mock simulated premium unlock bypassed.');
      return;
    }
    _isPurchasePending = true;
    _errorMessage = null;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumUserKey, true);
    _isPurchasePending = false;
    notifyListeners();
    Logger.info('✅ Simulated Premium unlocked successfully.');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
