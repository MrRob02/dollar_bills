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

  @override
  ReadableMovementsNode get readable => ReadableMovementsNode(this);
}
