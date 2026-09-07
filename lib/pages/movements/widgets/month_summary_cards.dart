import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';

class MonthSummaryCards extends StatelessWidget {
  final double income;
  final double expenses;

  const MonthSummaryCards({
    super.key,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final double net = income - expenses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Income Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: HexColor.mintPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: HexColor.mintPrimary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              size: 14,
                              color: HexColor.mintPrimaryDark,
                            ),
                          ),
                          const Gap(6),
                          Text(
                            '+ Ingresos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: HexColor.mintPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        '+${currency.format(income)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: HexColor.mintPrimaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(12),
              // Expense Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEECEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: HexColor.expenseRed.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: HexColor.expenseRed.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 14,
                              color: HexColor.expenseRed,
                            ),
                          ),
                          const Gap(6),
                          Text(
                            '- Gastos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: HexColor.expenseRed,
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        '-${currency.format(expenses)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: HexColor.expenseRed,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          // Sumatoria Ingresos / Gastos (Cuadro Gris)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF9CA3AF).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7280).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        size: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const Gap(8),
                    const Text(
                      'Sumatoria Ingresos / Gastos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${net > 0 ? '+' : ''}${currency.format(net)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: net > 0
                        ? HexColor.mintPrimaryDark
                        : (net < 0 ? HexColor.expenseRed : const Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
