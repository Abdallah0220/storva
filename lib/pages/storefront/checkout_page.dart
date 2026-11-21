import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/store_api.dart';
import '../../models/models.dart';
import '../../state/cart_provider.dart';
import '../../widgets/store_widgets.dart';
import 'order_success_page.dart';

/// Checkout: contact + address form, shipping region, coupon,
/// live order summary. Prices are recomputed server-side.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _couponController = TextEditingController();

  late Future<List<ShippingRate>> _ratesFuture;
  ShippingRate? _selectedRate;
  double? _couponPercent;
  String? _couponError;
  bool _placingOrder = false;

  @override
  void initState() {
    super.initState();
    _ratesFuture = context.read<StoreApi>().fetchActiveShippingRates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    final percent = await context.read<StoreApi>().validateCoupon(code);
    setState(() {
      _couponPercent = percent;
      _couponError = percent == null ? 'Invalid or already used code' : null;
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a shipping region')),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    setState(() => _placingOrder = true);

    try {
      final orderId = await context.read<StoreApi>().createOrder(
            customerName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            region: _selectedRate!.region,
            city: _cityController.text.trim(),
            address: _addressController.text.trim(),
            items: cart.toOrderItems(),
            couponCode: _couponPercent != null
                ? _couponController.text.trim()
                : null,
          );

      if (!mounted) return;
      cart.clear();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderSuccessPage(orderId: orderId)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not place the order. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: cart.isEmpty
            ? const StateMessage(
                icon: Icons.shopping_bag_outlined,
                title: 'Nothing to check out',
                message: 'Your cart is empty.',
              )
            : FutureBuilder<List<ShippingRate>>(
                future: _ratesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final rates = snapshot.data ?? [];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ResponsiveCenter(
                      maxWidth: 900,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 700;
                          final form = _buildForm(rates);
                          final summary = _buildSummary(cart);
                          if (wide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: form),
                                const SizedBox(width: 24),
                                Expanded(flex: 2, child: summary),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              form,
                              const SizedBox(height: 20),
                              summary,
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildForm(List<ShippingRate> rates) {
    return Form(
      key: _formKey,
      child: Container(
        decoration: AppTheme.card,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ShippingRate>(
              initialValue: _selectedRate,
              decoration: const InputDecoration(
                labelText: 'Shipping region',
                prefixIcon: Icon(Icons.local_shipping_outlined, size: 20),
              ),
              items: rates
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text('${r.region} - ${fmtMoney(r.shippingCost)}'),
                    ),
                  )
                  .toList(),
              onChanged: (r) => setState(() => _selectedRate = r),
              validator: (r) => r == null ? 'Choose your region' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city_outlined, size: 20),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Street address',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
              validator: _required,
            ),
            const SizedBox(height: 20),
            const Text(
              'Discount code',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      errorText: _couponError,
                      prefixIcon:
                          const Icon(Icons.confirmation_num_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _applyCoupon,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            if (_couponPercent != null) ...[
              const SizedBox(height: 8),
              Text(
                'Coupon applied: ${_couponPercent!.toStringAsFixed(0)}% off',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(CartProvider cart) {
    final subtotal = cart.subtotal;
    final shipping = _selectedRate?.shippingCost ?? 0;
    final discount =
        _couponPercent != null ? subtotal * _couponPercent! / 100 : 0.0;
    final total = subtotal - discount + shipping;

    return Container(
      decoration: AppTheme.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order summary',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ...cart.items.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.product.name} x${entry.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    fmtMoney(entry.lineTotal),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          _row('Subtotal', fmtMoney(subtotal)),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _row('Discount', '-${fmtMoney(discount)}', color: AppTheme.success),
          ],
          const SizedBox(height: 6),
          _row(
            'Shipping',
            _selectedRate == null ? '-' : fmtMoney(shipping),
          ),
          const Divider(height: 24),
          _row('Total', fmtMoney(total), bold: true),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _placingOrder ? null : _placeOrder,
              child: _placingOrder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Place order',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Cash on delivery. The store confirms your order by phone.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppTheme.textDark,
            fontSize: bold ? 17 : 14,
          ),
        ),
      ],
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;
}
