import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:dollar_bills/models/account_model.dart';
import 'package:dollar_bills/models/category_model.dart';
import 'package:dollar_bills/pages/accounts/add_category_dialog.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';

class AddAccountDialog extends StatefulWidget {
  final List<CategoryModel> categories;
  final void Function(CategoryModel)? onCategoryCreated;

  const AddAccountDialog({
    super.key,
    required this.categories,
    this.onCategoryCreated,
  });

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  AccountType _type = AccountType.debt;
  String? _selectedCategoryId;
  late List<CategoryModel> _localCategories;

  int _selectedIconCode = 0xe19f; // credit_card
  String _selectedColorHex = 'FFF59E0B'; // debt orange

  final List<int> _iconOptions = [
    0xe19f, // credit_card
    0xe49e, // payments
    0xe491, // people
    0xe518, // receipt
    0xe88a, // home
    0xe531, // car
    0xe7ee, // work
  ];

  final List<String> _colorOptions = [
    'FFF59E0B', // Amber / Debt orange
    'FF3B82F6', // Blue / Debtor
    'FFEF4444', // Red
    'FF8B5CF6', // Purple
    'FF3EB489', // Mint
    'FF10B981', // Emerald
    'FF64748B', // Slate
  ];

  @override
  void initState() {
    super.initState();
    _localCategories = List.from(widget.categories);
    if (_localCategories.isNotEmpty) {
      _selectedCategoryId = _localCategories.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createNewCategory() async {
    final newCat = await showDialog<CategoryModel>(
      context: context,
      builder: (_) => const AddCategoryDialog(),
    );
    if (newCat != null) {
      setState(() {
        _localCategories.add(newCat);
        _selectedCategoryId = newCat.id;
      });
      widget.onCategoryCreated?.call(newCat);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final cat = _localCategories.firstWhere((c) => c.id == _selectedCategoryId);

    final account = AccountModel(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _type,
      categoryId: cat.id,
      categoryName: cat.name,
      initialAmount: amount,
      currentAmount: amount,
      colorHex: _selectedColorHex,
      iconCodePoint: _selectedIconCode,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    Navigator.of(context).pop(account);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HexColor.mintLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: HexColor.mintPrimary,
                        size: 22,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      'Nueva Cuenta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HexColor.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  'Las cuentas de deudas y deudores no modifican tu balance de débito.',
                  style: TextStyle(fontSize: 12, color: HexColor.textMuted),
                ),
                const Gap(16),

                // Type switcher: Deuda (debo) vs Deudor (me deben)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: HexColor.backgroundGrey200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _type = AccountType.debt;
                            _selectedColorHex = 'FFF59E0B';
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _type == AccountType.debt
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Deuda (Debo pagar)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _type == AccountType.debt
                                      ? HexColor.debtOrange
                                      : HexColor.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _type = AccountType.debtor;
                            _selectedColorHex = 'FF3B82F6';
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _type == AccountType.debtor
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Deudor (Me deben)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _type == AccountType.debtor
                                      ? HexColor.debtorBlue
                                      : HexColor.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),

                // Name
                Text(
                  'Nombre de la cuenta o persona',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: HexColor.textPrimary,
                  ),
                ),
                const Gap(6),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Ej. Préstamo Juan, Tarjeta Banamex',
                    filled: true,
                    fillColor: HexColor.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
                ),
                const Gap(14),

                // Amount
                Text(
                  'Monto Total (\$)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: HexColor.textPrimary,
                  ),
                ),
                const Gap(6),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0.00',
                    filled: true,
                    fillColor: HexColor.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
                    final n = double.tryParse(v.replaceAll(',', ''));
                    if (n == null || n < 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const Gap(14),

                // Category assigned
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Categoría Asignada',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: HexColor.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: _createNewCategory,
                      child: Text(
                        '+ Crear Nueva',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: HexColor.mintPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: HexColor.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      items: _localCategories.map(
                        (c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategoryId = val);
                      },
                    ),
                  ),
                ),
                const Gap(14),

                // Icon and Color
                Text(
                  'Icono y Color',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: HexColor.textPrimary,
                  ),
                ),
                const Gap(6),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _iconOptions.length,
                    separatorBuilder: (context, index) => const Gap(8),
                    itemBuilder: (context, idx) {
                      final code = _iconOptions[idx];
                      final isSelected = code == _selectedIconCode;
                      return InkWell(
                        onTap: () => setState(() => _selectedIconCode = code),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? HexColor(_selectedColorHex)
                                : HexColor.backgroundLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            IconData(code, fontFamily: 'MaterialIcons'),
                            color: isSelected ? Colors.white : HexColor.textSecondary,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(8),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorOptions.length,
                    separatorBuilder: (context, index) => const Gap(8),
                    itemBuilder: (context, idx) {
                      final hex = _colorOptions[idx];
                      final isSelected = hex == _selectedColorHex;
                      final clr = HexColor(hex);
                      return InkWell(
                        onTap: () => setState(() => _selectedColorHex = hex),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: clr,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const Gap(24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor.mintPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Guardar',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
