import 'package:flutter/material.dart';

class PrimaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final Widget? leadingIcon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double borderRadius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  const PrimaryActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.backgroundColor = const Color(0xFF00BFA5),
    this.foregroundColor = Colors.white,
    this.borderRadius = 12,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            )
          : leadingIcon == null
          ? Text(
              text,
              style:
                  textStyle ??
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leadingIcon!,
                const SizedBox(width: 8),
                Text(
                  text,
                  style:
                      textStyle ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
    );

    if (width == null && height == null) {
      return button;
    }

    return SizedBox(width: width, height: height, child: button);
  }
}
