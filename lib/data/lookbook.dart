import '../models/models.dart';

/// One numbered hotspot on a lookbook outfit photo.
///
/// [dx] and [dy] are fractional positions (0..1) over the outfit image,
/// so the same config works on any screen size.
class LookItem {
  final int number;
  final String productId;
  final double dx;
  final double dy;

  const LookItem({
    required this.number,
    required this.productId,
    required this.dx,
    required this.dy,
  });
}

/// A shoppable outfit: one hero photo plus numbered product hotspots.
class Look {
  final String id;
  final String title;
  final String imageUrl;
  final List<LookItem> items;

  const Look({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.items,
  });
}

/// The looks shown on the storefront.
///
/// Buyers re-skinning the store edit this list (or, with a backend,
/// drive it from their own data source). Product ids must match
/// products returned by the StoreApi; unknown ids are skipped.
const demoLooks = <Look>[
  Look(
    id: 'look-1',
    title: 'Off Grid',
    imageUrl:
        'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=1000&q=80',
    items: [
      LookItem(number: 1, productId: 'demo-4', dx: 0.50, dy: 0.32),
      LookItem(number: 2, productId: 'demo-6', dx: 0.72, dy: 0.52),
      LookItem(number: 3, productId: 'demo-3', dx: 0.50, dy: 0.88),
    ],
  ),
  Look(
    id: 'look-2',
    title: 'City Moto',
    imageUrl:
        'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?auto=format&fit=crop&w=1000&q=80',
    items: [
      LookItem(number: 1, productId: 'demo-2', dx: 0.50, dy: 0.35),
      LookItem(number: 2, productId: 'demo-1', dx: 0.42, dy: 0.55),
      LookItem(number: 3, productId: 'demo-5', dx: 0.62, dy: 0.62),
    ],
  ),
];

/// Resolve a look's items against the live product list.
List<({LookItem item, Product product})> resolveLook(
  Look look,
  List<Product> products,
) {
  final byId = {for (final p in products) p.id: p};
  return [
    for (final item in look.items)
      if (byId[item.productId] != null) (item: item, product: byId[item.productId]!),
  ];
}
