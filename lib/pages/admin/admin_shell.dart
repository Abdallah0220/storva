import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import 'admin_coupons_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_login_page.dart';
import 'admin_orders_page.dart';
import 'admin_products_page.dart';
import 'admin_shipping_page.dart';

/// Admin layout: sidebar on desktop, drawer on mobile.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _pages = [
    AdminDashboardPage(),
    AdminProductsPage(),
    AdminOrdersPage(),
    AdminCouponsPage(),
    AdminShippingPage(),
  ];

  static const _items = [
    (Icons.dashboard_outlined, 'Dashboard'),
    (Icons.inventory_2_outlined, 'Products'),
    (Icons.receipt_long_outlined, 'Orders'),
    (Icons.confirmation_num_outlined, 'Coupons'),
    (Icons.local_shipping_outlined, 'Shipping'),
  ];

  Future<void> _signOut() async {
    if (!AppConfig.demoMode) {
      await Supabase.instance.client.auth.signOut();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);

    final nav = _items
        .asMap()
        .entries
        .map(
          (e) => _NavTile(
            icon: e.value.$1,
            label: e.value.$2,
            selected: _index == e.key,
            onTap: () {
              setState(() => _index = e.key);
              if (!wide) Navigator.of(context).maybePop();
            },
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: wide
          ? null
          : AppBar(
              title: Text('${AppConfig.storeName} Admin'),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
      drawer: wide ? null : Drawer(child: SafeArea(child: _navColumn(nav))),
      body: Row(
        children: [
          if (wide)
            Container(
              width: 230,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: AppTheme.border)),
              ),
              child: SafeArea(child: _navColumn(nav)),
            ),
          Expanded(
            child: SafeArea(
              child: IndexedStack(index: _index, children: _pages),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navColumn(List<Widget> nav) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppConfig.storeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (AppConfig.demoMode)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Demo mode - sample data',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ...nav,
        const Spacer(),
        const Divider(height: 1),
        _NavTile(
          icon: Icons.logout,
          label: 'Sign out',
          selected: false,
          onTap: _signOut,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? AppTheme.accent.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            size: 20,
            color: selected ? AppTheme.accent : AppTheme.textMuted,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppTheme.accent : AppTheme.textDark,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
