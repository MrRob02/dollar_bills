import 'package:flutter/material.dart';
import 'package:dollar_bills/pages/shared/dialogs/app_message.dart';
import 'package:dollar_bills/pages/shared/dialogs/status_dialog.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';

export 'package:dollar_bills/pages/shared/dialogs/status_dialog.dart'
    show CustomSnackBarType, StatusDialog;

class AppSnackBarWith {
  final BuildContext? context;
  final OverlayState? _overlay;

  AppSnackBarWith(BuildContext this.context) : _overlay = null;

  AppSnackBarWith.withOverlay(OverlayState overlay)
    : context = null,
      _overlay = overlay;

  Future show({
    String? title,
    required Object message,
    CustomSnackBarType type = CustomSnackBarType.alert,
    Duration duration = const Duration(seconds: 3),
    TextAlign? textAlign,
    bool barrierDismissible = true,
    bool forceDialog = false,
  }) async {
    if (type == CustomSnackBarType.success && !forceDialog) {
      assert(
        message is! ErrorMessage,
        'This class should not be sent to this type, use .alert, .info or .warning types',
      );
      final overlay = _overlay ?? (context != null ? Overlay.of(context!) : null);
      if (overlay == null) return;
      return _DollarToast.showOnOverlay(
        overlay,
        title: title ?? type.title,
        message: message is String ? message : message.toString(),
        icon: Icons.check_circle_rounded,
        color: HexColor.mintPrimary,
        duration: duration,
      );
    } else {
      if (context == null) return;
      return showDialog(
        context: context!,
        barrierDismissible: barrierDismissible,
        builder: (ctx) => StatusDialog(
          type: type,
          title: title,
          textAlign: textAlign,
          subtitle: message,
        ),
      );
    }
  }
}

class _DollarToast extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;

  const _DollarToast({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.duration,
  });

  static void showOnOverlay(
    OverlayState overlay, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required Duration duration,
  }) {
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _DollarToast(
        title: title,
        message: message,
        icon: icon,
        color: color,
        duration: duration,
      ),
    );

    overlay.insert(entry);
    Future.delayed(duration + const Duration(milliseconds: 1000), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  @override
  State<_DollarToast> createState() => _DollarToastState();
}

class _DollarToastState extends State<_DollarToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
