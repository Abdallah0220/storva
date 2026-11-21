import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'data/demo_store.dart';
import 'data/store_api.dart';
import 'data/supabase_store.dart';
import 'pages/admin/admin_login_page.dart';
import 'pages/admin/admin_shell.dart';
import 'pages/storefront/home_page.dart';
import 'state/cart_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  // Flutter Web uses the hash URL strategy by default:
  // https://your-store.com/#/admin opens the admin panel.
  final isAdminRoute = Uri.base.fragment.startsWith('/admin');

  runApp(StorvaApp(isAdminRoute: isAdminRoute));
}

class StorvaApp extends StatelessWidget {
  final bool isAdminRoute;

  const StorvaApp({super.key, required this.isAdminRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StoreApi>(
          create: (_) =>
              AppConfig.demoMode ? DemoStoreApi() : SupabaseStoreApi(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.storeName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: isAdminRoute ? const _AdminGate() : const HomePage(),
      ),
    );
  }
}

/// Decides between the admin login and the admin panel.
class _AdminGate extends StatelessWidget {
  const _AdminGate();

  @override
  Widget build(BuildContext context) {
    // Demo mode has no auth: go straight in so buyers can explore.
    if (AppConfig.demoMode) return const AdminShell();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const AdminLoginPage();
    return const AdminShell();
  }
}
