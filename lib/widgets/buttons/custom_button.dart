import 'package:flutter/material.dart';
import '../../utils/utils.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? icon;
  final bool isOutlined;
  final double? fontSize;
  final FontWeight? fontWeight;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 50,
    this.padding,
    this.borderRadius,
    this.icon,
    this.isOutlined = false,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? getColor('primary');
    final effectiveForegroundColor = foregroundColor ?? Colors.white;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(effectiveForegroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: effectiveForegroundColor,
                ),
              ),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: effectiveBackgroundColor,
            side: BorderSide(color: effectiveBackgroundColor),
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: buttonChild,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveForegroundColor,
          shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 2,
        ),
        child: buttonChild,
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool isLoading;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 24,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? getColor('primary');
    final effectiveForegroundColor = foregroundColor ?? Colors.white;

    Widget buttonChild = isLoading
        ? SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(effectiveForegroundColor),
            ),
          )
        : Icon(icon, size: size, color: effectiveForegroundColor);

    return IconButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveForegroundColor,
        shape: const CircleBorder(),
      ),
      icon: buttonChild,
    );
  }
}
