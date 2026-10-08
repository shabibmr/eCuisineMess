import 'package:flutter/material.dart';

/// An animated icon widget designed for navigation rails and navigation bars.
///
/// When [isSelected] is true, it provides a subtle continuous ambient animation
/// (gentle breathing scale, floating bob, and soft aura glow) to clearly indicate
/// the active destination. When hovered on desktop/web, it smoothly scales up
/// to provide tactile interactive feedback.
class AnimatedNavIcon extends StatefulWidget {
  const AnimatedNavIcon({
    super.key,
    required this.icon,
    this.isSelected = false,
    this.size = 24.0,
    this.color,
    this.enableAmbientAnimation = true,
  });

  /// The icon glyph to display.
  final IconData icon;

  /// Whether the destination this icon belongs to is currently selected.
  final bool isSelected;

  /// Icon font size, defaults to 24.0.
  final double size;

  /// Optional custom icon color. If null, inherits from ambient [IconTheme].
  final Color? color;

  /// Whether continuous ambient idle animation is enabled when selected.
  final bool enableAmbientAnimation;

  @override
  State<AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<AnimatedNavIcon>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _glowAnimation;

  late final AnimationController _hoverController;
  late final Animation<double> _hoverScaleAnimation;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Ambient continuous breathing & float animation (3.6s full cycle)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _ambientController,
        curve: Curves.easeInOutSine,
      ),
    );

    _floatAnimation = Tween<double>(begin: 0.0, end: -1.8).animate(
      CurvedAnimation(
        parent: _ambientController,
        curve: Curves.easeInOutSine,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ambientController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Desktop hover response
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _hoverScaleAnimation = Tween<double>(begin: 0.0, end: 0.06).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOut,
      ),
    );

    // Subtle entrance pop when selected
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _entranceScaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    if (widget.isSelected) {
      _entranceController.forward(from: 0.0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationLoop();
  }

  @override
  void didUpdateWidget(covariant AnimatedNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _entranceController.forward(from: 0.0);
      }
      _syncAnimationLoop();
    }
  }

  void _syncAnimationLoop() {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.isSelected && widget.enableAmbientAnimation && !disableAnimations) {
      if (!_ambientController.isAnimating) {
        _ambientController.repeat(reverse: true);
      }
    } else {
      if (_ambientController.isAnimating) {
        _ambientController.stop();
        _ambientController.reset();
      }
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _hoverController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconTheme = IconTheme.of(context);
    final effectiveColor =
        widget.color ?? iconTheme.color ?? theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _ambientController,
            _hoverController,
            _entranceController,
          ]),
          builder: (context, child) {
            final ambientScale =
                widget.isSelected ? _scaleAnimation.value : 1.0;
            final entranceScale =
                widget.isSelected ? _entranceScaleAnimation.value : 1.0;
            final hoverScale = 1.0 + _hoverScaleAnimation.value;
            final totalScale = ambientScale * entranceScale * hoverScale;

            final floatOffset =
                widget.isSelected ? _floatAnimation.value : 0.0;

            Widget iconWidget = Icon(
              widget.icon,
              size: widget.size,
              color: effectiveColor,
            );

            if (widget.isSelected) {
              final glowAlpha =
                  (_glowAnimation.value * 0.20).clamp(0.0, 1.0);
              iconWidget = DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: glowAlpha),
                      blurRadius: 8 * _glowAnimation.value + 4,
                      spreadRadius: 1 * _glowAnimation.value,
                    ),
                  ],
                ),
                child: iconWidget,
              );
            }

            return Transform.translate(
              offset: Offset(0, floatOffset),
              child: Transform.scale(
                scale: totalScale,
                child: iconWidget,
              ),
            );
          },
        ),
      ),
    );
  }
}
