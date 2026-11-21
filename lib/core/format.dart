import 'config.dart';

/// Money formatting helpers.
String fmtMoney(num value) =>
    '${AppConfig.currencySymbol}${value.toStringAsFixed(2)}';
