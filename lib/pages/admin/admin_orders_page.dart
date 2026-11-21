import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/store_api.dart';
import '../../models/models.dart';
import '../../widgets/store_widgets.dart';
import 'admin_dashboard_page.dart' show statusColorOf;

/// Order list with expandable details and status management.
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  late Future<List<Order>> _future;
  String? _statusFilter;

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
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return StateMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load orders',
            actionLabel: 'Retry',
            onAction: _reload,
          );
        }
        final orders = (snapshot.data ?? []).where((o) {
          return _statusFilter == null || o.status == _statusFilter;
        }).toList();

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const ResponsiveCenter(
                padding: EdgeInsets.zero,
                child: Text(
                  'Orders',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('All', null),
                    ...Order.statuses.map((s) => _filterChip(
                          s[0].toUpperCase() + s.substring(1),
                          s,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                const StateMessage(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders here',
                )
              else
                ...orders.map(
                  (o) => ResponsiveCenter(
                    padding: EdgeInsets.zero,
                    child: _OrderCard(
                      order: o,
                      onStatusChanged: _reload,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String? status) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = status),
        selectedColor: AppTheme.accent.withValues(alpha: 0.14),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  final Future<void> Function() onStatusChanged;

  const _OrderCard({required this.order, required this.onStatusChanged});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;
  Future<List<OrderItem>>? _itemsFuture;

  Order get order => widget.order;

  @override
  Widget build(BuildContext context) {
    final color = statusColorOf(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.card,
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
                _itemsFuture ??=
                    context.read<StoreApi>().fetchOrderItems(order.id);
              });
            },
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.receipt_outlined, color: color, size: 20),
            ),
            title: Text(
              order.customerName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${DateFormat('d MMM, HH:mm').format(order.createdAt)} - '
              '${order.region}',
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
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.phone_outlined, order.phone),
                  const SizedBox(height: 6),
                  _infoRow(
                    Icons.location_on_outlined,
                    '${order.address}, ${order.city}, ${order.region}',
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<OrderItem>>(
                    future: _itemsFuture,
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return const Text(
                          'Loading items...',
                          style: TextStyle(color: AppTheme.textMuted),
                        );
                      }
                      return Column(
                        children: items
                            .map(
                              (item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.productName} '
                                        'x${item.quantity}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      fmtMoney(item.price * item.quantity),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _moneyRow('Subtotal', fmtMoney(order.subtotal)),
                  if (order.discountAmount > 0)
                    _moneyRow(
                      'Discount ${order.couponCode ?? ''}',
                      '-${fmtMoney(order.discountAmount)}',
                    ),
                  _moneyRow('Shipping', fmtMoney(order.shippingCost)),
                  _moneyRow('Total', fmtMoney(order.total), bold: true),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownButton<String>(
                        value: order.status,
                        underline: const SizedBox.shrink(),
                        items: Order.statuses
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s[0].toUpperCase() + s.substring(1),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (status) async {
                          if (status == null) return;
                          await context
                              .read<StoreApi>()
                              .updateOrderStatus(order.id, status);
                          await widget.onStatusChanged();
                        },
                      ),
                      if (AppConfig.whatsappNumber.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () {
                            launchUrl(
                              Uri.parse(
                                'https://wa.me/${order.phone.replaceAll(RegExp(r'\D'), '')}',
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_outlined, size: 16),
                          label: const Text('WhatsApp customer'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _moneyRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
