import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:dollar_bills/pages/shared/dialogs/app_message.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';
import 'package:dollar_bills/pages/shared/widgets/custom_card.dart';

enum CustomSnackBarType {
  success,
  alert,
  info,
  warning;

  String get title {
    switch (this) {
      case CustomSnackBarType.success:
        return 'Éxito';
      case CustomSnackBarType.info:
        return 'Información';
      case CustomSnackBarType.alert:
        return 'Aviso';
      case CustomSnackBarType.warning:
        return 'Advertencia';
    }
  }
}

class StatusDialog extends StatelessWidget {
  final CustomSnackBarType type;
  final String? title;
  final Object subtitle;
  final String? continueText;
  final String? cancelText;
  final TextAlign? textAlign;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;

  const StatusDialog({
    super.key,
    required this.type,
    this.title,
    required this.subtitle,
    this.onContinue,
    this.continueText = 'Aceptar',
    this.cancelText = 'Cancelar',
    this.textAlign,
    this.onCancel,
  });

  Color get _color {
    switch (type) {
      case CustomSnackBarType.success:
        return HexColor.mintPrimary;
      case CustomSnackBarType.alert:
        return HexColor.foregroundOrange;
      case CustomSnackBarType.warning:
        return HexColor.debtOrange;
      case CustomSnackBarType.info:
        return HexColor.foregroundBlue;
    }
  }

  IconData get _icon {
    switch (type) {
      case CustomSnackBarType.success:
        return Icons.check_circle_outline_rounded;
      case CustomSnackBarType.alert:
      case CustomSnackBarType.warning:
        return Icons.warning_amber_rounded;
      case CustomSnackBarType.info:
        return Icons.info_outline_rounded;
    }
  }

  String get _displaySubtitle {
    final s = subtitle;
    if (s is String) return s;
    if (s is ErrorMessage) return s.displayMessage;
    return s.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomCard.circle(
              elevation: 0,
              color: _color.withValues(alpha: 0.15),
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(_icon, size: 56, color: _color),
              ),
            ),
            const Gap(16),
            Text(
              title ?? type.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
            const Gap(10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  _displaySubtitle,
                  textAlign: textAlign ?? TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onContinue ?? () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  continueText ?? 'Aceptar',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (onCancel != null) ...[
              const Gap(8),
              TextButton(
                onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                child: Text(
                  cancelText ?? 'Cancelar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
