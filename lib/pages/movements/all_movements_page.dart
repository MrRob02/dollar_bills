import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:dollar_bills/models/movement_model.dart';
import 'package:dollar_bills/pages/movements/add_movement_page.dart';
import 'package:dollar_bills/pages/movements/movements_node.dart';
import 'package:dollar_bills/pages/movements/widgets/day_group_header.dart';
import 'package:dollar_bills/pages/movements/widgets/initial_balance_dialog.dart';
import 'package:dollar_bills/pages/movements/widgets/month_selector_strip.dart';
import 'package:dollar_bills/pages/movements/widgets/month_summary_cards.dart';
import 'package:dollar_bills/pages/movements/widgets/movement_card.dart';
import 'package:dollar_bills/pages/movements/widgets/recurring_scope_dialog.dart';
import 'package:dollar_bills/pages/shared/dialogs/app_snackbar.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';
import 'package:dollar_bills/pages/shared/widgets/custom_scaffold.dart';
import 'package:trinity/widgets/node_provider.dart';
import 'package:trinity/widgets/signal_builder.dart';
import 'package:trinity/widgets/signal_listener.dart';

class AllMovementsPage extends StatefulWidget {
  const AllMovementsPage({super.key});

  @override
  State<AllMovementsPage> createState() => _AllMovementsPageState();
}

