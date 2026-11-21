import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';

/// Shown after a successful order. Cash-on-delivery flow: the store
/// contacts the customer to confirm.
class OrderSuccessPage extends StatelessWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ResponsiveCenter(
            maxWidth: 460,
            child: Container(
              decoration: AppTheme.card,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.success,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Order placed!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thank you. We will call you shortly to confirm '
                    'your order and delivery time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: orderId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order ID copied')),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Order #$shortId',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.copy,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: const Text('Back to store'),
                    ),
                  ),
                  if (AppConfig.whatsappNumber.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          launchUrl(
                            Uri.parse(
                              'https://wa.me/${AppConfig.whatsappNumber}?text='
                              'Hello, I just placed order $shortId',
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: const Text('Message us on WhatsApp'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
