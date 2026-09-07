import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';

class DayGroupHeader extends StatelessWidget {
  final DateTime date;
  final double netAmount;

  const DayGroupHeader({
    super.key,
    required this.date,
    required this.netAmount,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    
    // Format: "5 Nov, Jueves"
    final dayNum = date.day;
    final monthName = DateFormat('MMM', 'es_MX').format(date);
    final weekdayName = DateFormat('EEEE', 'es_MX').format(date);
    final formattedWeekday = weekdayName.isNotEmpty 
        ? '${weekdayName[0].toUpperCase()}${weekdayName.substring(1)}'
        : '';
    final label = '$dayNum $monthName, $formattedWeekday';

    final isPositive = netAmount > 0;
    final isNegative = netAmount < 0;

    final Color amountColor = isPositive
        ? HexColor.incomeGreen
        : isNegative
            ? HexColor.expenseRed
            : HexColor.textMuted;

    final String sign = isPositive ? '+' : (isNegative ? '-' : '');
    final String amountStr = '$sign${currency.format(netAmount.abs())}';

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: HexColor.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            amountStr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
