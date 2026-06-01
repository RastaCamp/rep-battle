import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'entitlement_service.dart';

/// Google Play product id for one-time Pro unlock ($4.99 USD in Play Console).
const String kProProductId = 'rep_battle_pro';

class BillingService extends ChangeNotifier {
  BillingService(this._entitlement);

  final EntitlementService _entitlement;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool storeAvailable = false;
  bool purchasePending = false;
  ProductDetails? proProduct;
  String? lastError;

  Future<void> init() async {
    if (kIsWeb) return;

    storeAvailable = await _iap.isAvailable();
    if (!storeAvailable) return;

    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object e) {
        lastError = e.toString();
        purchasePending = false;
        notifyListeners();
      },
    );

    await _queryProducts();
    await restorePurchases();
  }

  Future<void> _queryProducts() async {
    final response = await _iap.queryProductDetails({kProProductId});
    if (response.error != null) {
      lastError = response.error!.message;
    }
    if (response.productDetails.isNotEmpty) {
      proProduct = response.productDetails.first;
    }
    notifyListeners();
  }

  Future<void> buyPro() async {
    if (_entitlement.isPro) return;
    if (!storeAvailable || proProduct == null) {
      lastError = 'Store unavailable. Try again later.';
      notifyListeners();
      return;
    }
    lastError = null;
    purchasePending = true;
    notifyListeners();
    final param = PurchaseParam(productDetails: proProduct!);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    if (!storeAvailable) return;
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != kProProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          purchasePending = true;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          unawaited(_entitlement.grantProFromPurchase());
          purchasePending = false;
          lastError = null;
        case PurchaseStatus.error:
          purchasePending = false;
          lastError = purchase.error?.message ?? 'Purchase failed';
        case PurchaseStatus.canceled:
          purchasePending = false;
      }

      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }
    notifyListeners();
  }

  String get proPriceLabel =>
      proProduct?.price ?? r'$4.99';

  @override
  void dispose() {
    unawaited(_purchaseSub?.cancel());
    super.dispose();
  }
}
