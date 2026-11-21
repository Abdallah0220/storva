import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/store_api.dart';
import '../../models/models.dart';
import '../../widgets/store_widgets.dart';

/// Single-use discount codes: generate, copy, delete.
class AdminCouponsPage extends StatefulWidget {
  const AdminCouponsPage({super.key});

  @override
  State<AdminCouponsPage> createState() => _AdminCouponsPageState();
}

class _AdminCouponsPageState extends State<AdminCouponsPage> {
  late Future<List<Coupon>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<StoreApi>().fetchAllCoupons();
  }

  Future<void> _reload() async {
    setState(() => _future = context.read<StoreApi>().fetchAllCoupons());
    await _future;
  }

  Future<void> _createCoupon() async {
    final controller = TextEditingController(text: '10');
    final percent = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New coupon'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Discount percent',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (percent == null || !mounted) return;
    try {
      await context.read<StoreApi>().createCoupon(percent);
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount must be between 1 and 100')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCoupon,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New coupon', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<Coupon>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (snapshot.hasError) {
            return StateMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load coupons',
              actionLabel: 'Retry',
              onAction: _reload,
            );
          }
          final coupons = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: coupons.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Coupons',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }
                final coupon = coupons[index - 1];
                return ResponsiveCenter(
                  padding: EdgeInsets.zero,
                  child: Container(
                    decoration: AppTheme.card,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (coupon.isUsed
                                ? AppTheme.textMuted
                                : AppTheme.success)
                            .withValues(alpha: 0.12),
                        child: Icon(
                          coupon.isUsed
                              ? Icons.check_circle_outline
                              : Icons.confirmation_num_outlined,
                          size: 20,
                          color: coupon.isUsed
                              ? AppTheme.textMuted
                              : AppTheme.success,
                        ),
                      ),
                      title: Text(
                        coupon.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      subtitle: Text(
                        coupon.isUsed
                            ? 'Used${coupon.usedAt != null ? ' on ${DateFormat('d MMM yyyy').format(coupon.usedAt!)}' : ''}'
                            : '${coupon.discountPercent.toStringAsFixed(0)}% off - active',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Copy code',
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: coupon.code),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied')),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppTheme.danger,
                            ),
                            onPressed: () async {
                              await context
                                  .read<StoreApi>()
                                  .deleteCoupon(coupon.id);
                              _reload();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
