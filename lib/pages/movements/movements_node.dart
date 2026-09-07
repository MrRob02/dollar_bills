import 'dart:developer';
import 'package:dollar_bills/models/movement_model.dart';
import 'package:dollar_bills/services/balance_service.dart';
import 'package:dollar_bills/services/movements_service.dart';
import 'package:trinity/trinity.dart';
import 'package:trinity_generator/trinity_generator.dart';

part 'movements_node.readable.dart';

@Readable()
class MovementsNode extends NodeInterface {
  late final movements = registerSignal(ListSignal<MovementModel>([]));
  late final balance = registerSignal(Signal<double>(0.0));
  late final isInitialSetupDone = registerSignal(Signal<bool>(true));
  late final isLiquidatedSuccess = registerSignal(Signal<bool>(false));
  late final isDeletedSuccess = registerSignal(Signal<bool>(false));
  late final isUpdatedSuccess = registerSignal(Signal<bool>(false));
  late final selectedMonth = registerSignal(
    Signal<DateTime>(DateTime(DateTime.now().year, DateTime.now().month)),
  );

  final MovementsService _movementsService = MovementsService();
  final BalanceService _balanceService = BalanceService();

  MovementsNode() {
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      await loading(
        () async {
          final settings = _balanceService.getSettings();
          final list = await _movementsService.getAllMovements();
          balance.value = settings.currentBalance;
          isInitialSetupDone.value = settings.isInitialSetupDone;
          movements.value = list;
        },
        fullScreen: movements.isEmpty,
      );
    } catch (e, st) {
      log('MovementsNode fetchData error: $e\n$st');
    }
  }

  void setSelectedMonth(DateTime month) {
    selectedMonth.value = DateTime(month.year, month.month);
  }

  Future<void> toggleLiquidation(MovementModel movement, [DateTime? date]) async {
    try {
      await loading(() async {
        await _movementsService.toggleLiquidation(
          movement.id,
          date ?? movement.scheduledDate,
        );
        isLiquidatedSuccess.value = true;
        await fetchData();
      });
    } catch (e, st) {
      log('MovementsNode toggleLiquidation error: $e\n$st');
    }
  }

  Future<void> setInitialBalance(double initialBalance) async {
    try {
      await loading(() async {
        final settings = await _balanceService.setInitialBalance(initialBalance);
        balance.value = settings.currentBalance;
        isInitialSetupDone.value = true;
      });
    } catch (e, st) {
      log('MovementsNode setInitialBalance error: $e\n$st');
    }
  }

  Future<void> updateBalance(double newBalance) async {
    try {
      await loading(() async {
        final settings = await _balanceService.updateCurrentBalance(newBalance);
        balance.value = settings.currentBalance;
      });
    } catch (e, st) {
      log('MovementsNode updateBalance error: $e\n$st');
    }
  }

  Future<void> liquidateMovement(String id, DateTime date) async {
    try {
      await loading(() async {
        await _movementsService.liquidateMovement(id, date);
        await fetchData();
        isLiquidatedSuccess.value = true;
      });
    } catch (e, st) {
      log('MovementsNode liquidateMovement error: $e\n$st');
    }
  }

  Future<void> deleteMovement(
    String id, {
    DateTime? date,
    RecurringScope scope = RecurringScope.all,
  }) async {
    try {
      await loading(() async {
        await _movementsService.deleteMovement(id, date: date, scope: scope);
        await fetchData();
        isDeletedSuccess.value = true;
      });
    } catch (e, st) {
      log('MovementsNode deleteMovement error: $e\n$st');
    }
  }

  Future<void> updateMovement(
    MovementModel movement, {
    DateTime? originalOccurrenceDate,
    RecurringScope scope = RecurringScope.all,
  }) async {
    try {
      await loading(() async {
        await _movementsService.updateMovement(
          movement,
          originalOccurrenceDate: originalOccurrenceDate,
          scope: scope,
        );
        await fetchData();
        isUpdatedSuccess.value = true;
      });
    } catch (e, st) {
      log('MovementsNode updateMovement error: $e\n$st');
    }
  }

  /// Calcula los totales de un mes.
  /// Si [onlyAffectsBalance] es true, excluye movimientos con affectsBalance == false
  /// (es decir, movimientos que ya estaban contemplados en el balance inicial).
  MonthTotals calculateMonthTotals(
    DateTime month, {
    bool onlyAffectsBalance = false,
  }) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    double income = 0.0;
    double expenses = 0.0;

    for (int d = 1; d <= daysInMonth; d++) {
      final dayDate = DateTime(month.year, month.month, d);
      for (final p in movements.value) {
        if (p.matchesDate(dayDate)) {
          if (onlyAffectsBalance && !p.affectsMainBalance) {
            continue;
          }
          if (p.isIncome) {
            income += p.amount;
          } else {
            expenses += p.amount;
          }
        }
      }
    }

    return MonthTotals(income: income, expenses: expenses);
  }

  /// Calcula la sumatoria neta de Ingresos/Egresos de los meses anteriores
  /// de ese mismo año (desde Enero hasta month - 1).
  /// Excluye movimientos ya contemplados en el balance inicial.
  double calculatePreviousMonthsBalanceNet(DateTime month) {
    if (month.month <= 1) return 0.0;

    double net = 0.0;
    for (int m = 1; m < month.month; m++) {
      final mDate = DateTime(month.year, m);
      final totals = calculateMonthTotals(mDate, onlyAffectsBalance: true);
      net += totals.net;
    }
    return net;
  }

  /// Calcula la sumatoria neta (Ingresos - Gastos) de movimientos liquidados en un mes específico.
  /// Solo toma en cuenta movimientos que afectan el balance (affectsMainBalance == true).
  double calculateLiquidatedNetForMonth(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    double net = 0.0;

    for (int d = 1; d <= daysInMonth; d++) {
      final dayDate = DateTime(month.year, month.month, d);
      for (final p in movements.value) {
        if (p.matchesDate(dayDate) && p.affectsMainBalance) {
          final occ = p.occurrenceForDate(dayDate);
          if (occ.isLiquidated) {
            if (occ.isIncome) {
              net += occ.amount;
            } else {
              net -= occ.amount;
            }
          }
        }
      }
    }
    return net;
  }

  /// Calcula la sumatoria neta de movimientos liquidados desde enero hasta el mes especificado
  /// (inclusive) de ese mismo año.
  /// Solo toma en cuenta movimientos que afectan el balance (affectsMainBalance == true).
  double calculateLiquidatedNetUpToMonth(DateTime month) {
    double total = 0.0;
    for (int m = 1; m <= month.month; m++) {
      total += calculateLiquidatedNetForMonth(DateTime(month.year, m));
    }
    return total;
  }

  /// Calcula el balance al mes:
  /// Saldo Real + Sumatoria Ingreso/Egreso de ese mes + Sumatoria Ingreso/Egreso de los meses anteriores de ese mismo año
  /// menos los movimientos liquidados del mes actual y de todos los anteriores (para no duplicar con el saldo real).
  /// No incluye saldo contemplado en la sumatoria de ingresos/egresos del balance.
  double calculateMonthlyBalance({
    required double realBalance,
    required DateTime targetMonth,
  }) {
    final currentMonthNet = calculateMonthTotals(
      targetMonth,
      onlyAffectsBalance: true,
    ).net;
    final previousMonthsNet = calculatePreviousMonthsBalanceNet(targetMonth);
    final liquidatedNet = calculateLiquidatedNetUpToMonth(targetMonth);

    return realBalance + currentMonthNet + previousMonthsNet - liquidatedNet;
  }

  @override
  ReadableMovementsNode get readable => ReadableMovementsNode(this);
}

class MonthTotals {
  final double income;
  final double expenses;
  double get net => income - expenses;

  const MonthTotals({this.income = 0.0, this.expenses = 0.0});
}
