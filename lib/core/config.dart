/// Store configuration for Storva.
///
/// ─────────────────────────────────────────────────────────────
/// BUYER SETUP: everything you need to edit lives in this file.
/// See DOCUMENTATION.html for the full walkthrough.
/// ─────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._();

  /// Your store name, shown in the header, title and emails.
  static const String storeName = 'Storva';

  /// Currency symbol used across storefront, checkout and admin.
  static const String currencySymbol = '\$';

  /// WhatsApp number (country code + number, digits only) used for the
  /// "contact us" / order follow-up buttons. Leave empty to hide them.
  static const String whatsappNumber = '15550102299';

  /// ── Supabase connection ─────────────────────────────────────
  /// 1. Create a free project at https://supabase.com
  /// 2. Run supabase/schema.sql in its SQL editor
  /// 3. Paste your Project URL and anon public key below
  ///
  /// While these placeholders are untouched the app runs in DEMO MODE
  /// with built-in sample data, so you can preview everything first.
  static const String supabaseUrl = 'https://twaobefblnhqriqnlocl.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_ZZPJHI71Tef3O2SJDokrPQ_nJRiel86';

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('YOUR_') &&
      !supabaseAnonKey.contains('YOUR_');

  /// Demo mode = no backend required, sample data in memory.
  static bool get demoMode => !isConfigured;
}
