/// Phone number helpers for checkout and WhatsApp links.
library;

/// A dialling-code option shown in the checkout phone field.
class CountryCode {
  const CountryCode(this.name, this.dialCode);

  final String name;

  /// Digits only, no '+'.
  final String dialCode;
}

/// Country codes offered at checkout. AppConfig.defaultCountryCode is
/// preselected; customers ordering from elsewhere pick theirs, or type
/// the full international number (with + or 00) and it is kept as entered.
const kCountryCodes = <CountryCode>[
  CountryCode('Egypt', '20'),
  CountryCode('Saudi Arabia', '966'),
  CountryCode('UAE', '971'),
  CountryCode('Kuwait', '965'),
  CountryCode('Qatar', '974'),
  CountryCode('Bahrain', '973'),
  CountryCode('Oman', '968'),
  CountryCode('Jordan', '962'),
  CountryCode('Palestine', '970'),
  CountryCode('Lebanon', '961'),
  CountryCode('Iraq', '964'),
  CountryCode('Syria', '963'),
  CountryCode('Yemen', '967'),
  CountryCode('Libya', '218'),
  CountryCode('Sudan', '249'),
  CountryCode('Morocco', '212'),
  CountryCode('Algeria', '213'),
  CountryCode('Tunisia', '216'),
];

/// Normalizes a typed phone number to international digits only
/// (no '+', spaces or dashes), ready for wa.me links.
///
///  - "+2010..." or "002010..."   -> kept as entered ("2010...")
///  - "2010..." with default '20' -> kept (already has the country code)
///  - "010..."  with default '20' -> "2010..." (trunk zero dropped)
///  - "10..."   with default '20' -> "2010..." (country code added)
///
/// A full international number typed with + or 00 is never altered, and
/// a local number is prefixed exactly once with the selected code.
String normalizePhone(String raw, {required String defaultCountryCode}) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  final hasPlus = s.startsWith('+');
  var digits = s.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  if (hasPlus) return digits;
  if (digits.startsWith('00')) return digits.substring(2);
  final cc = defaultCountryCode.replaceAll(RegExp(r'\D'), '');
  if (cc.isNotEmpty &&
      digits.startsWith(cc) &&
      digits.length > cc.length + 6) {
    return digits;
  }
  digits = digits.replaceFirst(RegExp(r'^0+'), '');
  return cc + digits;
}

/// Loose E.164 sanity check: 8 to 15 digits after normalization.
bool isValidPhone(String raw, {required String defaultCountryCode}) {
  final n = normalizePhone(raw, defaultCountryCode: defaultCountryCode);
  return n.length >= 8 && n.length <= 15;
}
