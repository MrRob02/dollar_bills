import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:dollar_bills/models/category_model.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int _selectedIconCode = 0xe518; // receipt
  String _selectedColorHex = 'FF3EB489';

  final List<int> _iconOptions = [
    0xe518, // receipt
    0xe19f, // credit_card
    0xe49e, // payments
    0xe491, // people
    0xe88a, // home
    0xe531, // car
    0xe80c, // school
    0xe8cc, // shopping_cart
    0xe56c, // restaurant
    0xe7ee, // work
  ];

  final List<String> _colorOptions = [
    'FF3EB489', // Mint primary
    'FF2EC4B6', // Mint accent
    'FF10B981', // Emerald
    'FF3B82F6', // Blue
    'FF8B5CF6', // Purple
    'FFF59E0B', // Amber
    'FFEF4444', // Red
    'FF64748B', // Slate
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cat = CategoryModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      iconCodePoint: _selectedIconCode,
      colorHex: _selectedColorHex,
    );
    Navigator.of(context).pop(cat);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
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
                    child: Icon(Icons.category_rounded,
                        color: HexColor.mintPrimary, size: 22),
                  ),
                  const Gap(12),
                  Text(
                    'Nueva Categoría',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HexColor.textPrimary,
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Text(
                'Nombre de la categoría',
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
                  hintText: 'Ej. Bancos, Amigos, Negocio',
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
              const Gap(16),
              Text(
                'Icono',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: HexColor.textPrimary,
                ),
              ),
              const Gap(8),
              SizedBox(
                height: 42,
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? HexColor.mintPrimary
                              : HexColor.backgroundLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          IconData(code, fontFamily: 'MaterialIcons'),
                          color:
                              isSelected ? Colors.white : HexColor.textSecondary,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Gap(16),
              Text(
                'Color',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: HexColor.textPrimary,
                ),
              ),
              const Gap(8),
              SizedBox(
                height: 36,
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
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: clr,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: clr.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const Gap(24),
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
    );
  }
}
