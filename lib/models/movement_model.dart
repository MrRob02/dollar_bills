enum MovementType {
  income, // Entrada (+)
  expense; // Salida (-)

  String get displayName {
    switch (this) {
      case MovementType.income:
        return 'Entrada';
      case MovementType.expense:
        return 'Salida';
    }
  }
}

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurrenceType.none:
        return 'Una sola vez';
      case RecurrenceType.daily:
        return 'Diario';
      case RecurrenceType.weekly:
        return 'Semanal';
      case RecurrenceType.monthly:
        return 'Mensual';
      case RecurrenceType.yearly:
        return 'Anual';
    }
  }
}

enum RecurringScope {
  onlyThis,
  thisAndFuture,
  all;

  String get displayName {
    switch (this) {
      case RecurringScope.onlyThis:
        return 'Solo este movimiento';
      case RecurringScope.thisAndFuture:
        return 'Este y los movimientos posteriores';
      case RecurringScope.all:
        return 'Todos los movimientos';
    }
  }
}

class MovementModel {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final MovementType type;
  final int iconCodePoint;
  final String colorHex;
  final String? accountId; // Cuenta personalizada adicional vinculada (deuda/deudor)
  final String? accountName;
  final DateTime scheduledDate;
  final DateTime? liquidationDate;
  final bool affectsBalance; // True por defecto; si es false, ya estaba contemplado en el balance inicial
  final RecurrenceType recurrenceType;
  final bool isLastDayOfMonth;
  final String? recurringGroupId;
  final int repetitionIndex;
  final int? totalRepetitions;
  final DateTime? endDate;
  final Map<String, String> liquidatedDates; // 'yyyy-M-d' -> ISO string of liquidation
  final List<String> skippedDates; // 'yyyy-M-d' of skipped/deleted occurrences

  const MovementModel({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.type,
    required this.iconCodePoint,
    required this.colorHex,
    this.accountId,
    this.accountName,
    required this.scheduledDate,
    this.liquidationDate,
    this.affectsBalance = true,
    this.recurrenceType = RecurrenceType.none,
    this.isLastDayOfMonth = false,
    this.recurringGroupId,
    this.repetitionIndex = 1,
    this.totalRepetitions,
    this.endDate,
    this.liquidatedDates = const {},
    this.skippedDates = const [],
  });

  /// Getter computado según comentario de revisión
  bool get isLiquidated => liquidationDate != null;

  bool get isIncome => type == MovementType.income;
  bool get isExpense => type == MovementType.expense;
  bool get isRecurring => recurrenceType != RecurrenceType.none;
  bool get hasCustomAccount => accountId != null && accountId != 'main';
  bool get affectsMainBalance => affectsBalance;

