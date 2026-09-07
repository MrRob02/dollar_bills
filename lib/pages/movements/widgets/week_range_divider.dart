import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';

class WeekRangeDivider extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const WeekRangeDivider({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM dd', 'es_MX');
    final startStr = format.format(startDate);
    final endStr = format.format(endDate);
    final label = '$startStr - $endStr';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey.withValues(alpha: 0.25),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: HexColor.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: HexColor.textMuted,
                ),
              ],
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.withValues(alpha: 0.25),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
