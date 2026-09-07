import 'package:flutter/material.dart';

abstract class AppIcons {
  static const Map<int, IconData> _iconMap = {
    0xe518: Icons.receipt_long,
    0xe19f: Icons.credit_card,
    0xe49e: Icons.payments,
    0xe491: Icons.people,
    0xe8cc: Icons.shopping_cart,
    0xe56c: Icons.restaurant,
    0xe7ee: Icons.work,
    0xe88a: Icons.home,
    0xe531: Icons.directions_car,
    0xe904: Icons.flight,
    0xe3f7: Icons.medical_services,
    0xe80c: Icons.school,
    0xe338: Icons.sports_esports,
    0xe318: Icons.fitness_center,
    0xe541: Icons.local_cafe,
    0xe91d: Icons.pets,
    0xe32c: Icons.phone_iphone,
  };

  static IconData getIcon(int codePoint) {
    return _iconMap[codePoint] ?? Icons.receipt_long;
  }
}
