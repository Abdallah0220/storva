import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/anim.dart';
import '../../core/config.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/store_api.dart';
import '../../models/models.dart';
import '../../state/cart_provider.dart';
import '../../widgets/lookbook_section.dart';
import '../../widgets/noir_hero.dart';
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
  final ScrollController _scroll = ScrollController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToGrid() {
    _scroll.animateTo(
      620,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Product>> _load() =>
      context.read<StoreApi>().fetchActiveProducts();

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
            _Header(onSearch: (q) => setState(() => _query = q)),
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
                    final matchesQuery =
                        q.isEmpty ||
                        p.name.toLowerCase().contains(q) ||
                        p.category.toLowerCase().contains(q);
                    return matchesCategory && matchesQuery;
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: CustomScrollView(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: ResponsiveCenter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Reveal(
                                  child: NoirHero(
                                    imageUrl:
                                        'https://images.unsplash.com/photo-1509631179647-0177331693ae?auto=format&fit=crop&w=1000&q=80',
                                    onCta: _scrollToGrid,
                                  ),
                                ),
                                Reveal(
                                  delay: const Duration(milliseconds: 120),
                                  child: LookbookSection(products: products),
                                ),
                                const SizedBox(height: 8),
                                Reveal(
                                  delay: const Duration(milliseconds: 180),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Reveal(
                                  delay: const Duration(milliseconds: 240),
                                  child: SizedBox(
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
                          // Lazy sliver grid: cards build as they near the
                          // viewport, so each one plays its Reveal entrance
                          // as the user scrolls to it.
                          SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final viewport = constraints.crossAxisExtent;
                              const maxWidth = 1100.0;
                              final contentWidth =
                                  (viewport < maxWidth ? viewport : maxWidth) -
                                  40;
                              final cols = gridColumns(contentWidth);
                              final horizontal = viewport > maxWidth
                                  ? (viewport - maxWidth) / 2 + 20
                                  : 20.0;
                              return SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontal,
                                ),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => Reveal(
                                      delay: Duration(
                                        milliseconds: 70 * (index % cols),
                                      ),
                                      offsetY: 26,
                                      child: ProductCard(
                                        product: filtered[index],
                                      ),
                                    ),
                                    childCount: filtered.length,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 0.66,
                                      ),
                                ),
                              );
                            },
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
        color: AppTheme.background,
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
                        Navigator.of(
                          context,
                        ).push(fadeSlideRoute(const CartPage()));
                      },
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                ),
                                child: child,
                              ),
                          child: Container(
                            key: ValueKey(cart.itemCount),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
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
        selectedColor: AppTheme.primary,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.textDark,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.6,
          fontSize: 12,
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
          AppConfig.storeName == 'Storva'
              ? 'Powered by Storva'
              : '${AppConfig.storeName} - powered by Storva',
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
