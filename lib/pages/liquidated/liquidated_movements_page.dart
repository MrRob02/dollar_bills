import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:dollar_bills/models/movement_model.dart';
import 'package:dollar_bills/pages/liquidated/liquidated_movements_node.dart';
import 'package:dollar_bills/pages/movements/widgets/movement_card.dart';
import 'package:dollar_bills/pages/shared/dialogs/app_snackbar.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';
import 'package:dollar_bills/pages/shared/widgets/custom_scaffold.dart';
import 'package:trinity/widgets/node_provider.dart';
import 'package:trinity/widgets/signal_builder.dart';
import 'package:trinity/widgets/signal_listener.dart';

class LiquidatedMovementsPage extends StatefulWidget {
  const LiquidatedMovementsPage({super.key});

  @override
  State<LiquidatedMovementsPage> createState() => _LiquidatedMovementsPageState();
}

class _LiquidatedMovementsPageState extends State<LiquidatedMovementsPage> {
  final TextEditingController _searchController = TextEditingController();
  // Filter: 0 = Todos, 1 = Solo Entradas, 2 = Solo Salidas
  int _typeFilter = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmUnliquidate(
    BuildContext context,
    LiquidatedMovementsNode node,
    MovementModel movement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatusDialog(
        type: CustomSnackBarType.warning,
        title: 'Deshacer Liquidación',
        subtitle:
            '¿Deseas revertir la liquidación de "${movement.title}"? El monto volverá al estado programado y se revertirá del balance.',
        continueText: 'Deshacer',
        cancelText: 'Cancelar',
        onContinue: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );

    if (confirmed == true) {
      await node.unliquidateMovement(movement.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return NodeProvider.builder(
      create: () => LiquidatedMovementsNode(),
      builder: (context, node) {
        return SignalListenerMany(
          listeners: [
            SignalListenerItem.of(
              signal: node.error,
              listener: (previous, next) {
                if (next != null) {
                  node.clearError();
                  AppSnackBarWith(context).show(message: next);
                }
              },
            ),
            SignalListenerItem.of(
              signal: node.isUnliquidatedSuccess,
              listener: (previous, next) {
                if (next) {
                  node.isUnliquidatedSuccess.value = false;
                  AppSnackBarWith(context).show(
                    message: 'Liquidación revertida exitosamente',
                    type: CustomSnackBarType.success,
                  );
                }
              },
            ),
          ],
          child: SignalBuilderMany<ReadableLiquidatedMovementsNode>(
            signals: {
              node.liquidatedMovements,
              node.isLoading,
              node.fullScreenLoading,
            },
            builder: (context, readable) {
              // Compute liquidated totals
              double totalIncome = 0.0;
              double totalExpense = 0.0;
              for (final m in readable.liquidatedMovements) {
                if (m.isIncome) {
                  totalIncome += m.amount;
                } else {
                  totalExpense += m.amount;
                }
              }

              return CustomScaffold(
                title: 'Movimientos Liquidados',
                showBackButton: false,
                fullScreenLoading: readable.fullScreenLoading,
                isLoading: readable.isLoading,
                onRefresh: node.fetchData,
                body: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, textValue, _) {
                    final query = textValue.text.trim().toLowerCase();

                    final filtered = readable.liquidatedMovements.where((m) {
                      final matchesQuery = query.isEmpty ||
                          m.title.toLowerCase().contains(query) ||
                          (m.accountName ?? '').toLowerCase().contains(query);

                      if (!matchesQuery) return false;

                      if (_typeFilter == 1) return m.isIncome;
                      if (_typeFilter == 2) return m.isExpense;
                      return true;
                    }).toList();

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Summary Card
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: HexColor.mintLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.verified_rounded,
                                        color: HexColor.mintPrimary,
                                        size: 18,
                                      ),
                                    ),
                                    const Gap(8),
                                    Text(
                                      'Historial de Cobros y Pagos Reales',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: HexColor.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: HexColor.incomeGreenLight,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Ingresado',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: HexColor.incomeGreen,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Gap(4),
                                            Text(
                                              currency.format(totalIncome),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: HexColor.incomeGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Gap(12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: HexColor.expenseRedLight,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Egresado',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: HexColor.expenseRed,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Gap(4),
                                            Text(
                                              currency.format(totalExpense),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: HexColor.expenseRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Search and Filter Bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Buscar en liquidados...',
                                      hintStyle: TextStyle(
                                        color: HexColor.textMuted,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: HexColor.mintPrimary,
                                      ),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 18),
                                              onPressed: () => _searchController.clear(),
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(10),
                                // Filter chips
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ChoiceChip(
                                        label: Text(
                                          'Todos (${readable.liquidatedMovements.length})',
                                        ),
                                        selected: _typeFilter == 0,
                                        selectedColor: HexColor.mintPrimary,
                                        labelStyle: TextStyle(
                                          color: _typeFilter == 0
                                              ? Colors.white
                                              : HexColor.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        onSelected: (_) =>
                                            setState(() => _typeFilter = 0),
                                      ),
                                      const Gap(8),
                                      ChoiceChip(
                                        label: const Text('Solo Entradas'),
                                        selected: _typeFilter == 1,
                                        selectedColor: HexColor.mintPrimary,
                                        labelStyle: TextStyle(
                                          color: _typeFilter == 1
                                              ? Colors.white
                                              : HexColor.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        onSelected: (_) =>
                                            setState(() => _typeFilter = 1),
                                      ),
                                      const Gap(8),
                                      ChoiceChip(
                                        label: const Text('Solo Salidas'),
                                        selected: _typeFilter == 2,
                                        selectedColor: HexColor.mintPrimary,
                                        labelStyle: TextStyle(
                                          color: _typeFilter == 2
                                              ? Colors.white
                                              : HexColor.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        onSelected: (_) =>
                                            setState(() => _typeFilter = 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // List of Liquidated Movements
                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 56,
                                      color: HexColor.textMuted.withValues(alpha: 0.5),
                                    ),
                                    const Gap(12),
                                    Text(
                                      query.isNotEmpty
                                          ? 'No hay movimientos que coincidan con "$query"'
                                          : 'No tienes movimientos liquidados todavía',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: HexColor.textSecondary,
                                      ),
                                    ),
                                    const Gap(6),
                                    Text(
                                      'Cuando liquides un movimiento programado aparecerá aquí en el orden en que fue liquidado.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: HexColor.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final movement = filtered[index];
                                return MovementCard(
                                  movement: movement,
                                  showLiquidationDateOnly: true,
                                  onUnliquidate: () =>
                                      _confirmUnliquidate(context, node, movement),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        const SliverToBoxAdapter(child: Gap(40)),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
