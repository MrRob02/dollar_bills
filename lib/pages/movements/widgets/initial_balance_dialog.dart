import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';

class InitialBalanceDialog extends StatefulWidget {
  final double currentBalance;
  final bool isFirstTime;

  const InitialBalanceDialog({
    super.key,
    this.currentBalance = 0.0,
    this.isFirstTime = true,
  });

  @override
  State<InitialBalanceDialog> createState() => _InitialBalanceDialogState();
}

class _InitialBalanceDialogState extends State<InitialBalanceDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentBalance > 0
          ? widget.currentBalance.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final value = double.tryParse(_controller.text.replaceAll(',', '')) ?? 0.0;
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: HexColor.mintLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 32,
                  color: HexColor.mintPrimary,
                ),
              ),
              const Gap(16),
              Text(
                widget.isFirstTime
                    ? '¡Bienvenido a Dollar bills!'
                    : 'Ajustar Balance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HexColor.textPrimary,
                ),
              ),
              const Gap(8),
              Text(
                widget.isFirstTime
                    ? 'Ingresa tu balance actual (tu débito al día) para comenzar a gestionar tus finanzas.'
                    : 'Ingresa el nuevo monto disponible en tu cuenta de débito:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: HexColor.textSecondary,
                  height: 1.4,
                ),
              ),
              const Gap(24),
              TextFormField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: HexColor.mintPrimaryDark,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: HexColor.mintPrimaryDark,
                  ),
                  hintText: '0.00',
                  filled: true,
                  fillColor: HexColor.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: HexColor.mintPrimary,
                      width: 2,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Por favor ingresa un monto válido';
                  }
                  final n = double.tryParse(val.replaceAll(',', ''));
                  if (n == null || n < 0) {
                    return 'Ingresa un número mayor o igual a 0';
                  }
                  return null;
                },
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor.mintPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.isFirstTime ? 'Comenzar' : 'Guardar Balance',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!widget.isFirstTime) ...[
                const Gap(8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: HexColor.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
