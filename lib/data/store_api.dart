import 'dart:typed_data';

import '../models/models.dart';

/// Everything the app needs from a backend, in one contract.
///
/// Two implementations ship with the template:
///  * [DemoStoreApi]      - in-memory sample data, no setup required
///  * [SupabaseStoreApi]  - the real backend (lib/data/supabase_store.dart)
///
/// Point the app at your own backend by editing lib/core/config.dart.
abstract class StoreApi {
  // ── Storefront ────────────────────────────────────────────────
  Future<List<Product>> fetchActiveProducts();
  Future<Product?> fetchProductById(String id);
  Future<List<ShippingRate>> fetchActiveShippingRates();
  Future<double?> validateCoupon(String code);
  Future<String> createOrder({
    required String customerName,
    required String phone,
    required String region,
    required String city,
    required String address,
    required List<OrderItem> items,
    String? couponCode,
  });

  // ── Admin: products ───────────────────────────────────────────
  Future<List<Product>> fetchAllProducts();
  Future<String> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
  Future<String> uploadProductImage(Uint8List bytes, String fileName);

  // ── Admin: orders ─────────────────────────────────────────────
  Future<List<Order>> fetchAllOrders();
  Future<List<OrderItem>> fetchOrderItems(String orderId);
  Future<void> updateOrderStatus(String orderId, String status);

  // ── Admin: coupons ────────────────────────────────────────────
  Future<List<Coupon>> fetchAllCoupons();
  Future<Coupon> createCoupon(double discountPercent);
  Future<void> deleteCoupon(String id);

  // ── Admin: shipping ───────────────────────────────────────────
  Future<List<ShippingRate>> fetchAllShippingRates();
  Future<String> createShippingRate(String region, double cost);
  Future<void> updateShippingRate({
    required String id,
    required double shippingCost,
    required bool isActive,
  });
}
