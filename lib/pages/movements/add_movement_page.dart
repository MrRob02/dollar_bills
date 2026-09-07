import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:dollar_bills/models/account_model.dart';
import 'package:dollar_bills/models/movement_model.dart';
import 'package:dollar_bills/pages/movements/widgets/recurring_scope_dialog.dart';
import 'package:dollar_bills/pages/shared/dialogs/app_snackbar.dart';
import 'package:dollar_bills/pages/shared/theme/app_icons.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';
import 'package:dollar_bills/pages/shared/widgets/custom_scaffold.dart';
import 'package:dollar_bills/services/accounts_service.dart';
import 'package:dollar_bills/services/movements_service.dart';

class AddMovementPage extends StatefulWidget {
  final MovementModel? movementToEdit;
  final DateTime? occurrenceDate;

  const AddMovementPage({
    super.key,
    this.movementToEdit,
    this.occurrenceDate,
  });

  @override
  State<AddMovementPage> createState() => _AddMovementPageState();
}

class _AddMovementPageState extends State<AddMovementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _repetitionsController = TextEditingController(text: '12');

  MovementType _type = MovementType.expense;
  DateTime _scheduledDate = DateTime.now();
  RecurrenceType _recurrenceType = RecurrenceType.none;
  bool _isLastDayOfMonth = false;

  // Initial liquidation state
  bool _isPaid = false;
  bool _affectsBalance = true;
  DateTime _liquidationDate = DateTime.now();

  // End condition: 0 = Indefinite, 1 = Date, 2 = Repetitions
  int _endConditionType = 0;
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));

  // Selected icon & color
  int _selectedIconCode = 0xe518; // receipt
  String _selectedColorHex = 'FF3EB489';

  // Accounts list
  List<AccountModel> _accounts = [];
  String? _selectedAccountId; // null = Main Balance only

  bool _isLoading = false;

  final List<int> _iconOptions = [
    0xe518, // receipt
    0xe19f, // credit_card
    0xe49e, // payments
    0xe8cc, // shopping_cart
    0xe56c, // restaurant
    0xe7ee, // work
    0xe88a, // home
    0xe531, // directions_car
    0xe904, // flight
    0xe3f7, // medical_services
    0xe80c, // school
    0xe338, // sports_esports
    0xe318, // fitness_center
    0xe541, // local_cafe
    0xe91d, // pets
    0xe32c, // phone_iphone
  ];

  final List<String> _colorOptions = [
    'FF3EB489', // Mint primary
    'FF2EC4B6', // Mint accent
    'FF10B981', // Emerald
    'FF3B82F6', // Blue
    'FF8B5CF6', // Purple
    'FFF59E0B', // Amber
    'FFEF4444', // Red
    'FFEC4899', // Pink
    'FF64748B', // Slate
  ];

  @override
  void initState() {
    super.initState();
    if (widget.movementToEdit != null) {
      final m = widget.movementToEdit!;
      _titleController.text = m.title;
      _descriptionController.text = m.description ?? '';
      _amountController.text = m.amount.toStringAsFixed(2);
      _type = m.type;
      _scheduledDate = widget.occurrenceDate ?? m.scheduledDate;
      _recurrenceType = m.recurrenceType;
      _isLastDayOfMonth = m.isLastDayOfMonth;
      _isPaid = m.isLiquidated;
      _affectsBalance = m.affectsBalance;
      if (m.liquidationDate != null) {
        _liquidationDate = m.liquidationDate!;
      }
      _selectedIconCode = m.iconCodePoint;
      _selectedColorHex = m.colorHex;
      _selectedAccountId = m.accountId;
      if (m.endDate != null) {
        _endConditionType = 1;
        _endDate = m.endDate!;
      } else if (m.totalRepetitions != null) {
        _endConditionType = 2;
        _repetitionsController.text = m.totalRepetitions.toString();
      } else {
        _endConditionType = 0;
      }
    }
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accs = await AccountsService().getAccounts();
    if (mounted) {
      setState(() {
        _accounts = accs;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _repetitionsController.dispose();
    super.dispose();
  }

  DateTime _computeLastDayOfMonth(DateTime date) {
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final year = date.month == 12 ? date.year + 1 : date.year;
    return DateTime(year, nextMonth, 0);
  }

  Future<void> _pickDate() async {
    if (_recurrenceType == RecurrenceType.monthly && _isLastDayOfMonth) {
      return; // Disabled because it will always be the last day
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HexColor.mintPrimary,
              onPrimary: Colors.white,
              onSurface: HexColor.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _pickLiquidationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _liquidationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HexColor.mintPrimary,
              onPrimary: Colors.white,
              onSurface: HexColor.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _liquidationDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _scheduledDate,
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HexColor.mintPrimary,
              onPrimary: Colors.white,
              onSurface: HexColor.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveMovement() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      AppSnackBarWith(context).show(message: 'Ingresa un monto válido mayor a 0');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedAccount = _selectedAccountId != null
          ? _accounts.firstWhere((a) => a.id == _selectedAccountId)
          : null;

      final actualScheduledDate =
          (_recurrenceType == RecurrenceType.monthly && _isLastDayOfMonth)
              ? _computeLastDayOfMonth(_scheduledDate)
              : _scheduledDate;

      int? maxRepetitions;
      DateTime? endDate;

      if (_recurrenceType != RecurrenceType.none) {
        if (_endConditionType == 1) {
          endDate = _endDate;
        } else if (_endConditionType == 2) {
          maxRepetitions = int.tryParse(_repetitionsController.text) ?? 12;
        }
      }

      if (widget.movementToEdit != null) {
        // Modo edición
        RecurringScope scope = RecurringScope.all;
        if (widget.movementToEdit!.isRecurring) {
          setState(() => _isLoading = false);
          final selectedScope = await RecurringScopeDialog.show(
            context,
            isDelete: false,
            title: widget.movementToEdit!.title,
            date: widget.occurrenceDate ?? actualScheduledDate,
          );
          if (selectedScope == null) return;
          scope = selectedScope;
          setState(() => _isLoading = true);
        }

        final updated = widget.movementToEdit!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          amount: amount,
          type: _type,
          iconCodePoint: _selectedIconCode,
          colorHex: _selectedColorHex,
          scheduledDate: actualScheduledDate,
          accountId: _selectedAccountId,
          accountName: selectedAccount?.name,
          affectsBalance: _affectsBalance,
          recurrenceType: _recurrenceType,
          isLastDayOfMonth: _isLastDayOfMonth,
          endDate: endDate,
          totalRepetitions: maxRepetitions,
          liquidationDate: _isPaid ? _liquidationDate : null,
          clearLiquidationDate: !_isPaid,
        );

        await MovementsService().updateMovement(
          updated,
          originalOccurrenceDate: widget.occurrenceDate,
          scope: scope,
        );

        if (mounted) {
          AppSnackBarWith(context).show(
            message: 'Movimiento actualizado con éxito',
            type: CustomSnackBarType.success,
          );
          Navigator.of(context).pop(true);
        }
        return;
      }

      await MovementsService().scheduleMovement(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        amount: amount,
        type: _type,
        iconCodePoint: _selectedIconCode,
        colorHex: _selectedColorHex,
        scheduledDate: actualScheduledDate,
        accountId: _selectedAccountId,
        accountName: selectedAccount?.name,
        isPaid: _isPaid,
        affectsBalance: _affectsBalance,
        liquidationDate: _isPaid ? _liquidationDate : null,
        recurrenceType: _recurrenceType,
        isLastDayOfMonth: _isLastDayOfMonth,
        endDate: endDate,
        maxRepetitions: maxRepetitions,
      );

      if (mounted) {
        AppSnackBarWith(context).show(
          message: _isPaid
              ? 'Movimiento registrado como pagado'
              : 'Movimiento programado con éxito',
          type: CustomSnackBarType.success,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBarWith(context).show(message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es_MX');

    return CustomScaffold(
      title: widget.movementToEdit != null
          ? 'Editar Movimiento'
          : 'Programar Movimiento',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented control: Entrada (+) vs Salida (-)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: HexColor.backgroundGrey200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          _type = MovementType.income;
                          _selectedColorHex = 'FF10B981';
                        }),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == MovementType.income
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _type == MovementType.income
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 18,
                                color: _type == MovementType.income
                                    ? HexColor.incomeGreen
                                    : HexColor.textMuted,
                              ),
                              const Gap(6),
                              Text(
                                'Entrada',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _type == MovementType.income
                                      ? HexColor.incomeGreen
                                      : HexColor.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          _type = MovementType.expense;
                          _selectedColorHex = 'FFEF4444';
                        }),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == MovementType.expense
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _type == MovementType.expense
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 18,
                                color: _type == MovementType.expense
                                    ? HexColor.expenseRed
                                    : HexColor.textMuted,
                              ),
                              const Gap(6),
                              Text(
                                'Salida',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _type == MovementType.expense
                                      ? HexColor.expenseRed
                                      : HexColor.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(20),

              // Title and Description fields
              Text(
                'Nombre del movimiento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: HexColor.textPrimary,
                ),
              ),
              const Gap(8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Ej. Sueldo, Renta, Préstamo Juan',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: HexColor.mintPrimary, width: 2),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const Gap(16),

              Text(
                'Descripción (Opcional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: HexColor.textPrimary,
                ),
              ),
              const Gap(8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Añade notas o detalles adicionales...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: HexColor.mintPrimary, width: 2),
                  ),
                ),
              ),
              const Gap(16),

              Text(
                'Monto (\$)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: HexColor.textPrimary,
                ),
              ),
              const Gap(8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  hintText: '0.00',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: HexColor.mintPrimary, width: 2),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa el monto' : null,
              ),
              const Gap(20),

              // Section: Estado inicial (Liquidado / Pagado)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isPaid
                      ? HexColor.mintLight.withValues(alpha: 0.6)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isPaid
                        ? HexColor.mintPrimary.withValues(alpha: 0.4)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estado: Pagado / Liquidado',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: HexColor.textPrimary,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                'Márcalo si este movimiento ya ocurrió y ya fue cobrado/pagado.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: HexColor.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(8),
                        Switch.adaptive(
                          activeTrackColor: HexColor.mintPrimary,
                          value: _isPaid,
                          onChanged: (val) => setState(() => _isPaid = val),
                        ),
                      ],
                    ),
                    if (_isPaid) ...[
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Afectar balance actual',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: HexColor.textPrimary,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  _affectsBalance
                                      ? '${_type == MovementType.income ? 'Sumará' : 'Restará'} este monto a tu débito al día.'
                                      : 'Apagado: ya está contemplado en tu saldo actual.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _affectsBalance
                                        ? HexColor.mintPrimaryDark
                                        : HexColor.debtOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          Switch.adaptive(
                            activeTrackColor: HexColor.mintPrimary,
                            value: _affectsBalance,
                            onChanged: (val) => setState(() => _affectsBalance = val),
                          ),
                        ],
                      ),
                      const Gap(8),
                      InkWell(
                        onTap: _pickLiquidationDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.event_available_rounded,
                                      color: HexColor.mintPrimary, size: 18),
                                  const Gap(8),
                                  Text(
                                    'Fecha de pago: ${dateFormat.format(_liquidationDate)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.edit_calendar,
                                  color: HexColor.mintPrimary, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(20),

              // Account selector
              Text(
                'Cuenta (Opcional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: HexColor.textPrimary,
                ),
              ),
              const Gap(4),
              Text(
                'Selecciona una cuenta de deuda o deudor si deseas que afecte su saldo.',
                style: TextStyle(fontSize: 12, color: HexColor.textMuted),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle_outline_rounded,
                                color: HexColor.textMuted, size: 18),
                            const Gap(10),
                            Text(
                              'Ninguna',
                              style: TextStyle(
                                color: HexColor.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._accounts.map(
                        (a) => DropdownMenuItem<String?>(
                          value: a.id,
                          child: Row(
                            children: [
                              Icon(
                                a.isDebt
                                    ? Icons.money_off_rounded
                                    : Icons.attach_money_rounded,
                                color: a.isDebt
                                    ? HexColor.debtOrange
                                    : HexColor.debtorBlue,
                                size: 20,
                              ),
                              const Gap(10),
                              Text(
                                '${a.name} (${a.type.displayName})',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedAccountId = val),
                  ),
                ),
              ),
              const Gap(20),

              // Icon & Color Pickers
              Text(
                'Icono y Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: HexColor.textPrimary,
                ),
              ),
              const Gap(10),
              // Icon selector horizontal
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _iconOptions.length,
                  separatorBuilder: (context, index) => const Gap(8),
                  itemBuilder: (context, idx) {
                    final code = _iconOptions[idx];
                    final isSelected = code == _selectedIconCode;
                    return InkWell(
                      onTap: () => setState(() => _selectedIconCode = code),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? HexColor.mintPrimary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? HexColor.mintPrimary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(
                          AppIcons.getIcon(code),
                          color: isSelected ? Colors.white : HexColor.textSecondary,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Gap(12),
              // Color selector horizontal
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colorOptions.length,
                  separatorBuilder: (context, index) => const Gap(10),
                  itemBuilder: (context, idx) {
                    final hex = _colorOptions[idx];
                    final isSelected = hex == _selectedColorHex;
                    final clr = HexColor(hex);
                    return InkWell(
                      onTap: () => setState(() => _selectedColorHex = hex),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: clr,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: clr.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const Gap(24),

              // Date and Recurrence
              Text(
                'Fecha y Programación',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: HexColor.textPrimary,
                ),
              ),
              const Gap(10),
              // Scheduled Date Picker
              InkWell(
                onTap: (_recurrenceType == RecurrenceType.monthly && _isLastDayOfMonth)
                    ? null
                    : _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: (_recurrenceType == RecurrenceType.monthly && _isLastDayOfMonth)
                        ? Colors.grey.shade100
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              color: (_recurrenceType == RecurrenceType.monthly && _isLastDayOfMonth)
                                  ? HexColor.textMuted
                                  : HexColor.mintPrimary,
                              size: 20),
                          const Gap(12),
                          Text(
                            (_recurrenceType == RecurrenceType.monthly && _isLastDayOfMonth)
                                ? 'Último día del mes (Automático)'
                                : 'Fecha: ${dateFormat.format(_scheduledDate)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: (_recurrenceType == RecurrenceType.monthly && _isLastDayOfMonth)
                                  ? HexColor.textMuted
                                  : HexColor.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (!(_recurrenceType == RecurrenceType.monthly && _isLastDayOfMonth))
                        Icon(Icons.edit_calendar_rounded,
                            color: HexColor.mintPrimary, size: 20),
                    ],
                  ),
                ),
              ),
              const Gap(14),

              // Recurrence dropdown
              Text(
                'Repetición',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HexColor.textSecondary,
                ),
              ),
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RecurrenceType>(
                    value: _recurrenceType,
                    isExpanded: true,
                    items: RecurrenceType.values.map(
                      (r) => DropdownMenuItem<RecurrenceType>(
                        value: r,
                        child: Text(r.displayName),
                      ),
                    ).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _recurrenceType = val;
                          if (_recurrenceType != RecurrenceType.monthly) {
                            _isLastDayOfMonth = false;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),

              // Monthly specific: Last day of month toggle
              if (_recurrenceType == RecurrenceType.monthly) ...[
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: HexColor.mintLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HexColor.mintPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Último día del mes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: HexColor.textPrimary,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              'Inhabilita la fecha fija y se programará el último día de cada mes automáticamente.',
                              style: TextStyle(fontSize: 12, color: HexColor.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      Switch.adaptive(
                        activeTrackColor: HexColor.mintPrimary,
                        value: _isLastDayOfMonth,
                        onChanged: (val) => setState(() => _isLastDayOfMonth = val),
                      ),
                    ],
                  ),
                ),
              ],

              // End condition for recurring
              if (_recurrenceType != RecurrenceType.none) ...[
                const Gap(16),
                Text(
                  'Finalización de la repetición',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HexColor.textSecondary,
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Sin fin'),
                      selected: _endConditionType == 0,
                      selectedColor: HexColor.mintPrimary,
                      labelStyle: TextStyle(
                        color: _endConditionType == 0 ? Colors.white : HexColor.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _endConditionType = 0),
                    ),
                    const Gap(8),
                    ChoiceChip(
                      label: const Text('Hasta fecha'),
                      selected: _endConditionType == 1,
                      selectedColor: HexColor.mintPrimary,
                      labelStyle: TextStyle(
                        color: _endConditionType == 1 ? Colors.white : HexColor.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _endConditionType = 1),
                    ),
                    const Gap(8),
                    ChoiceChip(
                      label: const Text('Por repeticiones'),
                      selected: _endConditionType == 2,
                      selectedColor: HexColor.mintPrimary,
                      labelStyle: TextStyle(
                        color: _endConditionType == 2 ? Colors.white : HexColor.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _endConditionType = 2),
                    ),
                  ],
                ),
                if (_endConditionType == 1) ...[
                  const Gap(10),
                  InkWell(
                    onTap: _pickEndDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Finaliza el: ${dateFormat.format(_endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Icon(Icons.edit_calendar, color: HexColor.mintPrimary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_endConditionType == 2) ...[
                  const Gap(10),
                  TextFormField(
                    controller: _repetitionsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Número de repeticiones',
                      hintText: 'Ej. 12',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Ingresa un número mayor a 0';
                      return null;
                    },
                  ),
                ],
              ],

              const Gap(32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMovement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor.mintPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.movementToEdit != null
                              ? 'Guardar Cambios'
                              : (_isPaid
                                  ? 'Registrar como Pagado'
                                  : 'Programar Movimiento'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}
