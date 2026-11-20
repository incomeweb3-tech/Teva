import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart';
import 'wallet.dart';

/// Diamond packages. Create the SAME product IDs in
/// Play Console > Monetize > In-app products (type: consumable).
/// Prices are set in Play Console, the app only shows Google's price.
const Map<String, int> kDiamondPackages = {
  'diamond_50': 50,
  'diamond_60': 60,
  'diamond_100': 100,
  'diamond_110': 110,
  'diamond_200': 200,
  'diamond_210': 210,
  'diamond_300': 300,
  'diamond_310': 310,
};

class BillingService extends ChangeNotifier {
  BillingService._();
  static final BillingService instance = BillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  bool loading = true;
  String? message;
  Map<String, ProductDetails> products = {};
  final Set<String> _handled = {};

  Future<void> init() async {
    _sub ??= _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      available = await _iap.isAvailable();
      if (available) {
        final res = await _iap.queryProductDetails(kDiamondPackages.keys.toSet());
        products = {for (final p in res.productDetails) p.id: p};
      }
    } catch (e) {
      available = false;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> buy(String productId) async {
    final p = products[productId];
    if (p == null) return;
    message = null;
    await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: p),
      autoConsume: true,
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final pd in list) {
      switch (pd.status) {
        case PurchaseStatus.pending:
          message = 'Payment pending...';
          break;
        case PurchaseStatus.error:
          message = 'Purchase failed. Please try again.';
          break;
        case PurchaseStatus.canceled:
          message = 'Purchase cancelled.';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final key = pd.purchaseID ?? '${pd.productID}-${pd.transactionDate}';
          if (!_handled.contains(key)) {
            _handled.add(key);
            // TODO(server): send pd.verificationData.serverVerificationData
            // to your backend, verify with Google Play Developer API, then
            // credit diamonds on the server.
            final d = kDiamondPackages[pd.productID] ?? 0;
            Wallet.instance.addDiamonds(d);
            final price = products[pd.productID]?.price ?? '';
            Wallet.instance.addHistory(
                '${DateTime.now().toString().substring(0, 16)}  +$d diamonds  $price');
            message = 'Added $d diamonds!';
          }
          break;
      }
      if (pd.pendingCompletePurchase) {
        await _iap.completePurchase(pd);
      }
    }
    notifyListeners();
  }
}
