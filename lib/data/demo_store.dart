import 'dart:math';
import 'dart:typed_data';

import '../models/models.dart';
import 'store_api.dart';

/// In-memory backend used in demo mode (no Supabase configured).
/// Lets buyers explore the full storefront and admin panel instantly.
class DemoStoreApi implements StoreApi {
  final List<Product> _products = List.of(_seedProducts);
  final List<Order> _orders = List.of(_seedOrders);
  final List<Coupon> _coupons = List.of(_seedCoupons);
  final List<ShippingRate> _rates = List.of(_seedRates);
  final Map<String, List<OrderItem>> _orderItems = {
    'demo-order-1': [
      const OrderItem(
        productName: 'Aurora Wireless Headphones',
        price: 129.99,
        quantity: 1,
      ),
      const OrderItem(productName: 'Lumen Desk Lamp', price: 45.50, quantity: 1),
    ],
    'demo-order-2': [
      const OrderItem(
        productName: 'Pulse Smart Watch',
        price: 199.00,
        quantity: 1,
      ),
    ],
  };

  Future<T> _latency<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 350), () => value);

  String _id() => 'demo-${DateTime.now().microsecondsSinceEpoch}';

  // ── Storefront ────────────────────────────────────────────────

  @override
  Future<List<Product>> fetchActiveProducts() =>
      _latency(_products.where((p) => p.isActive).toList());

  @override
  Future<Product?> fetchProductById(String id) async {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<List<ShippingRate>> fetchActiveShippingRates() =>
      _latency(_rates.where((r) => r.isActive).toList());

  @override
  Future<double?> validateCoupon(String code) async {
    for (final c in _coupons) {
      if (c.code.toUpperCase() == code.trim().toUpperCase() && !c.isUsed) {
        return c.discountPercent;
      }
    }
    return null;
  }

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
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );
    final rate = _rates.firstWhere(
      (r) => r.region == region,
      orElse: () => const ShippingRate(
        id: 'none',
        region: 'Other',
        shippingCost: 0,
        isActive: true,
      ),
    );
    var discount = 0.0;
    if (couponCode != null) {
      final pct = await validateCoupon(couponCode);
      if (pct != null) discount = subtotal * pct / 100;
    }
    final id = _id();
    _orders.insert(
      0,
      Order(
        id: id,
        customerName: customerName,
        phone: phone,
        region: region,
        city: city,
        address: address,
        subtotal: subtotal,
        discountAmount: discount,
        shippingCost: rate.shippingCost,
        couponCode: couponCode,
        total: subtotal - discount + rate.shippingCost,
        status: 'new',
        createdAt: DateTime.now(),
      ),
    );
    _orderItems[id] = items;
    return id;
  }

  // ── Admin: products ───────────────────────────────────────────

  @override
  Future<List<Product>> fetchAllProducts() => _latency(List.of(_products));

  @override
  Future<String> createProduct(Product product) async {
    final id = _id();
    _products.insert(
      0,
      Product(
        id: id,
        name: product.name,
        description: product.description,
        price: product.price,
        compareAtPrice: product.compareAtPrice,
        category: product.category,
        imageUrl: product.imageUrl,
        isActive: product.isActive,
      ),
    );
    return id;
  }

  @override
  Future<void> updateProduct(Product product) async {
    final i = _products.indexWhere((p) => p.id == product.id);
    if (i != -1) _products[i] = product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
  }

  @override
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    // Demo mode can't store bytes; the admin form keeps a local preview.
    return 'demo-upload://$fileName';
  }

  // ── Admin: orders ─────────────────────────────────────────────

  @override
  Future<List<Order>> fetchAllOrders() => _latency(List.of(_orders));

  @override
  Future<List<OrderItem>> fetchOrderItems(String orderId) =>
      _latency(_orderItems[orderId] ?? const []);

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i == -1) return;
    final o = _orders[i];
    _orders[i] = Order(
      id: o.id,
      customerName: o.customerName,
      phone: o.phone,
      region: o.region,
      city: o.city,
      address: o.address,
      subtotal: o.subtotal,
      discountAmount: o.discountAmount,
      shippingCost: o.shippingCost,
      couponCode: o.couponCode,
      total: o.total,
      status: status,
      createdAt: o.createdAt,
    );
  }

  // ── Admin: coupons ────────────────────────────────────────────

  @override
  Future<List<Coupon>> fetchAllCoupons() => _latency(List.of(_coupons));

  @override
  Future<Coupon> createCoupon(double discountPercent) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final code = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
    final coupon = Coupon(
      id: _id(),
      code: code,
      discountPercent: discountPercent,
      isUsed: false,
      createdAt: DateTime.now(),
    );
    _coupons.insert(0, coupon);
    return coupon;
  }

  @override
  Future<void> deleteCoupon(String id) async {
    _coupons.removeWhere((c) => c.id == id);
  }

  // ── Admin: shipping ───────────────────────────────────────────

  @override
  Future<List<ShippingRate>> fetchAllShippingRates() =>
      _latency(List.of(_rates));

  @override
  Future<String> createShippingRate(String region, double cost) async {
    final id = _id();
    _rates.add(
      ShippingRate(id: id, region: region, shippingCost: cost, isActive: true),
    );
    return id;
  }

  @override
  Future<void> updateShippingRate({
    required String id,
    required double shippingCost,
    required bool isActive,
  }) async {
    final i = _rates.indexWhere((r) => r.id == id);
    if (i == -1) return;
    _rates[i] = ShippingRate(
      id: id,
      region: _rates[i].region,
      shippingCost: shippingCost,
      isActive: isActive,
    );
  }
}

