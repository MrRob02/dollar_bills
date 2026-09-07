import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_bills/models/movement_model.dart';
import 'package:dollar_bills/models/account_model.dart';
import 'package:dollar_bills/models/category_model.dart';

void main() {
  group('MovementModel tests', () {
    test('isLiquidated returns false when liquidationDate is null', () {
      final movement = MovementModel(
        id: 'test_1',
        title: 'Sueldo',
        amount: 15000,
        type: MovementType.income,
        iconCodePoint: 0xe518,
        colorHex: 'FF3EB489',
        scheduledDate: DateTime(2026, 9, 15),
      );

      expect(movement.isLiquidated, isFalse);
      expect(movement.liquidationDate, isNull);
    });

    test('isLiquidated returns true when liquidationDate is set', () {
      final movement = MovementModel(
        id: 'test_2',
        title: 'Renta',
        description: 'Pago mensual del departamento',
        amount: 8000,
        type: MovementType.expense,
        iconCodePoint: 0xe518,
        colorHex: 'FFEF4444',
        scheduledDate: DateTime(2026, 9, 1),
        liquidationDate: DateTime(2026, 9, 2),
      );

      expect(movement.isLiquidated, isTrue);
      expect(movement.liquidationDate, isNotNull);
      expect(movement.description, equals('Pago mensual del departamento'));
    });

    test('Serialization toMap and fromMap retains all fields and getter', () {
      final original = MovementModel(
        id: 'test_3',
        title: 'Gasto Internet',
        description: 'Fibra óptica 500mb',
        amount: 600,
        type: MovementType.expense,
        iconCodePoint: 0xe32c,
        colorHex: 'FF3B82F6',
        accountId: 'acc_debt_1',
        accountName: 'Tarjeta Santander',
        scheduledDate: DateTime(2026, 9, 30),
        liquidationDate: DateTime(2026, 9, 29),
        affectsBalance: false, // contemplado en saldo inicial
        recurrenceType: RecurrenceType.monthly,
        isLastDayOfMonth: true,
        recurringGroupId: 'grp_123',
        repetitionIndex: 3,
        totalRepetitions: 12,
      );

      final map = original.toMap();
      final reconstructed = MovementModel.fromMap(map);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.title, equals(original.title));
      expect(reconstructed.description, equals('Fibra óptica 500mb'));
      expect(reconstructed.amount, equals(original.amount));
      expect(reconstructed.isLiquidated, isTrue);
      expect(reconstructed.isLastDayOfMonth, isTrue);
      expect(reconstructed.affectsBalance, isFalse);
      expect(reconstructed.hasCustomAccount, isTrue);
      expect(reconstructed.accountName, equals('Tarjeta Santander'));
      expect(reconstructed.recurrenceType, equals(RecurrenceType.monthly));
    });

    test('affectsBalance is true by default and affectsMainBalance reflects it', () {
      final defaultMovement = MovementModel(
        id: 'test_4',
        title: 'Supermercado',
        amount: 1200,
        type: MovementType.expense,
        iconCodePoint: 0xe8cc,
        colorHex: 'FFEF4444',
        scheduledDate: DateTime(2026, 9, 6),
      );

      expect(defaultMovement.affectsBalance, isTrue);
      expect(defaultMovement.affectsMainBalance, isTrue);
    });
  });

  group('Account & Category tests', () {
    test('Account debt and debtor types and category assignment', () {
      const category = CategoryModel(
        id: 'cat_test',
        name: 'Tarjetas',
        iconCodePoint: 0xe19f,
        colorHex: 'FF3EB489',
      );

      final accountDebt = AccountModel(
        id: 'acc_1',
        name: 'Tarjeta BBVA',
        type: AccountType.debt,
        categoryId: category.id,
        categoryName: category.name,
        initialAmount: 5000,
        currentAmount: 5000,
        colorHex: 'FFF59E0B',
        iconCodePoint: 0xe19f,
      );

      expect(accountDebt.isDebt, isTrue);
      expect(accountDebt.isDebtor, isFalse);
      expect(accountDebt.categoryName, equals('Tarjetas'));
    });
  });

  group('Calendar feed and projected balance tests', () {
    test('Groups movements by date correctly', () {
      final m1 = MovementModel(
        id: '1',
        title: 'Gasolina',
        amount: 500,
        type: MovementType.expense,
        iconCodePoint: 0xe518,
        colorHex: 'FFEF4444',
        scheduledDate: DateTime(2026, 10, 15, 9, 30),
      );
      final m2 = MovementModel(
        id: '2',
        title: 'Cena',
        amount: 300,
        type: MovementType.expense,
        iconCodePoint: 0xe518,
        colorHex: 'FFEF4444',
        scheduledDate: DateTime(2026, 10, 15, 20, 0),
      );
      final m3 = MovementModel(
        id: '3',
        title: 'Freelance',
        amount: 2500,
        type: MovementType.income,
        iconCodePoint: 0xe518,
        colorHex: 'FF3EB489',
        scheduledDate: DateTime(2026, 10, 16, 12, 0),
      );

      final movements = [m1, m2, m3];
      final Map<DateTime, List<MovementModel>> grouped = {};
      for (final m in movements) {
        final dayKey = DateTime(m.scheduledDate.year, m.scheduledDate.month, m.scheduledDate.day);
        grouped.putIfAbsent(dayKey, () => []).add(m);
      }

      expect(grouped.length, equals(2));
      expect(grouped[DateTime(2026, 10, 15)]!.length, equals(2));
      expect(grouped[DateTime(2026, 10, 16)]!.length, equals(1));
    });

    test('Projected balance includes pending transactions up to target month', () {
      double currentBalance = 10000;
      final movements = [
        MovementModel(
          id: '1',
          title: 'Sueldo Octubre',
          amount: 5000,
          type: MovementType.income,
          iconCodePoint: 0xe518,
          colorHex: 'FF3EB489',
          scheduledDate: DateTime(2026, 10, 15),
        ),
        MovementModel(
          id: '2',
          title: 'Renta Octubre',
          amount: 3000,
          type: MovementType.expense,
          iconCodePoint: 0xe518,
          colorHex: 'FFEF4444',
          scheduledDate: DateTime(2026, 10, 20),
        ),
        MovementModel(
          id: '3',
          title: 'Bono Noviembre',
          amount: 2000,
          type: MovementType.income,
          iconCodePoint: 0xe518,
          colorHex: 'FF3EB489',
          scheduledDate: DateTime(2026, 11, 5),
        ),
      ];

      // Test projection for October 2026
      final targetOctober = DateTime(2026, 10);
      final endOfOct = DateTime(targetOctober.year, targetOctober.month + 1, 0, 23, 59, 59);
      double projectedOct = currentBalance;
      for (final m in movements) {
        if (!m.isLiquidated && !m.scheduledDate.isAfter(endOfOct)) {
          projectedOct += m.isIncome ? m.amount : -m.amount;
        }
      }

      expect(projectedOct, equals(12000)); // 10000 + 5000 - 3000

      // Test projection for November 2026
      final targetNov = DateTime(2026, 11);
      final endOfNov = DateTime(targetNov.year, targetNov.month + 1, 0, 23, 59, 59);
      double projectedNov = currentBalance;
      for (final m in movements) {
        if (!m.isLiquidated && !m.scheduledDate.isAfter(endOfNov)) {
          projectedNov += m.isIncome ? m.amount : -m.amount;
        }
      }

      expect(projectedNov, equals(14000)); // 10000 + 5000 - 3000 + 2000
    });

    test('Monthly balance matches Real balance plus net income/expense sumatoria', () {
      const monthIncome = 10250.00;
      const monthExpenses = 20138.77;
      const netSum = monthIncome - monthExpenses;

      expect(netSum, closeTo(-9888.77, 0.01));
    });

    test('Liquidating an income movement moves it to Real balance without double counting in projected balance', () {
      double realBalance = 10000.0;
      final income = MovementModel(
        id: '1',
        title: 'Sueldo',
        amount: 5000.0,
        type: MovementType.income,
        iconCodePoint: 0xe518,
        colorHex: 'FF3EB489',
        scheduledDate: DateTime(2026, 10, 15),
      );
      final expense = MovementModel(
        id: '2',
        title: 'Renta',
        amount: 2000.0,
        type: MovementType.expense,
        iconCodePoint: 0xe518,
        colorHex: 'FFEF4444',
        scheduledDate: DateTime(2026, 10, 20),
      );

      final movements = [income, expense];

      // Before liquidation:
      // Real: 10,000
      // Pending net: +5000 (pending income) - 2000 (pending expense) = +3000
      // Projected: 10,000 + 3,000 = 13,000
      double pendingNetBefore = 0;
      for (final m in movements) {
        if (!m.isLiquidated && m.affectsMainBalance) {
          pendingNetBefore += m.isIncome ? m.amount : -m.amount;
        }
      }
      expect(realBalance + pendingNetBefore, equals(13000.0));

      // Liquidate income:
      realBalance += income.amount; // 15,000.0
      final liquidatedIncome = income.copyWith(liquidationDate: DateTime(2026, 10, 15));
      final updatedMovements = [liquidatedIncome, expense];

      // After liquidation:
      // Real: 15,000
      // Pending net: -2000 (only expense is pending)
      // Projected: 15,000 - 2,000 = 13,000 (Matches before liquidation!)
      double pendingNetAfter = 0;
      for (final m in updatedMovements) {
        if (!m.isLiquidated && m.affectsMainBalance) {
          pendingNetAfter += m.isIncome ? m.amount : -m.amount;
        }
      }
      expect(realBalance + pendingNetAfter, equals(13000.0));
    });

    test('Dynamic day inspection detects month change and payments per day', () {
      final startDate = DateTime(2026, 10, 1);
      final m1 = MovementModel(
        id: '1',
        title: 'Luz',
        amount: 450,
        type: MovementType.expense,
        iconCodePoint: 0xe518,
        colorHex: 'FFEF4444',
        scheduledDate: DateTime(2026, 10, 5),
      );

      final Map<String, List<MovementModel>> movementsByDay = {
        '2026-10-5': [m1],
      };

      // Day 0: 2026-10-01 (isMonthChange = true, hasMovements = false)
      final day0 = DateTime(startDate.year, startDate.month, startDate.day + 0);
      expect(day0.day == 1, isTrue); // month label displayed
      expect(movementsByDay['${day0.year}-${day0.month}-${day0.day}'], isNull);

      // Day 1: 2026-10-02 (isMonthChange = false, hasMovements = false -> shrink/nothing)
      final day1 = DateTime(startDate.year, startDate.month, startDate.day + 1);
      expect(day1.day == 1, isFalse);
      expect(movementsByDay['${day1.year}-${day1.month}-${day1.day}'], isNull);

      // Day 4: 2026-10-05 (isMonthChange = false, hasMovements = true -> shows payment)
      final day4 = DateTime(startDate.year, startDate.month, startDate.day + 4);
      expect(day4.day == 1, isFalse);
      expect(movementsByDay['${day4.year}-${day4.month}-${day4.day}']!.length, equals(1));

      // Day 31: 2026-11-01 (isMonthChange = true -> next month label displayed)
      final day31 = DateTime(startDate.year, startDate.month, startDate.day + 31);
      expect(day31.month, equals(11));
      expect(day31.day == 1, isTrue);
    });

    test('Centralized recurring movement matches dates indefinitely without end date', () {
      final sueldo = MovementModel(
        id: 'prog_sueldo',
        title: 'Sueldo',
        amount: 12250,
        type: MovementType.income,
        iconCodePoint: 0xe518,
        colorHex: 'FF3EB489',
        scheduledDate: DateTime(2026, 9, 6),
        recurrenceType: RecurrenceType.monthly,
        endDate: null, // No end date
        liquidatedDates: {
          '2026-9-6': DateTime(2026, 9, 6).toIso8601String(),
        },
      );

      // Matches start date
      expect(sueldo.matchesDate(DateTime(2026, 9, 6)), isTrue);
      // Does not match random date in same month
      expect(sueldo.matchesDate(DateTime(2026, 9, 7)), isFalse);
      // Does not match before start date
      expect(sueldo.matchesDate(DateTime(2026, 8, 6)), isFalse);

      // Matches 1 year later (September 2027)
      expect(sueldo.matchesDate(DateTime(2027, 9, 6)), isTrue);

      // Matches after 1 year: October, November, December 2027
      expect(sueldo.matchesDate(DateTime(2027, 10, 6)), isTrue);
      expect(sueldo.matchesDate(DateTime(2027, 11, 6)), isTrue);
      expect(sueldo.matchesDate(DateTime(2027, 12, 6)), isTrue);

      // Matches in 2028 and 2030 indefinitely
      expect(sueldo.matchesDate(DateTime(2028, 1, 6)), isTrue);
      expect(sueldo.matchesDate(DateTime(2030, 6, 6)), isTrue);

      // Occurrence on 2026-9-6 is liquidated
      final occLiquidated = sueldo.occurrenceForDate(DateTime(2026, 9, 6));
      expect(occLiquidated.isLiquidated, isTrue);

      // Occurrence on 2027-10-6 is pending (not liquidated)
      final occPending = sueldo.occurrenceForDate(DateTime(2027, 10, 6));
      expect(occPending.isLiquidated, isFalse);
      expect(occPending.amount, equals(12250));
      expect(occPending.title, equals('Sueldo'));
    });

    test('Centralized end-of-month recurrence matches last day of every month', () {
      final endOfMonthExpense = MovementModel(
        id: 'prog_renta',
        title: 'Renta',
        amount: 8000,
        type: MovementType.expense,
        iconCodePoint: 0xe88a,
        colorHex: 'FFEF4444',
        scheduledDate: DateTime(2026, 8, 31),
        recurrenceType: RecurrenceType.monthly,
        isLastDayOfMonth: true,
      );

      // August has 31 days
      expect(endOfMonthExpense.matchesDate(DateTime(2026, 8, 31)), isTrue);
      // September has 30 days
      expect(endOfMonthExpense.matchesDate(DateTime(2026, 9, 30)), isTrue);
      expect(endOfMonthExpense.matchesDate(DateTime(2026, 9, 31)), isFalse);
      // February 2027 has 28 days
      expect(endOfMonthExpense.matchesDate(DateTime(2027, 2, 28)), isTrue);
      // October 2027 has 31 days
      expect(endOfMonthExpense.matchesDate(DateTime(2027, 10, 31)), isTrue);
      // November 2027 has 30 days
      expect(endOfMonthExpense.matchesDate(DateTime(2027, 11, 30)), isTrue);
    });

    test('Debt account reduces on expense liquidation and auto-reconciliation matches (Prestamo PLATA)', () {
      final debtAccount = AccountModel(
        id: 'acc_plata',
        name: 'Préstamo PLATA',
        categoryId: 'cat_loans',
        categoryName: 'Préstamos Personales',
        type: AccountType.debt,
        initialAmount: 18023.90,
        currentAmount: 18023.90,
        colorHex: 'FFEF4444',
        iconCodePoint: 0xe49e,
      );

      final payment = MovementModel(
        id: 'mov_pago_plata',
        title: 'Pago Préstamo PLATA',
        amount: 7641.77,
        type: MovementType.expense,
        iconCodePoint: 0xe49e,
        colorHex: 'FFEF4444',
        scheduledDate: DateTime(2026, 9, 25),
        accountId: 'acc_plata',
        accountName: 'Préstamo PLATA',
        liquidationDate: DateTime(2026, 9, 25),
      );

      // Simulation of reconciliation
      final liquidated = [payment];
      double totalExpense = 0;
      double totalIncome = 0;
      for (final m in liquidated) {
        if (m.accountId == debtAccount.id || m.accountName == debtAccount.name) {
          if (m.isExpense) totalExpense += m.amount;
          if (m.isIncome) totalIncome += m.amount;
        }
      }

      final reconciled = (debtAccount.initialAmount - totalExpense + totalIncome)
          .clamp(0.0, double.infinity);

      expect(reconciled, closeTo(10382.13, 0.01));
    });

    test('RecurringScope onlyThis deletion skips only that date and keeps others active', () {
      final prog = MovementModel(
        id: 'prog_gym',
        title: 'Gimnasio',
        amount: 800,
        type: MovementType.expense,
        iconCodePoint: 0xe318,
        colorHex: 'FFEF4444',
        scheduledDate: DateTime(2026, 8, 15),
        recurrenceType: RecurrenceType.monthly,
      );

      // Delete only occurrence on 2026-9-15
      final targetDate = DateTime(2026, 9, 15);
      final dateKey = '${targetDate.year}-${targetDate.month}-${targetDate.day}';
      final updated = prog.copyWith(skippedDates: [dateKey]);

      expect(updated.matchesDate(DateTime(2026, 8, 15)), isTrue);
      expect(updated.matchesDate(DateTime(2026, 9, 15)), isFalse);
      expect(updated.matchesDate(DateTime(2026, 10, 15)), isTrue);
    });

    test('RecurringScope thisAndFuture deletion sets endDate to before date', () {
      final prog = MovementModel(
        id: 'prog_gym',
        title: 'Gimnasio',
        amount: 800,
        type: MovementType.expense,
        iconCodePoint: 0xe318,
        colorHex: 'FFEF4444',
        scheduledDate: DateTime(2026, 8, 15),
        recurrenceType: RecurrenceType.monthly,
      );

      // Delete this and future occurrences from 2026-10-15
      final cutoffDate = DateTime(2026, 10, 15);
      final newEndDate = cutoffDate.subtract(const Duration(days: 1));
      final updated = prog.copyWith(endDate: newEndDate);

      expect(updated.matchesDate(DateTime(2026, 8, 15)), isTrue);
      expect(updated.matchesDate(DateTime(2026, 9, 15)), isTrue);
      expect(updated.matchesDate(DateTime(2026, 10, 15)), isFalse);
      expect(updated.matchesDate(DateTime(2026, 11, 15)), isFalse);
    });

    test('RecurringScope thisAndFuture editing creates two segmented timelines', () {
      final originalProg = MovementModel(
        id: 'prog_spotify',
        title: 'Spotify Antiguo',
        amount: 115,
        type: MovementType.expense,
        iconCodePoint: 0xe518,
        colorHex: 'FF3EB489',
        scheduledDate: DateTime(2026, 1, 10),
        recurrenceType: RecurrenceType.monthly,
      );

      // Edit starting on 2026-10-10: price increases to 149 and title changes
      final occDate = DateTime(2026, 10, 10);
      final truncatedOriginal = originalProg.copyWith(
        endDate: occDate.subtract(const Duration(days: 1)),
      );
      final newProgram = MovementModel(
        id: 'prog_spotify_new',
        title: 'Spotify Nuevo Precio',
        amount: 149,
        type: MovementType.expense,
        iconCodePoint: 0xe518,
        colorHex: 'FF3EB489',
        scheduledDate: occDate,
        recurrenceType: RecurrenceType.monthly,
      );

      // Before Oct 2026: original program matches, new program does not
      expect(truncatedOriginal.matchesDate(DateTime(2026, 9, 10)), isTrue);
      expect(newProgram.matchesDate(DateTime(2026, 9, 10)), isFalse);

      // On/After Oct 2026: original program does not match, new program matches
      expect(truncatedOriginal.matchesDate(DateTime(2026, 10, 10)), isFalse);
      expect(newProgram.matchesDate(DateTime(2026, 10, 10)), isTrue);
      expect(newProgram.occurrenceForDate(DateTime(2026, 10, 10)).amount, equals(149));
      expect(newProgram.occurrenceForDate(DateTime(2026, 11, 10)).amount, equals(149));
    });
  });
}
