import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';

/// 3D tactile game button with physical press compression, sound effect, and haptic response.
/// Adapts seamlessly to Light and Dark themes.
class BouncingGameButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? bevelColor;
  final Color? borderColor;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? extraGlow;

  const BouncingGameButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.bevelColor,
    this.borderColor,
    this.width,
    this.height = 56,
    this.borderRadius = 18,
    this.padding,
    this.extraGlow,
  });

  @override
  State<BouncingGameButton> createState() => _BouncingGameButtonState();
}

class _BouncingGameButtonState extends State<BouncingGameButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    HapticService.instance.lightImpact();
    AudioService.instance.playButtonClick();
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    const double bevelDepth = 4.0;
    final double topTranslate = _isPressed ? bevelDepth : 0.0;
    final double bottomMargin = _isPressed ? 0.0 : bevelDepth;

    final Color effectiveBg = widget.backgroundColor ?? AppColors.primary;
    final Color effectiveBevel = widget.bevelColor ?? AppColors.buttonBevel;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, topTranslate, 0),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 1.5)
                : null,
            boxShadow: [
              // Bottom 3D bevel shadow
              BoxShadow(
                color: effectiveBevel,
                offset: Offset(0, bottomMargin),
                blurRadius: 0,
              ),
              // Soft ambient glow
              if (widget.extraGlow != null) ...widget.extraGlow!,
            ],
          ),
          child: Center(
            widthFactor: widget.width == null ? 1.0 : null,
            heightFactor: 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