// ── Seed content ────────────────────────────────────────────────

final _seedProducts = <Product>[
  Product(
    id: 'demo-1',
    name: 'Aurora Wireless Headphones',
    description:
        'Over-ear wireless headphones with active noise cancellation, '
        '40-hour battery life and a foldable travel design.',
    price: 129.99,
    compareAtPrice: 179.99,
    category: 'Electronics',
    imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
  Product(
    id: 'demo-2',
    name: 'Pulse Smart Watch',
    description:
        'Fitness-focused smart watch with heart-rate tracking, GPS and '
        'a bright always-on display.',
    price: 199.00,
    category: 'Electronics',
    imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
  Product(
    id: 'demo-3',
    name: 'Lumen Desk Lamp',
    description:
        'Minimal desk lamp with three warmth levels, dimming and a USB-C '
        'charging port in the base.',
    price: 45.50,
    compareAtPrice: 59.00,
    category: 'Home',
    imageUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
  Product(
    id: 'demo-4',
    name: 'Glow Skin Care Set',
    description:
        'Three-step daily routine: gentle cleanser, vitamin C serum and '
        'a lightweight moisturizer.',
    price: 59.99,
    category: 'Beauty',
    imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
  Product(
    id: 'demo-5',
    name: 'Pro Yoga Mat',
    description:
        'Non-slip 6 mm yoga mat with alignment markers and a carry strap.',
    price: 27.75,
    category: 'Sports',
    imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
  Product(
    id: 'demo-6',
    name: 'Metro Backpack',
    description:
        'Water-resistant 20 L city backpack with a padded 15" laptop sleeve '
        'and a hidden pocket.',
    price: 74.20,
    compareAtPrice: 89.00,
    category: 'Fashion',
    imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
];

final _seedOrders = [
  Order(
    id: 'demo-order-1',
    customerName: 'Sara Ahmed',
    phone: '15550102030',
    region: 'Cairo',
    city: 'Nasr City',
    address: '12 Abbas El Akkad St, Apt 4',
    subtotal: 175.49,
    discountAmount: 17.55,
    shippingCost: 40.0,
    couponCode: 'WELCOME10',
    total: 197.94,
    status: 'new',
    createdAt: DateTime(2026, 11, 20, 14, 32),
  ),
  Order(
    id: 'demo-order-2',
    customerName: 'Omar Khaled',
    phone: '15550109988',
    region: 'Giza',
    city: 'Dokki',
    address: '8 Tahrir St',
    subtotal: 199.00,
    discountAmount: 0,
    shippingCost: 45.0,
    total: 244.00,
    status: 'shipped',
    createdAt: DateTime(2026, 11, 18, 9, 5),
  ),
];

final _seedCoupons = <Coupon>[
  Coupon(
    id: 'demo-coupon-1',
    code: 'WELCOME10',
    discountPercent: 10,
    isUsed: false,
    createdAt: DateTime(2026, 11, 1),
  ),
  Coupon(
    id: 'demo-coupon-2',
    code: 'VIP25OFF',
    discountPercent: 25,
    isUsed: true,
    createdAt: DateTime(2026, 10, 12),
    usedAt: DateTime(2026, 10, 30),
  ),
];

final _seedRates = <ShippingRate>[
  ShippingRate(id: 'r1', region: 'Cairo', shippingCost: 40, isActive: true),
  ShippingRate(id: 'r2', region: 'Giza', shippingCost: 45, isActive: true),
  ShippingRate(id: 'r3', region: 'Alexandria', shippingCost: 60, isActive: true),
  ShippingRate(id: 'r4', region: 'Other regions', shippingCost: 80, isActive: true),
];