  /// Revisa si esta programación debe pintarse en la fecha especificada
  bool matchesDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );

    // No puede ser antes de la fecha inicial programada
    if (d.isBefore(start)) return false;

    // Si fue eliminada/omitida específicamente en esta fecha
    final dateKey = '${d.year}-${d.month}-${d.day}';
    if (skippedDates.contains(dateKey)) return false;

    // Si tiene fecha fin, no debe ser posterior
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (d.isAfter(end)) return false;
    }

    switch (recurrenceType) {
      case RecurrenceType.none:
        return d.isAtSameMomentAs(start);

      case RecurrenceType.daily:
        if (totalRepetitions != null) {
          final daysDiff = d.difference(start).inDays;
          if (daysDiff >= totalRepetitions!) return false;
        }
        return true;

      case RecurrenceType.weekly:
        if (d.weekday != start.weekday) return false;
        if (totalRepetitions != null) {
          final weeksDiff = d.difference(start).inDays ~/ 7;
          if (weeksDiff >= totalRepetitions!) return false;
        }
        return true;

      case RecurrenceType.monthly:
        final monthsDiff =
            (d.year - start.year) * 12 + (d.month - start.month);
        if (monthsDiff < 0) return false;
        if (totalRepetitions != null && monthsDiff >= totalRepetitions!) {
          return false;
        }

        if (isLastDayOfMonth) {
          final lastDay = DateTime(d.year, d.month + 1, 0).day;
          return d.day == lastDay;
        } else {
          final lastDay = DateTime(d.year, d.month + 1, 0).day;
          final targetDay =
              start.day > lastDay ? lastDay : start.day;
          return d.day == targetDay;
        }

      case RecurrenceType.yearly:
        final yearsDiff = d.year - start.year;
        if (yearsDiff < 0) return false;
        if (totalRepetitions != null && yearsDiff >= totalRepetitions!) {
          return false;
        }
        return d.month == start.month && d.day == start.day;
    }
  }

  /// Retorna la instancia de movimiento para una fecha específica
  MovementModel occurrenceForDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    final liqStr = liquidatedDates[dateKey];
    final dateLiquidation = liqStr != null ? DateTime.parse(liqStr) : null;

    return copyWith(
      id: isRecurring ? '${id}_$dateKey' : id,
      scheduledDate: DateTime(date.year, date.month, date.day),
      liquidationDate: isRecurring ? dateLiquidation : liquidationDate,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'amount': amount,
        'type': type.name,
        'iconCodePoint': iconCodePoint,
        'colorHex': colorHex,
        'accountId': accountId,
        'accountName': accountName,
        'scheduledDate': scheduledDate.toIso8601String(),
        'liquidationDate': liquidationDate?.toIso8601String(),
        'affectsBalance': affectsBalance,
        'recurrenceType': recurrenceType.name,
        'isLastDayOfMonth': isLastDayOfMonth,
        'recurringGroupId': recurringGroupId,
        'repetitionIndex': repetitionIndex,
        'totalRepetitions': totalRepetitions,
        'endDate': endDate?.toIso8601String(),
        'liquidatedDates': liquidatedDates,
        'skippedDates': skippedDates,
      };

  factory MovementModel.fromMap(Map<dynamic, dynamic> map) {
    final rawLiqDates = map['liquidatedDates'];
    final Map<String, String> resolvedLiqDates = {};
    if (rawLiqDates is Map) {
      for (final entry in rawLiqDates.entries) {
        resolvedLiqDates[entry.key.toString()] = entry.value.toString();
      }
    }

    final rawSkipped = map['skippedDates'];
    final List<String> resolvedSkipped = [];
    if (rawSkipped is List) {
      for (final item in rawSkipped) {
        resolvedSkipped.add(item.toString());
      }
    }

    return MovementModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      amount: (map['amount'] as num).toDouble(),
      type: MovementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MovementType.expense,
      ),
      iconCodePoint: map['iconCodePoint'] as int? ?? 0xe043,
      colorHex: map['colorHex'] as String? ?? 'FF3EB489',
      accountId: map['accountId'] as String?,
      accountName: map['accountName'] as String?,
      scheduledDate: DateTime.parse(map['scheduledDate'] as String),
      liquidationDate: map['liquidationDate'] != null
          ? DateTime.parse(map['liquidationDate'] as String)
          : null,
      affectsBalance: map['affectsBalance'] as bool? ?? true,
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.name == map['recurrenceType'],
        orElse: () => RecurrenceType.none,
      ),
      isLastDayOfMonth: map['isLastDayOfMonth'] as bool? ?? false,
      recurringGroupId: map['recurringGroupId'] as String?,
      repetitionIndex: map['repetitionIndex'] as int? ?? 1,
      totalRepetitions: map['totalRepetitions'] as int?,
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      liquidatedDates: resolvedLiqDates,
      skippedDates: resolvedSkipped,
    );
  }

  MovementModel copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    MovementType? type,
    int? iconCodePoint,
    String? colorHex,
    String? accountId,
    String? accountName,
    DateTime? scheduledDate,
    DateTime? liquidationDate,
    bool clearLiquidationDate = false,
    bool? affectsBalance,
    RecurrenceType? recurrenceType,
    bool? isLastDayOfMonth,
    String? recurringGroupId,
    int? repetitionIndex,
    int? totalRepetitions,
    DateTime? endDate,
    Map<String, String>? liquidatedDates,
    List<String>? skippedDates,
  }) {
    return MovementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      liquidationDate: clearLiquidationDate
          ? null
          : (liquidationDate ?? this.liquidationDate),
      affectsBalance: affectsBalance ?? this.affectsBalance,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      isLastDayOfMonth: isLastDayOfMonth ?? this.isLastDayOfMonth,
      recurringGroupId: recurringGroupId ?? this.recurringGroupId,
      repetitionIndex: repetitionIndex ?? this.repetitionIndex,
      totalRepetitions: totalRepetitions ?? this.totalRepetitions,
      endDate: endDate ?? this.endDate,
      liquidatedDates: liquidatedDates ?? this.liquidatedDates,
      skippedDates: skippedDates ?? this.skippedDates,
    );
  }
}
