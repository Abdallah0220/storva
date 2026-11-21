import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/lookbook.dart';
import '../models/models.dart';
import '../state/cart_provider.dart';
import 'dashed_circle.dart';
import 'store_widgets.dart';

/// "Shop the look": an outfit photo with numbered hotspots.
/// Tapping a hotspot (or its row) selects it; the expanded list shows
/// ADD / IN BAG states and a running total for the selected pieces.
class LookbookSection extends StatefulWidget {
  final List<Product> products;

  const LookbookSection({super.key, required this.products});

  @override
  State<LookbookSection> createState() => _LookbookSectionState();
}

class _LookbookSectionState extends State<LookbookSection> {
  int _lookIndex = 0;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final looks = demoLooks
        .where((l) => resolveLook(l, widget.products).isNotEmpty)
        .toList();
    if (looks.isEmpty) return const SizedBox.shrink();

    final look = looks[_lookIndex % looks.length];
    final resolved = resolveLook(look, widget.products);
    final cart = context.watch<CartProvider>();

    final inBag = resolved
        .where((r) => cart.items.any((e) => e.product.id == r.product.id))
        .fold(0.0, (sum, r) => sum + r.product.price);
    final bagCount = resolved
        .where((r) => cart.items.any((e) => e.product.id == r.product.id))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SHOP THE LOOK', style: AppTheme.eyebrow),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text('${look.title}.', style: AppTheme.displayThin),
              ),
              if (looks.length > 1)
                Row(
                  children: [
                    for (var i = 0; i < looks.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _lookIndex = i;
                            _selected = null;
                          }),
                          child: DashedCircle(
                            size: 54,
                            filled: i == _lookIndex,
                            color: i == _lookIndex
                                ? AppTheme.primary
                                : AppTheme.dash,
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: ClipOval(
                                  child: ProductImage(
                                    imageUrl: looks[i].imageUrl,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final image = _LookImage(
                look: look,
                resolved: resolved,
                selected: _selected,
                onSelect: (n) =>
                    setState(() => _selected = _selected == n ? null : n),
              );
              final list = _LookList(
                resolved: resolved,
                selected: _selected,
                onSelect: (n) =>
                    setState(() => _selected = _selected == n ? null : n),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: image),
                    const SizedBox(width: 28),
                    Expanded(flex: 4, child: list),
                  ],
                );
              }
              return Column(
                children: [image, const SizedBox(height: 20), list],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [
                Text(
                  bagCount == 0
                      ? 'Nothing from this look in your bag yet'
                      : '$bagCount of ${resolved.length} pieces in your bag',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'TOTAL  ${fmtMoney(inBag)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LookImage extends StatelessWidget {
  final Look look;
  final List<({LookItem item, Product product})> resolved;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _LookImage({
    required this.look,
    required this.resolved,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(imageUrl: look.imageUrl),
                for (final r in resolved)
                  Positioned(
                    left: r.item.dx * constraints.maxWidth - 17,
                    top: r.item.dy * constraints.maxHeight - 17,
                    child: _Hotspot(
                      number: r.item.number,
                      active: selected == r.item.number,
                      onTap: () => onSelect(r.item.number),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Hotspot extends StatelessWidget {
  final int number;
  final bool active;
  final VoidCallback onTap;

  const _Hotspot({
    required this.number,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DashedCircle(
        size: 34,
        color: Colors.white,
        strokeWidth: 1.1,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: active ? 26 : 22,
            height: active ? 26 : 22,
            decoration: BoxDecoration(
              color: active ? Colors.white : AppTheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                number.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? AppTheme.primary : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LookList extends StatelessWidget {
  final List<({LookItem item, Product product})> resolved;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _LookList({
    required this.resolved,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Column(
      children: [
        for (var i = 0; i < resolved.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: AppTheme.border),
          _LookRow(
            entry: resolved[i],
            active: selected == resolved[i].item.number,
            inBag: cart.items.any(
              (e) => e.product.id == resolved[i].product.id,
            ),
            onTap: () => onSelect(resolved[i].item.number),
            onAdd: () {
              context.read<CartProvider>().add(resolved[i].product);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      '${resolved[i].product.name} saved to your bag',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
            },
          ),
        ],
      ],
    );
  }
}

class _LookRow extends StatelessWidget {
  final ({LookItem item, Product product}) entry;
  final bool active;
  final bool inBag;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _LookRow({
    required this.entry,
    required this.active,
    required this.inBag,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final product = entry.product;
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        color: active ? AppTheme.surface : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            DashedCircle(
              size: 56,
              filled: active,
              color: active ? AppTheme.primary : AppTheme.dash,
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: ClipOval(
                    child: ProductImage(imageUrl: product.imageUrl),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.item.number.toString().padLeft(2, '0')}  '
                    '${product.name.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              fmtMoney(product.price),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            _BagButton(inBag: inBag, onAdd: onAdd),
          ],
        ),
      ),
    );
  }
}

class _BagButton extends StatelessWidget {
  final bool inBag;
  final VoidCallback onAdd;

  const _BagButton({required this.inBag, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (inBag) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: AppTheme.pillRadius,
        ),
        child: const Text(
          'IN BAG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      );
    }
    return OutlinedButton(
      onPressed: onAdd,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'ADD',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
