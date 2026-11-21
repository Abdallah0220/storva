import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'store_api.dart';

/// Real backend, backed by Supabase (Postgres + Auth + Storage).
/// The database schema and security policies live in supabase/schema.sql.
class SupabaseStoreApi implements StoreApi {
  final SupabaseClient _client = Supabase.instance.client;

  static const String imageBucket = 'product-images';

  // ── Storefront ────────────────────────────────────────────────

  @override
  Future<List<Product>> fetchActiveProducts() async {
    final data = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (data as List).map((m) => Product.fromMap(m)).toList();
  }

  @override
  Future<Product?> fetchProductById(String id) async {
    final data =
        await _client.from('products').select().eq('id', id).maybeSingle();
    return data == null ? null : Product.fromMap(data);
  }

  @override
  Future<List<ShippingRate>> fetchActiveShippingRates() async {
    final data = await _client
        .from('shipping_rates')
        .select()
        .eq('is_active', true)
        .order('region');
    return (data as List).map((m) => ShippingRate.fromMap(m)).toList();
  }

  /// Returns the discount percent for a valid, unused code, else null.
  /// Server-side function: the client never sees coupon rows.
  @override
  Future<double?> validateCoupon(String code) async {
    if (code.trim().isEmpty) return null;
    final result = await _client.rpc(
      'validate_coupon',
      params: {'p_code': code.trim()},
    );
    if (result is List && result.isNotEmpty) {
      final row = result.first as Map<String, dynamic>;
      if (row['is_valid'] == true) {
        return (row['discount_percent'] as num).toDouble();
      }
    }
    return null;
  }

  /// Creates the order through a SECURITY DEFINER function that
  /// recomputes all prices server-side (the client only sends
  /// product ids and quantities, so totals can't be tampered with).
  @override
  Future<String> createOrder({
    required String customerName,
    required String phone,
    required String region,
    required String city,
    required String address,
    required List<OrderItem> items,
    String? couponCode,
  }) async {
    final result = await _client.rpc(
      'create_order_with_items',
      params: {
        'p_customer_name': customerName,
        'p_phone': phone,
        'p_region': region,
        'p_city': city,
        'p_address': address,
        'p_items': items
            .map((e) => {'product_id': e.productId, 'quantity': e.quantity})
            .toList(),
        'p_coupon_code': couponCode,
      },
    );
    return result as String;
  }

  // ── Admin: products ───────────────────────────────────────────

  @override
  Future<List<Product>> fetchAllProducts() async {
    final data = await _client
        .from('products')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((m) => Product.fromMap(m)).toList();
  }

  @override
  Future<String> createProduct(Product product) async {
    final data =
        await _client.from('products').insert(product.toMap()).select().single();
    return data['id'] as String;
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _client.from('products').update(product.toMap()).eq('id', product.id);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  @override
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '${timestamp}_$safeName';

    await _client.storage
        .from(imageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return _client.storage.from(imageBucket).getPublicUrl(path);
  }

  // ── Admin: orders ─────────────────────────────────────────────

  @override
  Future<List<Order>> fetchAllOrders() async {
    final data = await _client
        .from('orders')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((m) => Order.fromMap(m)).toList();
  }

  @override
  Future<List<OrderItem>> fetchOrderItems(String orderId) async {
    final data =
        await _client.from('order_items').select().eq('order_id', orderId);
    return (data as List).map((m) => OrderItem.fromMap(m)).toList();
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.from('orders').update({'status': status}).eq('id', orderId);
  }

  // ── Admin: coupons ────────────────────────────────────────────

  @override
  Future<List<Coupon>> fetchAllCoupons() async {
    final data = await _client
        .from('coupons')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((m) => Coupon.fromMap(m)).toList();
  }

  @override
  Future<Coupon> createCoupon(double discountPercent) async {
    if (discountPercent <= 0 || discountPercent > 100) {
      throw ArgumentError('Discount must be between 1 and 100');
    }
    final data = await _client.rpc(
      'generate_coupon',
      params: {'p_discount_percent': discountPercent},
    );
    return Coupon.fromMap(data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCoupon(String id) async {
    await _client.from('coupons').delete().eq('id', id);
  }

  // ── Admin: shipping ───────────────────────────────────────────

  @override
  Future<List<ShippingRate>> fetchAllShippingRates() async {
    final data = await _client.from('shipping_rates').select().order('region');
    return (data as List).map((m) => ShippingRate.fromMap(m)).toList();
  }

  @override
  Future<String> createShippingRate(String region, double cost) async {
    final data = await _client
        .from('shipping_rates')
        .insert({'region': region, 'shipping_cost': cost})
        .select()
        .single();
    return data['id'] as String;
  }

  @override
  Future<void> updateShippingRate({
    required String id,
    required double shippingCost,
    required bool isActive,
  }) async {
    await _client
        .from('shipping_rates')
        .update({'shipping_cost': shippingCost, 'is_active': isActive})
        .eq('id', id);
  }
}