class _AllMovementsPageState extends State<AllMovementsPage> {
  final TextEditingController _searchController = TextEditingController();
  // Filter chips: 0 = Todos, 1 = Programados, 2 = Liquidados
  int _statusFilter = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkInitialSetup(
    BuildContext context,
    MovementsNode node,
    bool isDone,
    double currentBalance,
  ) {
    if (!isDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final result = await showDialog<double>(
          context: context,
          barrierDismissible: false,
          builder: (_) => InitialBalanceDialog(
            currentBalance: currentBalance,
            isFirstTime: true,
          ),
        );
        if (result != null) {
          await node.setInitialBalance(result);
          if (context.mounted) {
            AppSnackBarWith(context).show(
              message: 'Balance inicial configurado correctamente',
              type: CustomSnackBarType.success,
            );
          }
        }
      });
    }
  }

  Future<void> _openEditBalanceDialog(
    BuildContext context,
    MovementsNode node,
    double currentBalance,
  ) async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => InitialBalanceDialog(
        currentBalance: currentBalance,
        isFirstTime: false,
      ),
    );
    if (result != null) {
      await node.updateBalance(result);
      if (context.mounted) {
        AppSnackBarWith(context).show(
          message: 'Balance actualizado con éxito',
          type: CustomSnackBarType.success,
        );
      }
    }
  }

  Future<void> _editMovement(
    BuildContext context,
    MovementsNode node,
    MovementModel movement, [
    DateTime? date,
  ]) async {
    final res = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMovementPage(
          movementToEdit: movement,
          occurrenceDate: date,
        ),
      ),
    );
    if (res == true) {
      await node.fetchData();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MovementsNode node,
    MovementModel movement, [
    DateTime? date,
  ]) async {
    if (movement.isRecurring) {
      final scope = await RecurringScopeDialog.show(
        context,
        isDelete: true,
        title: movement.title,
        date: date ?? movement.scheduledDate,
      );
      if (scope != null) {
        await node.deleteMovement(
          movement.id,
          date: date ?? movement.scheduledDate,
          scope: scope,
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatusDialog(
        type: CustomSnackBarType.warning,
        title: 'Eliminar Movimiento',
        subtitle: '¿Estás seguro de que deseas eliminar "${movement.title}"?',
        continueText: 'Eliminar',
        cancelText: 'Cancelar',
        onContinue: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );

    if (confirmed == true) {
      await node.deleteMovement(movement.id);
    }
  }

  Widget _buildMonthChangeLabel(DateTime date) {
    final monthFormat = DateFormat('MMMM yyyy', 'es_MX');
    final monthStr = monthFormat.format(date);
    final capitalized = monthStr.isNotEmpty
        ? '${monthStr[0].toUpperCase()}${monthStr.substring(1)}'
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey.withValues(alpha: 0.3),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: HexColor.mintLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: HexColor.mintPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 14,
                    color: HexColor.mintPrimaryDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    capitalized.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: HexColor.mintPrimaryDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.withValues(alpha: 0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return NodeProvider.builder(
      create: () => MovementsNode(),
      builder: (context, node) {
        return SignalListenerMany(
          listeners: [
            SignalListenerItem.of(
              signal: node.error,
              listener: (previous, next) {
                if (next != null) {
                  node.clearError();
                  AppSnackBarWith(context).show(message: next.toString());
                }
              },
            ),
            SignalListenerItem.of(
              signal: node.isLiquidatedSuccess,
              listener: (previous, next) {
                if (next) {
                  node.isLiquidatedSuccess.value = false;
                  AppSnackBarWith(context).show(
                    message: 'Estado de liquidación actualizado',
                    type: CustomSnackBarType.success,
                  );
                }
              },
            ),
            SignalListenerItem.of(
              signal: node.isDeletedSuccess,
              listener: (previous, next) {
                if (next) {
                  node.isDeletedSuccess.value = false;
                  AppSnackBarWith(context).show(
                    message: 'Movimiento eliminado correctamente',
                    type: CustomSnackBarType.success,
                  );
                }
              },
            ),
            SignalListenerItem.of(
              signal: node.isUpdatedSuccess,
              listener: (previous, next) {
                if (next) {
                  node.isUpdatedSuccess.value = false;
                  AppSnackBarWith(context).show(
                    message: 'Movimiento actualizado correctamente',
                    type: CustomSnackBarType.success,
                  );
                }
              },
            ),
            SignalListenerItem.of(
              signal: node.isInitialSetupDone,
              listener: (previous, next) {
                if (!next) {
                  _checkInitialSetup(context, node, next, node.balance.value);
                }
              },
            ),
          ],
          child: SignalBuilderMany<ReadableMovementsNode>(
            signals: {
              node.movements,
              node.balance,
              node.isInitialSetupDone,
              node.selectedMonth,
              node.isLoading,
              node.fullScreenLoading,
            },
            builder: (context, readable) {
              if (!readable.isInitialSetupDone) {
                _checkInitialSetup(context, node, false, readable.balance);
              }

              final selMonth = readable.selectedMonth;

              // Calculate income & expenses for selected month dynamically across all programs
              final daysInMonth =
                  DateTime(selMonth.year, selMonth.month + 1, 0).day;
              double monthIncome = 0.0;
              double monthExpenses = 0.0;
              for (int d = 1; d <= daysInMonth; d++) {
                final dayDate = DateTime(selMonth.year, selMonth.month, d);
                for (final p in readable.movements) {
                  if (p.matchesDate(dayDate)) {
                    if (p.isIncome) {
                      monthIncome += p.amount;
                    } else {
                      monthExpenses += p.amount;
                    }
                  }
                }
              }

              // Calculate projected balance up to the end of selected month
              final now = DateTime.now();
              final currentMonth = DateTime(now.year, now.month);
              final targetMonth = DateTime(selMonth.year, selMonth.month);

              // Solo los movimientos PENDIENTES (sin liquidar) que afectan balance deben sumarse al saldo Real,
              // ya que lo liquidado ya se encuentra reflejado en el saldo Real.
              double calculatePendingNetForMonth(DateTime m) {
                final totalDays = DateTime(m.year, m.month + 1, 0).day;
                double pendingInc = 0.0;
                double pendingExp = 0.0;
                for (int d = 1; d <= totalDays; d++) {
                  final dayDate = DateTime(m.year, m.month, d);
                  for (final p in readable.movements) {
                    if (p.matchesDate(dayDate) && p.affectsMainBalance) {
                      final occ = p.occurrenceForDate(dayDate);
                      if (!occ.isLiquidated) {
                        if (occ.isIncome) {
                          pendingInc += occ.amount;
                        } else {
                          pendingExp += occ.amount;
                        }
                      }
                    }
                  }
                }
                return pendingInc - pendingExp;
              }

              double projectedBalance = readable.balance;

              if (targetMonth.isAtSameMomentAs(currentMonth)) {
                // Mes actual: Saldo Real + movimientos pendientes por liquidar de este mes
                projectedBalance += calculatePendingNetForMonth(currentMonth);
              } else if (targetMonth.isAfter(currentMonth)) {
                // Meses futuros: Saldo Real + pendientes del mes actual y de cada mes hasta el seleccionado
                DateTime iter = currentMonth;
                while (!iter.isAfter(targetMonth)) {
                  projectedBalance += calculatePendingNetForMonth(iter);
                  iter = DateTime(iter.year, iter.month + 1);
                }
              } else {
                // Meses pasados: Saldo Real menos los movimientos liquidados que ocurrieron después de ese mes
                double pastDiff = 0.0;
                DateTime iter = DateTime(targetMonth.year, targetMonth.month + 1);
                while (!iter.isAfter(currentMonth)) {
                  final totalDays = DateTime(iter.year, iter.month + 1, 0).day;
                  for (int d = 1; d <= totalDays; d++) {
                    final dayDate = DateTime(iter.year, iter.month, d);
                    for (final p in readable.movements) {
                      if (p.matchesDate(dayDate) && p.affectsMainBalance) {
                        final occ = p.occurrenceForDate(dayDate);
                        if (occ.isLiquidated) {
                          pastDiff += occ.isIncome ? occ.amount : -occ.amount;
                        }
                      }
                    }
                  }
                  iter = DateTime(iter.year, iter.month + 1);
                }
                projectedBalance -= pastDiff;
              }

              final monthName = DateFormat('MMMM yyyy', 'es_MX').format(selMonth);
              final capitalizedMonth = monthName.isNotEmpty
                  ? '${monthName[0].toUpperCase()}${monthName.substring(1)}'
                  : '';

              return CustomScaffold(
                title: 'Dollar bills',
                showBackButton: false,
                fullScreenLoading: readable.fullScreenLoading,
                isLoading: readable.isLoading,
                onRefresh: node.fetchData,
                floatingActionButton: FloatingActionButton.extended(
                  heroTag: 'fab_all_movements',
                  onPressed: () async {
                    final res = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddMovementPage(),
                      ),
                    );
                    if (res == true) {
                      await node.fetchData();
                    }
                  },
                  backgroundColor: HexColor.mintPrimary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Programar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                body: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, textValue, _) {
                    final query = textValue.text.trim().toLowerCase();

                    // Filter centralized programs
                    final filteredPrograms = readable.movements.where((m) {
                      final matchesQuery =
                          query.isEmpty ||
                          m.title.toLowerCase().contains(query) ||
                          (m.accountName ?? '').toLowerCase().contains(query) ||
                          (m.description ?? '').toLowerCase().contains(query);

                      return matchesQuery;
                    }).toList();

                    final startDate = DateTime(
                      readable.selectedMonth.year,
                      readable.selectedMonth.month,
                      1,
                    );

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Top Projected Balance Header matching screenshot
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Balance al mes de $capitalizedMonth',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: HexColor.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: HexColor.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _openEditBalanceDialog(
                                        context,
                                        node,
                                        readable.balance,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: HexColor.mintLight,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.account_balance_wallet_outlined,
                                              size: 13,
                                              color: HexColor.mintPrimaryDark,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Real: ${currency.format(readable.balance)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    HexColor.mintPrimaryDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  '${projectedBalance >= 0 ? '+' : ''}${currency.format(projectedBalance)}',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: projectedBalance >= 0
                                        ? HexColor.textPrimary
                                        : HexColor.expenseRed,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Horizontal Month Selector Strip
                        SliverToBoxAdapter(
                          child: MonthSelectorStrip(
                            selectedMonth: readable.selectedMonth,
                            onMonthSelected: (newMonth) {
                              node.setSelectedMonth(newMonth);
                            },
                          ),
                        ),

                        // Dual Summary Cards: + Ingresos / - Gastos
                        SliverToBoxAdapter(
                          child: MonthSummaryCards(
                            income: monthIncome,
                            expenses: monthExpenses,
                          ),
                        ),

                        // Search and Filter Bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Buscar movimiento o cuenta...',
                                      hintStyle: TextStyle(
                                        color: HexColor.textMuted,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: HexColor.mintPrimary,
                                      ),
                                      suffixIcon:
                                          _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _searchController.clear(),
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
                                const Gap(8),
                                // Filter chips
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ChoiceChip(
                                        label: Text(
                                          'Todos (${readable.movements.length})',
                                        ),
                                        selected: _statusFilter == 0,
                                        selectedColor: HexColor.mintPrimary,
                                        labelStyle: TextStyle(
                                          color: _statusFilter == 0
                                              ? Colors.white
                                              : HexColor.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        onSelected: (_) =>
                                            setState(() => _statusFilter = 0),
                                      ),
                                      const Gap(8),
                                      ChoiceChip(
                                        label: const Text('Sin Liquidar'),
                                        selected: _statusFilter == 1,
                                        selectedColor: HexColor.mintPrimary,
                                        labelStyle: TextStyle(
                                          color: _statusFilter == 1
                                              ? Colors.white
                                              : HexColor.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        onSelected: (_) =>
                                            setState(() => _statusFilter = 1),
                                      ),
                                      const Gap(8),
                                      ChoiceChip(
                                        label: const Text('Liquidados'),
                                        selected: _statusFilter == 2,
                                        selectedColor: HexColor.mintPrimary,
                                        labelStyle: TextStyle(
                                          color: _statusFilter == 2
                                              ? Colors.white
                                              : HexColor.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        onSelected: (_) =>
                                            setState(() => _statusFilter = 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Movements Calendar List or Empty State
                        if (filteredPrograms.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      size: 56,
                                      color: HexColor.textMuted.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    const Gap(12),
                                    Text(
                                      query.isNotEmpty
                                          ? 'No se encontraron resultados para "$query"'
                                          : 'No tienes movimientos registrados',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: HexColor.textSecondary,
                                      ),
                                    ),
                                    const Gap(6),
                                    Text(
                                      'Programa tu primera entrada o salida con el botón "+ Programar"',
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
                            key: ValueKey(
                              'infinite_calendar_${readable.selectedMonth.year}_${readable.selectedMonth.month}',
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final date = DateTime(
                                  startDate.year,
                                  startDate.month,
                                  startDate.day + index,
                                );

                                final isMonthChange = date.day == 1;

                                // Evaluar qué programaciones centralizadas corresponden a esta fecha
                                final dayMovements = <MovementModel>[];
                                for (final p in filteredPrograms) {
                                  if (p.matchesDate(date)) {
                                    final occ = p.occurrenceForDate(date);
                                    if (_statusFilter == 1 && occ.isLiquidated) continue;
                                    if (_statusFilter == 2 && !occ.isLiquidated) continue;
                                    dayMovements.add(occ);
                                  }
                                }

                                final hasMovements = dayMovements.isNotEmpty;

                                // No tiene un pago programado ni cambio de mes? No mostrar nada
                                if (!hasMovements && !isMonthChange) {
                                  return const SizedBox.shrink();
                                }

                                double dayNet = 0.0;
                                for (final m in dayMovements) {
                                  dayNet += m.isIncome ? m.amount : -m.amount;
                                }

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Cambia de mes? Colocar una etiqueta que diga el mes que sigue
                                    if (isMonthChange)
                                      _buildMonthChangeLabel(date),

                                    // Tiene un pago programado? Mostrar el pago
                                    if (hasMovements) ...[
                                      DayGroupHeader(
                                        date: date,
                                        netAmount: dayNet,
                                      ),
                                      for (final m in dayMovements)
                                        MovementCard(
                                          movement: m,
                                          onToggleLiquidation: () =>
                                              node.toggleLiquidation(m, date),
                                          onEdit: () =>
                                              _editMovement(context, node, m, date),
                                          onDelete: () =>
                                              _confirmDelete(context, node, m, date),
                                        ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        const SliverToBoxAdapter(child: Gap(80)),
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
