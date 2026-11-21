import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:storva/core/theme.dart';
import 'package:storva/data/demo_store.dart';
import 'package:storva/data/store_api.dart';
import 'package:storva/pages/admin/admin_shell.dart';
import 'package:storva/pages/storefront/home_page.dart';
import 'package:storva/pages/storefront/order_success_page.dart';
import 'package:storva/pages/storefront/product_details_page.dart';
import 'package:storva/state/cart_provider.dart';

Future<void> loadFonts() async {
  final poppins = FontLoader('Poppins')
    ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Poppins-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf'));
  await poppins.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(File('/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytes().then((b) => b.buffer.asByteData()));
  await icons.load();
}

const demoAssets = [
  'assets/demo/headphones.png',
  'assets/demo/watch.png',
  'assets/demo/lamp.png',
  'assets/demo/skincare.png',
  'assets/demo/yogamat.png',
  'assets/demo/backpack.png',
];

Widget wrap(Widget child, {CartProvider? cart}) {
  return MultiProvider(
    providers: [
      Provider<StoreApi>(create: (_) => DemoStoreApi()),
      ChangeNotifierProvider<CartProvider>.value(value: cart ?? CartProvider()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: child,
    ),
  );
}

void setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(824, 1784);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await tester.pump();
    // Decode demo images into the cache so they paint in the golden.
    final context = tester.element(find.byType(Scaffold).first);
    for (final asset in demoAssets) {
      await precacheImage(AssetImage(asset), context);
    }
    await tester.pump();
  });
  // Flush the fake-time demo latency timers.
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(loadFonts);

  testWidgets('shot home', (tester) async {
    setPhone(tester);
    await tester.pumpWidget(wrap(const HomePage()));
    await settle(tester);
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/01-home.png'),
    );
  });

  testWidgets('shot product details', (tester) async {
    setPhone(tester);
    await tester.pumpWidget(
      wrap(const ProductDetailsPage(productId: 'demo-1')),
    );
    await settle(tester);
    await expectLater(
      find.byType(ProductDetailsPage),
      matchesGoldenFile('goldens/02-product.png'),
    );
  });

  testWidgets('shot order success', (tester) async {
    setPhone(tester);
    await tester.pumpWidget(
      wrap(const OrderSuccessPage(orderId: '9f4c2ab1-77dd-4e10')),
    );
    await settle(tester);
    await expectLater(
      find.byType(OrderSuccessPage),
      matchesGoldenFile('goldens/04-success.png'),
    );
  });

  testWidgets('shot admin dashboard', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const AdminShell()));
    await settle(tester);
    await expectLater(
      find.byType(AdminShell),
      matchesGoldenFile('goldens/05-admin.png'),
    );
  });
}
