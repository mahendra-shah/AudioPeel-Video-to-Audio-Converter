import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// Manages the "Remove Ads" non-consumable in-app purchase.
///
/// Call [initialise] once at app start-up, then use [purchaseRemoveAds]
/// and [restorePurchases] as needed. Listen to [isPurchased] via
/// [ChangeNotifier].
class IapService extends ChangeNotifier {
  static const _tag = 'IAP';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  bool _isPurchased = false;
  bool _isPurchasing = false;
  ProductDetails? _product;
  String? _error;

  /// Whether the "Remove Ads" product has been purchased.
  bool get isPurchased => _isPurchased;

  /// Whether a purchase transaction is in progress.
  bool get isPurchasing => _isPurchasing;

  /// Localised product details fetched from the store.
  ProductDetails? get product => _product;

  /// The last error message, if any.
  String? get error => _error;

  /// Formatted price from the store (e.g. "$1.99"), or the fallback.
  String get price => _product?.price ?? '\$1.99';

  // ─── Lifecycle ────────────────────────────────────────────────────

  /// Connects to the store, loads product details, and starts
  /// listening for purchase updates.
  Future<void> initialise() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      Logger.warning('In-app purchases not available', _tag);
      return;
    }

    // Listen for purchase stream events.
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (Object e) {
        Logger.error('Purchase stream error', error: e, tag: _tag);
      },
    );

    await _loadProducts();
  }

  /// Cleans up the purchase stream subscription.
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ─── Products ─────────────────────────────────────────────────────

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({
      AppConstants.removeAdsProductId,
    });

    if (response.error != null) {
      Logger.error('Failed to load products: ${response.error}', tag: _tag);
      return;
    }

    if (response.productDetails.isEmpty) {
      Logger.warning('No products found for Remove Ads', _tag);
      return;
    }

    _product = response.productDetails.first;
    Logger.info('Loaded product: ${_product!.id} – ${_product!.price}', _tag);
    notifyListeners();
  }

  // ─── Purchasing ───────────────────────────────────────────────────

  /// Initiates the non-consumable "Remove Ads" purchase.
  Future<void> purchaseRemoveAds() async {
    if (!_available || _product == null) {
      _error = 'Store not available';
      notifyListeners();
      return;
    }

    _isPurchasing = true;
    _error = null;
    notifyListeners();

    final purchaseParam = PurchaseParam(productDetails: _product!);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      Logger.error('Purchase initiation failed', error: e, tag: _tag);
      _isPurchasing = false;
      _error = 'Purchase failed. Please try again.';
      notifyListeners();
    }
  }

  /// Restores previously completed purchases (e.g. after reinstall).
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  // ─── Purchase Updates ─────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _isPurchased = true;
          _isPurchasing = false;
          _error = null;
          Logger.info('Purchase verified: ${purchase.productID}', _tag);

        case PurchaseStatus.error:
          _isPurchasing = false;
          _error = purchase.error?.message ?? 'Purchase failed';
          Logger.error('Purchase error: ${purchase.error}', tag: _tag);

        case PurchaseStatus.canceled:
          _isPurchasing = false;
          _error = null;
          Logger.info('Purchase cancelled', _tag);

        case PurchaseStatus.pending:
          _isPurchasing = true;
          Logger.info('Purchase pending', _tag);
      }

      // Complete pending purchases to avoid re-delivery.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }
}
