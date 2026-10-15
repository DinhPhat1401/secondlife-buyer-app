import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum SlButtonType { primary, secondary, outline, text }

class SlButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final SlButtonType type;
  final Widget? icon;
  final double? width;
  final double height;

  const SlButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = SlButtonType.primary,
    this.icon,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget childWidget;
    if (isLoading) {
      childWidget = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (icon != null) {
      childWidget = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    } else {
      childWidget = Text(text);
    }

    final buttonChild = SizedBox(
      width: width,
      height: height,
      child: () {
        switch (type) {
          case SlButtonType.primary:
            return ElevatedButton(
              onPressed: effectiveOnPressed,
              child: childWidget,
            );
          case SlButtonType.secondary:
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
              ),
              onPressed: effectiveOnPressed,
              child: childWidget,
            );
          case SlButtonType.outline:
            return OutlinedButton(
              onPressed: effectiveOnPressed,
              child: childWidget,
            );
          case SlButtonType.text:
            return TextButton(
              onPressed: effectiveOnPressed,
              child: childWidget,
            );
        }
      }(),
    );

    return buttonChild;
  }
}
