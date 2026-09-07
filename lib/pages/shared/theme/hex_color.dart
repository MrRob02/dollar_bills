import 'dart:ui';

class HexColor extends Color {
  HexColor(String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  // Mint Green Palette
  static Color get mintPrimary => const Color(0xFF3EB489);
  static Color get mintPrimaryDark => const Color(0xFF288562);
  static Color get mintLight => const Color(0xFFE8F8F3);
  static Color get mintAccent => const Color(0xFF2EC4B6);
  static Color get mintSoftBackground => const Color(0xFFF2FAF7);

  // General app colors
  static Color get backgroundWhite => const Color(0xFFFFFFFF);
  static Color get backgroundLight => const Color(0xFFF6F8FA);
  static Color get backgroundGrey100 => const Color(0xFFF1F3F5);
  static Color get backgroundGrey200 => const Color(0xFFE9ECEF);
  static Color get textPrimary => const Color(0xFF1E293B);
  static Color get textSecondary => const Color(0xFF64748B);
  static Color get textMuted => const Color(0xFF94A3B8);

  // Financial colors
  static Color get incomeGreen => const Color(0xFF10B981);
  static Color get incomeGreenLight => const Color(0xFFECFDF5);
  static Color get expenseRed => const Color(0xFFEF4444);
  static Color get expenseRedLight => const Color(0xFFFEF2F2);
  static Color get debtOrange => const Color(0xFFF59E0B);
  static Color get debtorBlue => const Color(0xFF3B82F6);

  // Alerts
  static Color get foregroundOrange => const Color(0xFFF97316);
  static Color get foregroundBlue => const Color(0xFF0284C7);
  static Color get labelRed => const Color(0xFFDC2626);
  static Color get labelGreen => const Color(0xFF16A34A);
}
