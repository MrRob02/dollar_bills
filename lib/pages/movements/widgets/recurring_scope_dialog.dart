import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:dollar_bills/models/movement_model.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';
import 'package:dollar_bills/pages/shared/widgets/custom_card.dart';

class RecurringScopeDialog extends StatelessWidget {
  final bool isDelete;
  final String title;
  final DateTime date;

  const RecurringScopeDialog({
    super.key,
    required this.isDelete,
    required this.title,
    required this.date,
  });

  static Future<RecurringScope?> show(
    BuildContext context, {
    required bool isDelete,
    required String title,
    required DateTime date,
  }) {
    return showDialog<RecurringScope>(
      context: context,
      builder: (ctx) => RecurringScopeDialog(
        isDelete: isDelete,
        title: title,
        date: date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMM yyyy', 'es_MX').format(date);
    final accentColor = isDelete ? HexColor.expenseRed : HexColor.mintPrimary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: CustomCard(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge Icon
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDelete
                      ? Icons.delete_outline_rounded
                      : Icons.edit_calendar_rounded,
                  color: accentColor,
                  size: 26,
                ),
              ),
            ),
            const Gap(14),

            // Header Texts
            Text(
              isDelete
                  ? '¿Eliminar movimiento recurrente?'
                  : '¿Cómo deseas aplicar los cambios?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const Gap(6),
            Text(
              '"$title" forma parte de una serie programada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: HexColor.textSecondary,
              ),
            ),
            const Gap(18),

            // Option 1: Solo este movimiento
            _buildOption(
              context: context,
              icon: Icons.event_rounded,
              scope: RecurringScope.onlyThis,
              title: 'Solo este movimiento',
              subtitle: isDelete
                  ? 'Elimina únicamente la fecha del $dateFormatted'
                  : 'Modifica únicamente la fecha del $dateFormatted',
              color: HexColor.mintPrimary,
            ),
            const Gap(10),

            // Option 2: Este y los posteriores
            _buildOption(
              context: context,
              icon: Icons.update_rounded,
              scope: RecurringScope.thisAndFuture,
              title: 'Este y los posteriores',
              subtitle: isDelete
                  ? 'Finaliza la serie antes del $dateFormatted'
                  : 'Aplica a partir del $dateFormatted en adelante',
              color: HexColor.foregroundBlue,
            ),
            const Gap(10),

            // Option 3: Todos los movimientos
            _buildOption(
              context: context,
              icon: Icons.repeat_rounded,
              scope: RecurringScope.all,
              title: 'Todos los movimientos',
              subtitle: isDelete
                  ? 'Elimina toda la serie programada'
                  : 'Aplica a toda la serie (pasados y futuros)',
              color: isDelete ? HexColor.expenseRed : HexColor.debtOrange,
            ),
            const Gap(16),

            // Botón Cancelar
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HexColor.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required RecurringScope scope,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(scope),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: HexColor.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
