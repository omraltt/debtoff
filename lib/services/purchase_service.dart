import 'dart:async';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/debt_provider.dart';

class PurchaseService {
  static const String premiumProductId = 'com.debtoff.premium';
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  // Initialize the purchase stream observer
  void initialize(DebtProvider provider) {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription?.cancel();
    _subscription = purchaseUpdated.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList, provider);
      },
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        // Silent catch for stream errors
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  // Handle transaction states from App Store Connect / Google Play Billing
  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList, DebtProvider provider) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Transaction is currently processing inside the App Store
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Purchase failed or was cancelled by the user
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        
        // Success! Set the user's local database state to Premium Active
        await provider.setPremium(true);
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  // Error reason from last purchase attempt (for UI error messages)
  String? lastError;

  // Trigger Apple In-App Purchase sheet
  Future<bool> buyPremium(DebtProvider provider) async {
    HapticFeedback.heavyImpact();
    lastError = null;
    
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      // In-app billing unavailable (e.g. child account restriction, parental controls)
      lastError = 'iap_unavailable';
      return false;
    }

    try {
      const Set<String> kIds = <String>{premiumProductId};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);
      
      if (response.notFoundIDs.contains(premiumProductId) || response.productDetails.isEmpty) {
        // Product not configured in App Store Connect yet
        lastError = 'iap_product_not_found';
        return false;
      }

      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      
      // Request Apple App Store to display the transaction sheet
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (_) {
      lastError = 'iap_error';
      return false;
    }
  }


  // Restore past purchases (Required by App Store review guidelines!)
  Future<void> restorePurchases() async {
    HapticFeedback.mediumImpact();
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;
    await _inAppPurchase.restorePurchases();
  }
}
