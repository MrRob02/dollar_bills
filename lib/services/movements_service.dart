import 'package:dollar_bills/core/local/data_persistence_service.dart';
import 'package:dollar_bills/models/movement_model.dart';
import 'package:dollar_bills/services/accounts_service.dart';
import 'package:dollar_bills/services/balance_service.dart';

class MovementsService {
  final BalanceService _balanceService = BalanceService();
  final AccountsService _accountsService = AccountsService();

  Future<List<MovementModel>> getAllMovements() async {
    final box = DataPersistenceService.movementsBox;
    final List<MovementModel> rawList = [];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        rawList.add(MovementModel.fromMap(Map<dynamic, dynamic>.from(raw)));
      }
    }

    // Auto-consolidate any legacy repeating groups into centralized programs
    final Map<String, List<MovementModel>> groups = {};
    final List<MovementModel> singleList = [];

    for (final m in rawList) {
      if (m.recurringGroupId != null && m.recurringGroupId!.isNotEmpty) {
        groups.putIfAbsent(m.recurringGroupId!, () => []).add(m);
      } else {
        singleList.add(m);
      }
    }

    // Consolidate legacy groups
    for (final entry in groups.entries) {
      final groupMovements = entry.value;
      if (groupMovements.isEmpty) continue;

      // Find earliest scheduledDate
      groupMovements.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      final first = groupMovements.first;

      final Map<String, String> consolidatedLiqDates = Map.from(first.liquidatedDates);
      for (final gm in groupMovements) {
        if (gm.liquidationDate != null) {
          final k =
              '${gm.scheduledDate.year}-${gm.scheduledDate.month}-${gm.scheduledDate.day}';
          consolidatedLiqDates[k] = gm.liquidationDate!.toIso8601String();
        }
      }

      // Create single centralized master program without artificial limits
      final consolidated = first.copyWith(
        id: 'prog_${entry.key}',
        endDate: first.totalRepetitions != null ? first.endDate : null,
        totalRepetitions: first.totalRepetitions,
        liquidatedDates: consolidatedLiqDates,
      );

      // Clean up legacy keys and save consolidated model
      for (final gm in groupMovements) {
        await box.delete(gm.id);
      }
      await box.put(consolidated.id, consolidated.toMap());
      singleList.add(consolidated);
    }

    // Sort by scheduledDate ascending
    singleList.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return singleList;
  }

  Future<List<MovementModel>> getLiquidatedMovements() async {
    final all = await getAllMovements();
    final List<MovementModel> liquidated = [];

    for (final m in all) {
      if (m.isRecurring) {
        for (final entry in m.liquidatedDates.entries) {
          final parts = entry.key.split('-');
          if (parts.length == 3) {
            final date = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            liquidated.add(m.occurrenceForDate(date));
          }
        }
      } else if (m.isLiquidated) {
        liquidated.add(m);
      }
    }

    // Sort strictly by liquidationDate descending (most recent first)
    liquidated.sort((a, b) {
      final dateA = a.liquidationDate ?? a.scheduledDate;
      final dateB = b.liquidationDate ?? b.scheduledDate;
      return dateB.compareTo(dateA);
    });
    return liquidated;
  }

  Future<void> scheduleMovement({
    required String title,
    String? description,
    required double amount,
    required MovementType type,
    required int iconCodePoint,
    required String colorHex,
    required DateTime scheduledDate,
    String? accountId,
    String? accountName,
    bool isPaid = false,
    bool affectsBalance = true,
    DateTime? liquidationDate,
    RecurrenceType recurrenceType = RecurrenceType.none,
    bool isLastDayOfMonth = false,
    DateTime? endDate,
    int? maxRepetitions,
  }) async {
    final box = DataPersistenceService.movementsBox;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final resolvedLiquidationDate = isPaid
        ? (liquidationDate ?? scheduledDate)
        : null;

    final Map<String, String> initialLiquidations = {};
    if (isPaid && resolvedLiquidationDate != null) {
      final dateKey =
          '${scheduledDate.year}-${scheduledDate.month}-${scheduledDate.day}';
      initialLiquidations[dateKey] = resolvedLiquidationDate.toIso8601String();
    }

    // Programación centralizada guardada exactamente una vez
    final model = MovementModel(
      id: recurrenceType == RecurrenceType.none
          ? 'mov_$timestamp'
          : 'prog_$timestamp',
      title: title,
      description: description,
      amount: amount,
      type: type,
      iconCodePoint: iconCodePoint,
      colorHex: colorHex,
      accountId: accountId,
      accountName: accountName,
      scheduledDate: scheduledDate,
      liquidationDate: resolvedLiquidationDate,
      affectsBalance: affectsBalance,
      recurrenceType: recurrenceType,
      isLastDayOfMonth: isLastDayOfMonth,
      endDate: endDate,
      totalRepetitions: maxRepetitions,
      liquidatedDates: initialLiquidations,
    );

    await box.put(model.id, model.toMap());

    if (isPaid) {
      if (affectsBalance) {
        await _balanceService.applyMovement(model);
      }
      final hasAccount = (accountId != null && accountId != 'main') ||
          (accountName != null && accountName.trim().isNotEmpty);
      if (hasAccount) {
        await _accountsService.adjustAccountForMovement(
          accountId: accountId,
          accountName: accountName,
          type: model.type,
          amount: model.amount,
          isRevert: false,
        );
      }
    }
  }

  MovementModel? _findProgram(String id) {
    final box = DataPersistenceService.movementsBox;
    // 1. Direct key match
    var raw = box.get(id);
    if (raw != null) {
      return MovementModel.fromMap(Map<dynamic, dynamic>.from(raw));
    }

    // 2. Strip occurrence date suffix (e.g. 'prog_123_2026-9-6' -> 'prog_123')
    final baseId = id.replaceFirst(RegExp(r'_\d{4}-\d+-\d+$'), '');
    raw = box.get(baseId);
    if (raw != null) {
      return MovementModel.fromMap(Map<dynamic, dynamic>.from(raw));
    }

    // 3. Search all in box
    for (final key in box.keys) {
      final itemRaw = box.get(key);
      if (itemRaw != null) {
        final m = MovementModel.fromMap(Map<dynamic, dynamic>.from(itemRaw));
        if (m.id == id || m.id == baseId) {
          return m;
        }
      }
    }
    return null;
  }

  Future<void> toggleLiquidation(String id, [DateTime? date]) async {
    final box = DataPersistenceService.movementsBox;
    final program = _findProgram(id);
    if (program == null) {
      throw 'Programación no encontrada';
    }

    final targetDate = date ?? program.scheduledDate;
    final dateKey = '${targetDate.year}-${targetDate.month}-${targetDate.day}';

    if (program.isRecurring) {
      final Map<String, String> updatedLiq =
          Map<String, String>.from(program.liquidatedDates);
      final isAlreadyLiquidated = updatedLiq.containsKey(dateKey);

      final occurrence = program.occurrenceForDate(targetDate);

      final hasAccount = (program.accountId != null && program.accountId != 'main') ||
          (program.accountName != null && program.accountName!.trim().isNotEmpty);

      if (isAlreadyLiquidated) {
        // Unliquidate this occurrence
        updatedLiq.remove(dateKey);
        if (program.affectsBalance) {
          await _balanceService.revertMovement(occurrence);
        }
        if (hasAccount) {
          await _accountsService.adjustAccountForMovement(
            accountId: program.accountId,
            accountName: program.accountName,
            type: occurrence.type,
            amount: occurrence.amount,
            isRevert: true,
          );
        }
      } else {
        // Liquidate this occurrence
        final liqDate = DateTime.now();
        updatedLiq[dateKey] = liqDate.toIso8601String();
        if (program.affectsBalance) {
          await _balanceService.applyMovement(
            occurrence.copyWith(liquidationDate: liqDate),
          );
        }
        if (hasAccount) {
          await _accountsService.adjustAccountForMovement(
            accountId: program.accountId,
            accountName: program.accountName,
            type: occurrence.type,
            amount: occurrence.amount,
            isRevert: false,
          );
        }
      }

      final updatedProgram = program.copyWith(liquidatedDates: updatedLiq);
      await box.put(program.id, updatedProgram.toMap());
    } else {
      // One-time movement
      if (program.isLiquidated) {
        await unliquidateMovement(program.id);
      } else {
        await liquidateMovement(program.id, DateTime.now());
      }
    }
  }

  Future<void> liquidateMovement(String id, DateTime liquidationDate) async {
    final box = DataPersistenceService.movementsBox;
    final program = _findProgram(id);
    if (program == null) {
      throw 'Movimiento no encontrado';
    }

    if (program.isRecurring) {
      await toggleLiquidation(id, liquidationDate);
      return;
    }

    if (program.isLiquidated) return;

    final updated = program.copyWith(
      liquidationDate: liquidationDate,
      affectsBalance: true,
    );
    await box.put(program.id, updated.toMap());

    await _balanceService.applyMovement(updated);
    final hasAccount = (updated.accountId != null && updated.accountId != 'main') ||
        (updated.accountName != null && updated.accountName!.trim().isNotEmpty);
    if (hasAccount) {
      await _accountsService.adjustAccountForMovement(
        accountId: updated.accountId,
        accountName: updated.accountName,
        type: updated.type,
        amount: updated.amount,
        isRevert: false,
      );
    }
  }

  Future<void> unliquidateMovement(String id, [DateTime? date]) async {
    final box = DataPersistenceService.movementsBox;
    final program = _findProgram(id);
    if (program == null) {
      throw 'Movimiento no encontrado';
    }

    if (program.isRecurring && date != null) {
      await toggleLiquidation(id, date);
      return;
    }

    if (!program.isLiquidated) return;

    if (program.affectsBalance) {
      await _balanceService.revertMovement(program);
    }

    final hasAccount = (program.accountId != null && program.accountId != 'main') ||
        (program.accountName != null && program.accountName!.trim().isNotEmpty);
    if (hasAccount) {
      await _accountsService.adjustAccountForMovement(
        accountId: program.accountId,
        accountName: program.accountName,
        type: program.type,
        amount: program.amount,
        isRevert: true,
      );
    }

    final updated = program.copyWith(clearLiquidationDate: true);
    await box.put(program.id, updated.toMap());
  }

  Future<void> deleteMovement(
    String id, {
    DateTime? date,
    RecurringScope scope = RecurringScope.all,
  }) async {
    final box = DataPersistenceService.movementsBox;
    final program = _findProgram(id);
    if (program == null) return;

    if (!program.isRecurring || date == null || scope == RecurringScope.all) {
      // Delete entire movement or entire recurring program
      if (program.isRecurring) {
        for (final entry in program.liquidatedDates.entries) {
          final parts = entry.key.split('-');
          if (parts.length == 3) {
            final occDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
            final occ = program.occurrenceForDate(occDate);
            if (program.affectsBalance) {
              await _balanceService.revertMovement(occ);
            }
            final hasAccount = (program.accountId != null && program.accountId != 'main') ||
                (program.accountName != null && program.accountName!.trim().isNotEmpty);
            if (hasAccount) {
              await _accountsService.adjustAccountForMovement(
                accountId: program.accountId,
                accountName: program.accountName,
                type: occ.type,
                amount: occ.amount,
                isRevert: true,
              );
            }
          }
        }
      } else {
        if (program.isLiquidated) {
          await unliquidateMovement(program.id);
        }
      }
      await box.delete(program.id);
      return;
    }

    final targetDate = DateTime(date.year, date.month, date.day);
    final dateKey = '${targetDate.year}-${targetDate.month}-${targetDate.day}';

    if (scope == RecurringScope.onlyThis) {
      // Skip only this occurrence
      final updatedSkipped = List<String>.from(program.skippedDates)
        ..add(dateKey);

      Map<String, String> updatedLiq = Map<String, String>.from(program.liquidatedDates);
      if (updatedLiq.containsKey(dateKey)) {
        final occ = program.occurrenceForDate(targetDate);
        if (program.affectsBalance) {
          await _balanceService.revertMovement(occ);
        }
        final hasAccount = (program.accountId != null && program.accountId != 'main') ||
            (program.accountName != null && program.accountName!.trim().isNotEmpty);
        if (hasAccount) {
          await _accountsService.adjustAccountForMovement(
            accountId: program.accountId,
            accountName: program.accountName,
            type: occ.type,
            amount: occ.amount,
            isRevert: true,
          );
        }
        updatedLiq.remove(dateKey);
      }

      final updated = program.copyWith(
        skippedDates: updatedSkipped,
        liquidatedDates: updatedLiq,
      );
      await box.put(program.id, updated.toMap());
      return;
    }

    if (scope == RecurringScope.thisAndFuture) {
      // If targetDate is on or before scheduledDate, delete whole program
      final programStart = DateTime(
        program.scheduledDate.year,
        program.scheduledDate.month,
        program.scheduledDate.day,
      );
      if (!targetDate.isAfter(programStart)) {
        await deleteMovement(program.id, date: date, scope: RecurringScope.all);
        return;
      }

      // Revert liquidations on or after targetDate
      final updatedLiq = Map<String, String>.from(program.liquidatedDates);
      final List<String> toRemove = [];
      for (final entry in updatedLiq.entries) {
        final parts = entry.key.split('-');
        if (parts.length == 3) {
          final occDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          if (!occDate.isBefore(targetDate)) {
            final occ = program.occurrenceForDate(occDate);
            if (program.affectsBalance) {
              await _balanceService.revertMovement(occ);
            }
            final hasAccount = (program.accountId != null && program.accountId != 'main') ||
                (program.accountName != null && program.accountName!.trim().isNotEmpty);
            if (hasAccount) {
              await _accountsService.adjustAccountForMovement(
                accountId: program.accountId,
                accountName: program.accountName,
                type: occ.type,
                amount: occ.amount,
                isRevert: true,
              );
            }
            toRemove.add(entry.key);
          }
        }
      }
      for (final k in toRemove) {
        updatedLiq.remove(k);
      }

      final newEndDate = targetDate.subtract(const Duration(days: 1));
      final updated = program.copyWith(
        endDate: newEndDate,
        liquidatedDates: updatedLiq,
      );
      await box.put(program.id, updated.toMap());
    }
  }

  Future<void> updateMovement(
    MovementModel updated, {
    DateTime? originalOccurrenceDate,
    RecurringScope scope = RecurringScope.all,
  }) async {
    final box = DataPersistenceService.movementsBox;
    final program = _findProgram(updated.id);

    // If not recurring or program not found or scope is all, update directly
    if (program == null || !program.isRecurring || scope == RecurringScope.all || originalOccurrenceDate == null) {
      if (program != null && program.isRecurring) {
        final merged = program.copyWith(
          title: updated.title,
          description: updated.description,
          amount: updated.amount,
          type: updated.type,
          iconCodePoint: updated.iconCodePoint,
          colorHex: updated.colorHex,
          accountId: updated.accountId,
          accountName: updated.accountName,
          affectsBalance: updated.affectsBalance,
          recurrenceType: updated.recurrenceType != RecurrenceType.none
              ? updated.recurrenceType
              : program.recurrenceType,
          isLastDayOfMonth: updated.isLastDayOfMonth,
          endDate: updated.endDate,
          totalRepetitions: updated.totalRepetitions,
          scheduledDate: updated.scheduledDate,
        );
        await box.put(program.id, merged.toMap());
      } else {
        await box.put(updated.id, updated.toMap());
      }
      return;
    }

    final occDate = DateTime(
      originalOccurrenceDate.year,
      originalOccurrenceDate.month,
      originalOccurrenceDate.day,
    );
    final occDateKey = '${occDate.year}-${occDate.month}-${occDate.day}';

    if (scope == RecurringScope.onlyThis) {
      // 1. Mark original date as skipped in master program
      final updatedSkipped = List<String>.from(program.skippedDates)
        ..add(occDateKey);

      final updatedLiq = Map<String, String>.from(program.liquidatedDates);
      final wasLiquidated = updatedLiq.containsKey(occDateKey);
      final liqDateStr = updatedLiq.remove(occDateKey);

      final updatedProgram = program.copyWith(
        skippedDates: updatedSkipped,
        liquidatedDates: updatedLiq,
      );
      await box.put(program.id, updatedProgram.toMap());

      // 2. Create standalone one-time movement for this occurrence
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final standalone = MovementModel(
        id: 'mov_$timestamp',
        title: updated.title,
        description: updated.description,
        amount: updated.amount,
        type: updated.type,
        iconCodePoint: updated.iconCodePoint,
        colorHex: updated.colorHex,
        scheduledDate: updated.scheduledDate,
        accountId: updated.accountId,
        accountName: updated.accountName,
        affectsBalance: updated.affectsBalance,
        recurrenceType: RecurrenceType.none,
        liquidationDate: wasLiquidated && liqDateStr != null
            ? DateTime.parse(liqDateStr)
            : updated.liquidationDate,
      );
      await box.put(standalone.id, standalone.toMap());
      return;
    }

    if (scope == RecurringScope.thisAndFuture) {
      // 1. Truncate original program up to day before occDate
      final newEndDate = occDate.subtract(const Duration(days: 1));

      final origLiq = Map<String, String>.from(program.liquidatedDates);
      final newLiq = <String, String>{};
      final List<String> toRemove = [];

      for (final entry in origLiq.entries) {
        final parts = entry.key.split('-');
        if (parts.length == 3) {
          final d = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          if (!d.isBefore(occDate)) {
            newLiq[entry.key] = entry.value;
            toRemove.add(entry.key);
          }
        }
      }
      for (final k in toRemove) {
        origLiq.remove(k);
      }

      final truncatedOriginal = program.copyWith(
        endDate: newEndDate,
        liquidatedDates: origLiq,
      );
      await box.put(program.id, truncatedOriginal.toMap());

      // 2. Create new recurring program starting at updated.scheduledDate
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newProgram = MovementModel(
        id: 'prog_$timestamp',
        title: updated.title,
        description: updated.description,
        amount: updated.amount,
        type: updated.type,
        iconCodePoint: updated.iconCodePoint,
        colorHex: updated.colorHex,
        scheduledDate: updated.scheduledDate,
        accountId: updated.accountId,
        accountName: updated.accountName,
        affectsBalance: updated.affectsBalance,
        recurrenceType: updated.recurrenceType != RecurrenceType.none
            ? updated.recurrenceType
            : program.recurrenceType,
        isLastDayOfMonth: updated.isLastDayOfMonth,
        endDate: updated.endDate,
        totalRepetitions: updated.totalRepetitions,
        liquidatedDates: newLiq,
      );
      await box.put(newProgram.id, newProgram.toMap());
    }
  }
}
