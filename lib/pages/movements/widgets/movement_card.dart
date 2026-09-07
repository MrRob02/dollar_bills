import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:dollar_bills/models/movement_model.dart';
import 'package:dollar_bills/pages/shared/theme/app_icons.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';
import 'package:dollar_bills/pages/shared/widgets/custom_card.dart';

class MovementCard extends StatelessWidget {
  final MovementModel movement;
  final VoidCallback? onToggleLiquidation;
  final VoidCallback? onLiquidate;
  final VoidCallback? onUnliquidate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showLiquidationDateOnly;

  const MovementCard({
    super.key,
    required this.movement,
    this.onToggleLiquidation,
    this.onLiquidate,
    this.onUnliquidate,
    this.onEdit,
    this.onDelete,
    this.showLiquidationDateOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final dateFormat = DateFormat('dd MMM yyyy', 'es_MX');
    final movementColor = HexColor(movement.colorHex);

    final scheduledDateStr = dateFormat.format(movement.scheduledDate);
    final liquidationDateStr = movement.liquidationDate != null
        ? dateFormat.format(movement.liquidationDate!)
        : null;

    final VoidCallback? handleToggle = onToggleLiquidation ??
        (movement.isLiquidated ? onUnliquidate : onLiquidate);

    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: handleToggle,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Circular icon with movement color
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: movementColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.getIcon(movement.iconCodePoint),
                color: movementColor,
                size: 22,
              ),
            ),
            const Gap(12),

            // Title, account/description, and tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          movement.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: HexColor.textPrimary,
                            decoration: movement.isLiquidated
                                ? TextDecoration.none
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (movement.isRecurring) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: HexColor.mintLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            movement.recurrenceType.displayName,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: HexColor.mintPrimaryDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(3),

                  // Subtitle: account name or description
                  if (movement.description != null &&
                      movement.description!.isNotEmpty) ...[
                    Text(
                      movement.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: HexColor.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                  ],

                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      if (movement.hasCustomAccount) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: HexColor.debtOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            movement.accountName!,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: HexColor.debtOrange,
                            ),
                          ),
                        ),
                      ],
                      if (!movement.affectsBalance && movement.isLiquidated) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: HexColor.debtOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Saldo contemplado',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: HexColor.debtOrange,
                            ),
                          ),
                        ),
                      ],
                      if (showLiquidationDateOnly && liquidationDateStr != null) ...[
                        Text(
                          'Liquidado: $liquidationDateStr',
                          style: TextStyle(
                            fontSize: 11,
                            color: HexColor.mintPrimaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        Text(
                          scheduledDateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: HexColor.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Gap(8),

            // Amount and Circular Toggle Checkbox
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${movement.isIncome ? '+' : '-'}${currency.format(movement.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: movement.isIncome
                        ? HexColor.incomeGreen
                        : HexColor.expenseRed,
                  ),
                ),
                if (movement.isLiquidated && liquidationDateStr != null && !showLiquidationDateOnly) ...[
                  const Gap(2),
                  Text(
                    'Liq: $liquidationDateStr',
                    style: TextStyle(
                      fontSize: 10,
                      color: HexColor.textMuted,
                    ),
                  ),
                ],
              ],
            ),
            const Gap(10),

            // Quick circular checkbox (○ when pending, ✓ when liquidated)
            GestureDetector(
              onTap: handleToggle,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: movement.isLiquidated
                      ? HexColor.mintPrimary
                      : Colors.transparent,
                  border: Border.all(
                    color: movement.isLiquidated
                        ? HexColor.mintPrimary
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: movement.isLiquidated
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),

            if (onEdit != null || onDelete != null) ...[
              const Gap(4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 18,
                iconColor: HexColor.textMuted,
                onSelected: (val) {
                  if (val == 'edit') {
                    onEdit?.call();
                  } else if (val == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: HexColor.mintPrimaryDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Editar',
                            style: TextStyle(
                              color: HexColor.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Eliminar',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
