import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/store_api.dart';
import '../../models/models.dart';
import '../../state/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_widgets.dart';
import 'cart_page.dart';

/// Public storefront: header, category filter, search, product grid.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Product>> _future;
  String _query = '';
  String? _category;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Product>> _load() => context.read<StoreApi>().fetchActiveProducts();

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onSearch: (q) => setState(() => _query = q),
            ),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _GridSkeleton();
                  }
                  if (snapshot.hasError) {
                    return StateMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load products',
                      message: 'Check your connection and try again.',
                      actionLabel: 'Retry',
                      onAction: _refresh,
                    );
                  }
                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return const StateMessage(
                      icon: Icons.storefront_outlined,
                      title: 'No products yet',
                      message: 'Add products from the admin panel (#/admin).',
                    );
                  }

                  final categories = products
                      .map((p) => p.category)
                      .toSet()
                      .toList();
                  final filtered = products.where((p) {
                    final matchesCategory =
                        _category == null || p.category == _category;
                    final q = _query.trim().toLowerCase();
                    final matchesQuery = q.isEmpty ||
                        p.name.toLowerCase().contains(q) ||
                        p.category.toLowerCase().contains(q);
                    return matchesCategory && matchesQuery;
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: ResponsiveCenter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  _category ?? 'All products',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${filtered.length} items',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 40,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      _CategoryChip(
                                        label: 'All',
                                        selected: _category == null,
                                        onTap: () =>
                                            setState(() => _category = null),
                                      ),
                                      ...categories.map(
                                        (c) => _CategoryChip(
                                          label: c,
                                          selected: _category == c,
                                          onTap: () =>
                                              setState(() => _category = c),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        if (filtered.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: StateMessage(
                              icon: Icons.search_off_outlined,
                              title: 'Nothing matches',
                              message: 'Try another search or category.',
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                            child: ResponsiveCenter(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          gridColumns(constraints.maxWidth),
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.66,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) =>
                                        ProductCard(product: filtered[index]),
                                  );
                                },
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: _Footer()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<String> onSearch;

  const _Header({required this.onSearch});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: ResponsiveCenter(
        maxWidth: 1140,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: AppTheme.accent),
            const SizedBox(width: 8),
            Text(
              AppConfig.storeName,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: wide ? 'Search products...' : 'Search...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CartPage()),
                        );
                      },
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.accent.withValues(alpha: 0.14),
        labelStyle: TextStyle(
          color: selected ? AppTheme.accent : AppTheme.textDark,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Center(
        child: Text(
          '${AppConfig.storeName} - powered by Storva',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ResponsiveCenter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cols = gridColumns(constraints.maxWidth);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.66,
              ),
              itemCount: cols * 2,
              itemBuilder: (_, _) => const SkeletonBlock(height: 260),
            );
          },
        ),
      ),
    );
  }
}
