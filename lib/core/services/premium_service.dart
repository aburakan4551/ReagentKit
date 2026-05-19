import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/logger.dart';

/// PremiumService handles Freemium logic, Free Scans limits, and In-App Purchases
class PremiumService extends ChangeNotifier {
  static const String _freeScansKey = 'free_scans_left';
  static const String _premiumUserKey = 'is_premium_user';
  static const String productId = 'ai_analysis_unlimited';
  
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  bool _isAvailable = false;
  bool _isPremium = false;
  int _freeScansLeft = 3;
  bool _isPurchasePending = false;
  String? _errorMessage;

  bool get isPremium => _isPremium;
  int get freeScansLeft => _freeScansLeft;
  bool get isPurchasePending => _isPurchasePending;
  String? get errorMessage => _errorMessage;
  bool get canAnalyze => _isPremium || _freeScansLeft > 0;

  PremiumService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load local state
    _isPremium = prefs.getBool(_premiumUserKey) ?? false;
    if (prefs.containsKey(_freeScansKey)) {
      _freeScansLeft = prefs.getInt(_freeScansKey)!;
    } else {
      _freeScansLeft = 3;
      await prefs.setInt(_freeScansKey, _freeScansLeft);
    }
    
    // Initialize IAP
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseDetailsUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) {
          Logger.error('IAP Error: $error');
          _errorMessage = 'Purchase stream error: $error';
          _isPurchasePending = false;
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  Future<void> consumeFreeScan() async {
    if (_isPremium) return;
    
    if (_freeScansLeft > 0) {
      _freeScansLeft--;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_freeScansKey, _freeScansLeft);
      
      try {
        await FirebaseAnalytics.instance.logEvent(
          name: 'free_scan_consumed',
          parameters: {'scans_left': _freeScansLeft},
        );
      } catch (_) {}
      
      notifyListeners();
      Logger.info('Free scan consumed. $_freeScansLeft remaining.');
    }
  }

  Future<void> buyPremium() async {
    if (!_isAvailable) {
      _errorMessage = 'Store is not available. Please check your connection.';
      notifyListeners();
      return;
    }

    _isPurchasePending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails({productId});
      if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
        _errorMessage = 'Product not found on the store.';
        _isPurchasePending = false;
        notifyListeners();
        return;
      }

      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
    } catch (e) {
      _errorMessage = 'Failed to initiate purchase: $e';
      _isPurchasePending = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    _isPurchasePending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _errorMessage = 'Failed to restore purchases: $e';
      _isPurchasePending = false;
      notifyListeners();
    }
  }

  Future<void> _onPurchaseDetailsUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isPurchasePending = true;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _errorMessage = purchaseDetails.error?.message ?? 'Unknown error';
        } else if (purchaseDetails.status == PurchaseStatus.purchased || 
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          if (purchaseDetails.productID == productId) {
            await _grantPremium();
          }
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
        
        _isPurchasePending = false;
        notifyListeners();
      }
    }
  }

  Future<void> _grantPremium() async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumUserKey, true);
    
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'premium_unlocked',
        parameters: {'method': 'in_app_purchase'},
      );
    } catch (_) {}
    
    Logger.info('✅ Lifetime premium unlocked successfully.');
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
