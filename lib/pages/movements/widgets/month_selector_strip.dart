import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';

class MonthSelectorStrip extends StatefulWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const MonthSelectorStrip({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  State<MonthSelectorStrip> createState() => _MonthSelectorStripState();
}

class _MonthSelectorStripState extends State<MonthSelectorStrip> {
  late final ScrollController _scrollController;
  late final List<DateTime> _months;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateMonths();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _generateMonths() {
    final now = DateTime.now();
    _months = [];
    // Generate from -12 months to +24 months
    for (int i = -12; i <= 24; i++) {
      _months.add(DateTime(now.year, now.month + i, 1));
    }
  }

  void _scrollToSelected() {
    final index = _months.indexWhere(
      (m) =>
          m.year == widget.selectedMonth.year &&
          m.month == widget.selectedMonth.month,
    );
    if (index != -1 && _scrollController.hasClients) {
      final offset = (index * 88.0) - (MediaQuery.of(context).size.width / 2) + 44.0;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant MonthSelectorStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM yy', 'es_MX');

    return SizedBox(
      height: 46,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final month = _months[index];
          final isSelected =
              month.year == widget.selectedMonth.year &&
              month.month == widget.selectedMonth.month;

          final label = format.format(month).toUpperCase();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: InkWell(
              onTap: () => widget.onMonthSelected(month),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? HexColor.textPrimary
                          : HexColor.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
