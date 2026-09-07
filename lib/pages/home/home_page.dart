import 'package:flutter/material.dart';
import 'package:dollar_bills/pages/accounts/accounts_page.dart';
import 'package:dollar_bills/pages/liquidated/liquidated_movements_page.dart';
import 'package:dollar_bills/pages/movements/all_movements_page.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int _movKey = 0;
  int _liqKey = 0;
  int _accKey = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) _movKey++;
      if (index == 1) _liqKey++;
      if (index == 2) _accKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AllMovementsPage(key: ValueKey('mov_$_movKey')),
          LiquidatedMovementsPage(key: ValueKey('liq_$_liqKey')),
          AccountsPage(key: ValueKey('acc_$_accKey')),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.swap_horiz_rounded,
                  label: 'Movimientos',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Liquidados',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.account_balance_rounded,
                  label: 'Deudas',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? HexColor.mintLight : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? HexColor.mintPrimary : HexColor.textMuted,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: HexColor.mintPrimaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
