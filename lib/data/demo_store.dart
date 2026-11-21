import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'store_api.dart';

/// In-memory backend used in demo mode (no Supabase configured).
/// Lets buyers explore the full storefront and admin panel instantly.
///
/// Demo state persists in the browser's local storage (via
/// shared_preferences), so an order placed on the storefront shows up
/// in the admin dashboard on the same device, and admin edits survive
/// reloads. Seeds are written on first run; real multi-device sync is
/// what the Supabase backend is for.
class DemoStoreApi implements StoreApi {
  static const _kVersion = 'storva_demo_v1';
  static const _kProducts = 'storva_demo_products';
  static const _kOrders = 'storva_demo_orders';
  static const _kOrderItems = 'storva_demo_order_items';
  static const _kCoupons = 'storva_demo_coupons';
  static const _kRates = 'storva_demo_rates';

  static bool _hydrated = false;
  static late List<Product> _products;
  static late List<Order> _orders;
  static late Map<String, List<OrderItem>> _orderItems;
  static late List<Coupon> _coupons;
  static late List<ShippingRate> _rates;

  Future<T> _latency<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 350), () => value);

  String _id() => 'demo-${DateTime.now().microsecondsSinceEpoch}';

  static Future<void> _hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_kVersion) == null) {
        _seedIntoMemory();
        await _persistAll();
        return;
      }
      _products = (jsonDecode(prefs.getString(_kProducts)!) as List)
          .map((e) => _productFromJson(e as Map<String, dynamic>))
          .toList();
      _orders = (jsonDecode(prefs.getString(_kOrders)!) as List)
          .map((e) => _orderFromJson(e as Map<String, dynamic>))
          .toList();
      _orderItems = (jsonDecode(prefs.getString(_kOrderItems)!) as Map).map(
        (k, v) => MapEntry(
          k as String,
          (v as List)
              .map((e) => _orderItemFromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      _coupons = (jsonDecode(prefs.getString(_kCoupons)!) as List)
          .map((e) => _couponFromJson(e as Map<String, dynamic>))
          .toList();
      _rates = (jsonDecode(prefs.getString(_kRates)!) as List)
          .map((e) => _rateFromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt or unavailable storage: fall back to seeds in memory.
      _seedIntoMemory();
    }
  }

  static void _seedIntoMemory() {
    _products = List.of(_seedProducts);
    _orders = List.of(_seedOrders);
    _orderItems = {
      for (final e in _seedOrderItems.entries) e.key: List.of(e.value),
    };
    _coupons = List.of(_seedCoupons);
    _rates = List.of(_seedRates);
  }

  static Future<void> _persistAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kVersion, '1');
      await prefs.setString(
        _kProducts,
        jsonEncode(_products.map(_productToJson).toList()),
      );
      await prefs.setString(
        _kOrders,
        jsonEncode(_orders.map(_orderToJson).toList()),
      );
      await prefs.setString(
        _kOrderItems,
        jsonEncode(
          _orderItems.map(
            (k, v) => MapEntry(k, v.map(_orderItemToJson).toList()),
          ),
        ),
      );
      await prefs.setString(
        _kCoupons,
        jsonEncode(_coupons.map(_couponToJson).toList()),
      );
      await prefs.setString(
        _kRates,
        jsonEncode(_rates.map(_rateToJson).toList()),
      );
    } catch (_) {
      // Storage full or blocked: keep running in memory.
    }
  }

  // ── JSON mappers ──────────────────────────────────────────────

  static Map<String, dynamic> _productToJson(Product p) => {
    'id': p.id,
    'name': p.name,
    'description': p.description,
    'price': p.price,
    'compareAtPrice': p.compareAtPrice,
    'category': p.category,
    'imageUrl': p.imageUrl,
    'isActive': p.isActive,
  };

  static Product _productFromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String?,
    price: (j['price'] as num).toDouble(),
    compareAtPrice: (j['compareAtPrice'] as num?)?.toDouble(),
    category: j['category'] as String? ?? 'General',
    imageUrl: j['imageUrl'] as String?,
    isActive: j['isActive'] as bool? ?? true,
  );

  static Map<String, dynamic> _orderItemToJson(OrderItem i) => {
    'productId': i.productId,
    'productName': i.productName,
    'price': i.price,
    'quantity': i.quantity,
  };

  static OrderItem _orderItemFromJson(Map<String, dynamic> j) => OrderItem(
    productId: j['productId'] as String?,
    productName: j['productName'] as String,
    price: (j['price'] as num).toDouble(),
    quantity: (j['quantity'] as num).toInt(),
  );

  static Map<String, dynamic> _orderToJson(Order o) => {
    'id': o.id,
    'customerName': o.customerName,
    'phone': o.phone,
    'region': o.region,
    'city': o.city,
    'address': o.address,
    'subtotal': o.subtotal,
    'discountAmount': o.discountAmount,
    'shippingCost': o.shippingCost,
    'couponCode': o.couponCode,
    'total': o.total,
    'status': o.status,
    'createdAt': o.createdAt.toIso8601String(),
  };

  static Order _orderFromJson(Map<String, dynamic> j) => Order(
    id: j['id'] as String,
    customerName: j['customerName'] as String,
    phone: j['phone'] as String,
    region: j['region'] as String,
    city: j['city'] as String,
    address: j['address'] as String,
    subtotal: (j['subtotal'] as num).toDouble(),
    discountAmount: (j['discountAmount'] as num).toDouble(),
    shippingCost: (j['shippingCost'] as num).toDouble(),
    couponCode: j['couponCode'] as String?,
    total: (j['total'] as num).toDouble(),
    status: j['status'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  static Map<String, dynamic> _couponToJson(Coupon c) => {
    'id': c.id,
    'code': c.code,
    'discountPercent': c.discountPercent,
    'isUsed': c.isUsed,
    'createdAt': c.createdAt.toIso8601String(),
    'usedAt': c.usedAt?.toIso8601String(),
  };

  static Coupon _couponFromJson(Map<String, dynamic> j) => Coupon(
    id: j['id'] as String,
    code: j['code'] as String,
    discountPercent: (j['discountPercent'] as num).toDouble(),
    isUsed: j['isUsed'] as bool? ?? false,
    createdAt: DateTime.parse(j['createdAt'] as String),
    usedAt: j['usedAt'] == null ? null : DateTime.parse(j['usedAt'] as String),
  );

  static Map<String, dynamic> _rateToJson(ShippingRate r) => {
    'id': r.id,
    'region': r.region,
    'shippingCost': r.shippingCost,
    'isActive': r.isActive,
  };

  static ShippingRate _rateFromJson(Map<String, dynamic> j) => ShippingRate(
    id: j['id'] as String,
    region: j['region'] as String,
    shippingCost: (j['shippingCost'] as num).toDouble(),
    isActive: j['isActive'] as bool? ?? true,
  );

  // ── Storefront ────────────────────────────────────────────────

  @override
  Future<List<Product>> fetchActiveProducts() async {
    await _hydrate();
    return _latency(_products.where((p) => p.isActive).toList());
  }

  @override
  Future<Product?> fetchProductById(String id) async {
    await _hydrate();
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<List<ShippingRate>> fetchActiveShippingRates() async {
    await _hydrate();
    return _latency(_rates.where((r) => r.isActive).toList());
  }

  @override
  Future<double?> validateCoupon(String code) async {
    await _hydrate();
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
    await _hydrate();
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
    await _persistAll();
    return id;
  }

  // ── Admin: products ───────────────────────────────────────────

  @override
  Future<List<Product>> fetchAllProducts() async {
    await _hydrate();
    return _latency(List.of(_products));
  }

  @override
  Future<String> createProduct(Product product) async {
    await _hydrate();
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
    await _persistAll();
    return id;
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _hydrate();
    final i = _products.indexWhere((p) => p.id == product.id);
    if (i != -1) _products[i] = product;
    await _persistAll();
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _hydrate();
    _products.removeWhere((p) => p.id == id);
    await _persistAll();
  }

  @override
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    // Demo mode can't store bytes; the admin form keeps a local preview.
    return 'demo-upload://$fileName';
  }

  // ── Admin: orders ─────────────────────────────────────────────

  @override
  Future<List<Order>> fetchAllOrders() async {
    await _hydrate();
    return _latency(List.of(_orders));
  }

  @override
  Future<List<OrderItem>> fetchOrderItems(String orderId) async {
    await _hydrate();
    return _latency(_orderItems[orderId] ?? const []);
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _hydrate();
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
    await _persistAll();
  }

  // ── Admin: coupons ────────────────────────────────────────────

  @override
  Future<List<Coupon>> fetchAllCoupons() async {
    await _hydrate();
    return _latency(List.of(_coupons));
  }

  @override
  Future<Coupon> createCoupon(double discountPercent) async {
    await _hydrate();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final code = List.generate(
      8,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
    final coupon = Coupon(
      id: _id(),
      code: code,
      discountPercent: discountPercent,
      isUsed: false,
      createdAt: DateTime.now(),
    );
    _coupons.insert(0, coupon);
    await _persistAll();
    return coupon;
  }

  @override
  Future<void> deleteCoupon(String id) async {
    await _hydrate();
    _coupons.removeWhere((c) => c.id == id);
    await _persistAll();
  }

  // ── Admin: shipping ───────────────────────────────────────────

  @override
  Future<List<ShippingRate>> fetchAllShippingRates() async {
    await _hydrate();
    return _latency(List.of(_rates));
  }

  @override
  Future<String> createShippingRate(String region, double cost) async {
    await _hydrate();
    final id = _id();
    _rates.add(
      ShippingRate(id: id, region: region, shippingCost: cost, isActive: true),
    );
    await _persistAll();
    return id;
  }

  @override
  Future<void> updateShippingRate({
    required String id,
    required double shippingCost,
    required bool isActive,
  }) async {
    await _hydrate();
    final i = _rates.indexWhere((r) => r.id == id);
    if (i == -1) return;
    _rates[i] = ShippingRate(
      id: id,
      region: _rates[i].region,
      shippingCost: shippingCost,
      isActive: isActive,
    );
    await _persistAll();
  }
}

// ── Seed content ────────────────────────────────────────────────

final _seedProducts = <Product>[
  Product(
    id: 'demo-1',
    name: 'Essential White Tee',
    description:
        'Heavyweight 220 gsm cotton tee with a boxy fit and a ribbed collar. '
        'Pre-shrunk and garment washed.',
    price: 29.00,
    category: 'Apparel',
    imageUrl:
        'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
  Product(
    id: 'demo-2',
    name: 'Camel Wool Blazer',
    description:
        'Soft-structured camel blazer in a warm wool blend with notch '
        'lapels, patch pockets and a relaxed fit.',
    price: 189.00,
    compareAtPrice: 240.00,
    category: 'Apparel',
    imageUrl:
        'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
  Product(
    id: 'demo-3',
    name: 'Retro Court Sneaker',
    description:
        'Low-top court sneaker in smooth white leather with perforated '
        'detailing and a cushioned cup sole.',
    price: 95.00,
    compareAtPrice: 120.00,
    category: 'Footwear',
    imageUrl:
        'https://images.unsplash.com/photo-1608231387042-66d1773070a5?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
  Product(
    id: 'demo-4',
    name: 'Ochre Trench Coat',
    description:
        'Water-resistant oversized trench with a belted waist, horn buttons '
        'and a storm flap.',
    price: 149.00,
    category: 'Apparel',
    imageUrl:
        'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
  Product(
    id: 'demo-5',
    name: 'Heritage Watch',
    description:
        'Slim 38 mm dress watch with a brushed case, mineral glass and '
        'a leather strap.',
    price: 199.00,
    compareAtPrice: 259.00,
    category: 'Accessories',
    imageUrl:
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80',
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
    category: 'Accessories',
    imageUrl:
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=800&q=80',
    isActive: true,
  ),
];

final _seedOrderItems = <String, List<OrderItem>>{
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
  ShippingRate(
    id: 'r3',
    region: 'Alexandria',
    shippingCost: 60,
    isActive: true,
  ),
  ShippingRate(
    id: 'r4',
    region: 'Other regions',
    shippingCost: 80,
    isActive: true,
  ),
];
