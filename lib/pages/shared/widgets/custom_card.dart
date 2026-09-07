import 'package:flutter/material.dart';

const double _elevationValue = 0.5;

class CustomCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double? elevation;
  final double disabledOpacity;
  final Color? color;
  final void Function()? onTap;
  final void Function()? onDoubleTap;
  final void Function()? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Clip? clipBehavior;
  final bool enabled;
  final BorderSide? borderSide;

  const CustomCard({
    super.key,
    required this.child,
    this.color,
    this.elevation = _elevationValue,
    this.disabledOpacity = 0.5,
    this.clipBehavior,
    this.borderRadius,
    this.onTap,
    this.onDoubleTap,
    this.padding,
    this.margin,
    this.onLongPress,
    this.enabled = true,
    this.borderSide,
  });

  const CustomCard.invisible({
    super.key,
    required this.child,
    this.color = Colors.transparent,
    this.onTap,
    this.onDoubleTap,
    this.disabledOpacity = 0.5,
    this.clipBehavior,
    this.onLongPress,
    this.borderRadius = BorderRadius.zero,
    this.enabled = true,
    this.padding = EdgeInsets.zero,
    this.borderSide,
  }) : margin = EdgeInsets.zero,
       elevation = 0;

  const CustomCard.noPadding({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.color,
    this.elevation = _elevationValue,
    this.disabledOpacity = 0.5,
    this.borderRadius,
    this.clipBehavior,
    this.onLongPress,
    this.margin,
    this.enabled = true,
    this.borderSide,
  }) : padding = EdgeInsets.zero;

  CustomCard.listRounded({
    super.key,
    required this.child,
    required bool isFirst,
    required bool isLast,
    this.color,
    this.disabledOpacity = 0.5,
    this.onTap,
    this.clipBehavior,
    this.onDoubleTap,
    this.onLongPress,
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.symmetric(vertical: 3),
    this.enabled = true,
    this.elevation = _elevationValue,
    this.borderSide,
  }) : borderRadius = _getBorder(isFirst, isLast);

  CustomCard.circle({
    super.key,
    required this.child,
    this.color,
    this.elevation = 0,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.disabledOpacity = 0.5,
    this.clipBehavior,
    this.padding,
    this.margin,
    this.enabled = true,
    this.borderSide,
  }) : borderRadius = BorderRadius.circular(200);

  static BorderRadius _getBorder(bool isFirst, bool isLast) {
    const radius = Radius.circular(16);
    const smallRadius = Radius.circular(4);
    if (isFirst && isLast) {
      return const BorderRadius.all(radius);
    } else if (isFirst) {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomRight: smallRadius,
        bottomLeft: smallRadius,
      );
    } else if (isLast) {
      return const BorderRadius.only(
        bottomLeft: radius,
        bottomRight: radius,
        topRight: smallRadius,
        topLeft: smallRadius,
      );
    } else {
      return const BorderRadius.all(smallRadius);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clr = color ?? Colors.white;
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : disabledOpacity,
        child: Card(
          color: clr,
          surfaceTintColor: clr,
          clipBehavior: clipBehavior ?? Clip.antiAlias,
          elevation: elevation,
          margin: margin,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(14),
            side: borderSide ?? BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
