/// All data models in one import.
library;

/// A sellable product.
class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final String category;
  final String? imageUrl;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.compareAtPrice,
    this.category = 'General',
    this.imageUrl,
    required this.isActive,
  });

  int? get discountPercent {
    final old = compareAtPrice;
    if (old == null || old <= price) return null;
    return (((old - price) / old) * 100).round();
  }

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    price: (map['price'] as num).toDouble(),
    compareAtPrice: (map['compare_at_price'] as num?)?.toDouble(),
    category: map['category'] as String? ?? 'General',
    imageUrl: map['image_url'] as String?,
    isActive: map['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'compare_at_price': compareAtPrice,
    'category': category,
    'image_url': imageUrl,
    'is_active': isActive,
  };

  Product copyWith({
    String? name,
    String? description,
    double? price,
    double? compareAtPrice,
    String? category,
    String? imageUrl,
    bool? isActive,
  }) => Product(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    compareAtPrice: compareAtPrice ?? this.compareAtPrice,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    isActive: isActive ?? this.isActive,
  );
}

/// One line of an order, sent to the backend when checking out.
class OrderItem {
  final String? id;
  final String? orderId;
  final String? productId;
  final String productName;
  final double price;
  final int quantity;

  const OrderItem({
    this.id,
    this.orderId,
    this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    id: map['id'] as String?,
    orderId: map['order_id'] as String?,
    productId: map['product_id'] as String?,
    productName: map['product_name'] as String,
    price: (map['price'] as num).toDouble(),
    quantity: map['quantity'] as int,
  );
}

/// A customer order.
class Order {
  final String id;
  final String customerName;
  final String phone;
  final String region;
  final String city;
  final String address;
  final double subtotal;
  final double discountAmount;
  final double shippingCost;
  final String? couponCode;
  final double total;
  final String status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.region,
    required this.city,
    required this.address,
    required this.subtotal,
    required this.discountAmount,
    required this.shippingCost,
    this.couponCode,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  static const List<String> statuses = [
    'new',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled',
  ];

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'New';
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  factory Order.fromMap(Map<String, dynamic> map) => Order(
    id: map['id'] as String,
    customerName: map['customer_name'] as String,
    phone: map['phone'] as String,
    region: map['region'] as String,
    city: map['city'] as String,
    address: map['address'] as String,
    subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
    discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
    shippingCost: (map['shipping_cost'] as num?)?.toDouble() ?? 0,
    couponCode: map['coupon_code'] as String?,
    total: (map['total'] as num).toDouble(),
    status: map['status'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}

/// A single-use discount code.
class Coupon {
  final String id;
  final String code;
  final double discountPercent;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime? usedAt;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.isUsed,
    required this.createdAt,
    this.usedAt,
  });

  factory Coupon.fromMap(Map<String, dynamic> map) => Coupon(
    id: map['id'] as String,
    code: map['code'] as String,
    discountPercent: (map['discount_percent'] as num).toDouble(),
    isUsed: map['is_used'] as bool? ?? false,
    createdAt: DateTime.parse(map['created_at'] as String),
    usedAt:
        map['used_at'] != null ? DateTime.parse(map['used_at'] as String) : null,
  );
}

/// Shipping price for one region (state / governorate / zone).
class ShippingRate {
  final String id;
  final String region;
  final double shippingCost;
  final bool isActive;

  const ShippingRate({
    required this.id,
    required this.region,
    required this.shippingCost,
    required this.isActive,
  });

  factory ShippingRate.fromMap(Map<String, dynamic> map) => ShippingRate(
    id: map['id'] as String,
    region: map['region'] as String,
    shippingCost: (map['shipping_cost'] as num).toDouble(),
    isActive: map['is_active'] as bool? ?? true,
  );
}
