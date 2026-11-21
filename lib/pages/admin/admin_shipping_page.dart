import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/store_api.dart';
import '../../models/models.dart';
import '../../widgets/store_widgets.dart';

/// Shipping regions and their delivery prices.
class AdminShippingPage extends StatefulWidget {
  const AdminShippingPage({super.key});

  @override
  State<AdminShippingPage> createState() => _AdminShippingPageState();
}

class _AdminShippingPageState extends State<AdminShippingPage> {
  late Future<List<ShippingRate>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<StoreApi>().fetchAllShippingRates();
  }

  Future<void> _reload() async {
    setState(() => _future = context.read<StoreApi>().fetchAllShippingRates());
    await _future;
  }

  Future<void> _addRegion() async {
    final nameController = TextEditingController();
    final costController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add shipping region'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Region name',
                hintText: 'e.g. Cairo, California, Zone B',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Shipping cost'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final region = nameController.text.trim();
    final cost = double.tryParse(costController.text.trim());
    if (region.isEmpty || cost == null || !mounted) return;
    await context.read<StoreApi>().createShippingRate(region, cost);
    _reload();
  }

  Future<void> _editRate(ShippingRate rate) async {
    final controller = TextEditingController(text: '${rate.shippingCost}');
    final cost = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shipping to ${rate.region}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Shipping cost'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (cost == null || !mounted) return;
    await context.read<StoreApi>().updateShippingRate(
          id: rate.id,
          shippingCost: cost,
          isActive: rate.isActive,
        );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRegion,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add region', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<ShippingRate>>(
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
              title: 'Could not load shipping rates',
              actionLabel: 'Retry',
              onAction: _reload,
            );
          }
          final rates = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: rates.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Shipping regions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }
                final rate = rates[index - 1];
                return ResponsiveCenter(
                  padding: EdgeInsets.zero,
                  child: Container(
                    decoration: AppTheme.card,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          size: 20,
                          color: AppTheme.accent,
                        ),
                      ),
                      title: Text(
                        rate.region,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        rate.isActive ? 'Active' : 'Hidden from checkout',
                        style: TextStyle(
                          fontSize: 12,
                          color: rate.isActive
                              ? AppTheme.success
                              : AppTheme.textMuted,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fmtMoney(rate.shippingCost),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            tooltip: 'Edit price',
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _editRate(rate),
                          ),
                          Switch(
                            value: rate.isActive,
                            onChanged: (v) async {
                              await context
                                  .read<StoreApi>()
                                  .updateShippingRate(
                                    id: rate.id,
                                    shippingCost: rate.shippingCost,
                                    isActive: v,
                                  );
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
