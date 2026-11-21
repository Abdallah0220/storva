import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/store_api.dart';
import '../../models/models.dart';
import '../../widgets/store_widgets.dart';

/// Store overview: revenue, order counts by status, recent orders.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<StoreApi>().fetchAllOrders();
  }

  Future<void> _reload() async {
    setState(() => _future = context.read<StoreApi>().fetchAllOrders());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
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
            title: 'Could not load orders',
            actionLabel: 'Retry',
            onAction: _reload,
          );
        }
        final orders = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: _reload,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _stats(orders),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent orders',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (orders.isEmpty)
                    const StateMessage(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders yet',
                    )
                  else
                    ...orders.take(5).map(_recentTile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stats(List<Order> orders) {
    final active = orders.where((o) => o.status != 'cancelled').toList();
    final revenue = active.fold<double>(0, (sum, o) => sum + o.total);
    final newCount = orders.where((o) => o.status == 'new').length;

    final cards = [
      (Icons.payments_outlined, 'Revenue', fmtMoney(revenue), AppTheme.success),
      (Icons.receipt_long_outlined, 'Orders', '${orders.length}', AppTheme.accent),
      (Icons.fiber_new_outlined, 'New', '$newCount', AppTheme.warning),
      (
        Icons.local_shipping_outlined,
        'In delivery',
        '${orders.where((o) => o.status == 'shipped').length}',
        AppTheme.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 800
            ? 4
            : constraints.maxWidth > 500
                ? 2
                : 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.9,
          children: cards
              .map(
                (c) => Container(
                  decoration: AppTheme.card,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(c.$1, color: c.$4, size: 22),
                      const Spacer(),
                      Text(
                        c.$3,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        c.$2,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _recentTile(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.card,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(order.status).withValues(alpha: 0.12),
          child: Icon(
            Icons.receipt_outlined,
            color: _statusColor(order.status),
            size: 20,
          ),
        ),
        title: Text(
          order.customerName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          DateFormat('d MMM, HH:mm').format(order.createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              fmtMoney(order.total),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              order.statusLabel,
              style: TextStyle(
                fontSize: 12,
                color: _statusColor(order.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color statusColorOf(String status) => _statusColor(status);

Color _statusColor(String status) {
  switch (status) {
    case 'new':
      return AppTheme.warning;
    case 'confirmed':
      return AppTheme.accent;
    case 'shipped':
      return AppTheme.primary;
    case 'delivered':
      return AppTheme.success;
    case 'cancelled':
      return AppTheme.danger;
    default:
      return AppTheme.textMuted;
  }
}
