import 'package:flutter/material.dart';
import 'package:moochat/core/theming/colors.dart';

/// Modern Dialog with updated design system
///
/// Features:
/// - Clean elevated surface with rounded corners
/// - Modern button styling with new color scheme
/// - Better spacing and typography
/// - Smooth animations and shadows
/// - Accessibility improvements
class ModernDialog extends StatelessWidget {
  const ModernDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const [],
    this.contentPadding,
    this.actionsPadding,
    this.backgroundColor,
    this.elevation = 8.0,
  });

  final String title;
  final Widget? content;
  final List<Widget> actions;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final Color? backgroundColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor ?? ColorsManager.surface,
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? ColorsManager.surface,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Content
            if (content != null)
              Flexible(
                child: Padding(
                  padding:
                      contentPadding ??
                      const EdgeInsets.symmetric(horizontal: 24.0),
                  child: content!,
                ),
              ),

            // Actions
            if (actions.isNotEmpty)
              Padding(
                padding:
                    actionsPadding ??
                    const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12.0),
                      actions[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show dialog with modern styling
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    Widget? content,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
    Color? backgroundColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ModernDialog(
        title: title,
        content: content,
        actions: actions,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

/// Modern Dialog Buttons with consistent styling
class ModernDialogButton extends StatelessWidget {
  const ModernDialogButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ModernButtonVariant.text,
    this.color,
    this.textColor,
    this.isDestructive = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ModernButtonVariant variant;
  final Color? color;
  final Color? textColor;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDestructive
        ? ColorsManager.error
        : (color ?? ColorsManager.primary);

    final effectiveTextColor =
        textColor ??
        (variant == ModernButtonVariant.filled ? Colors.white : effectiveColor);

    switch (variant) {
      case ModernButtonVariant.filled:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveColor,
            foregroundColor: effectiveTextColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: child,
        );

      case ModernButtonVariant.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: effectiveTextColor,
            side: BorderSide(color: effectiveColor),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: child,
        );

      case ModernButtonVariant.text:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: effectiveTextColor,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: child,
        );
    }
  }
}

enum ModernButtonVariant { filled, outlined, text }

/// Convenience methods for common dialog patterns
class ModernDialogUtils {
  /// Show confirmation dialog
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await ModernDialog.show<bool>(
      context: context,
      title: title,
      content: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 16.0,
            color: ColorsManager.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ),
      actions: [
        ModernDialogButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ModernDialogButton(
          onPressed: () => Navigator.of(context).pop(true),
          variant: ModernButtonVariant.filled,
          isDestructive: isDestructive,
          child: Text(confirmText),
        ),
      ],
    );
    return result ?? false;
  }

  /// Show info dialog
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await ModernDialog.show(
      context: context,
      title: title,
      content: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 16.0,
            color: ColorsManager.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ),
      actions: [
        ModernDialogButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: ModernButtonVariant.filled,
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Show error dialog
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await ModernDialog.show(
      context: context,
      title: title,
      content: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 16.0,
            color: ColorsManager.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ),
      actions: [
        ModernDialogButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: ModernButtonVariant.filled,
          isDestructive: true,
          child: Text(buttonText),
        ),
      ],
    );
  }
}
