import 'dart:ui';

import 'package:flutter/material.dart';

const Duration kGlassLiftEnterDuration = Duration(milliseconds: 240);
const Duration kGlassLiftExitDuration = Duration(milliseconds: 160);
const Duration kGlassLiftHoverDuration = Duration(milliseconds: 150);

/// Inherited route animation for inner title/body/actions stagger.
class AppGlassLiftScope extends InheritedWidget {
  const AppGlassLiftScope({
    super.key,
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppGlassLiftScope>()
        ?.animation;
  }

  @override
  bool updateShouldNotify(AppGlassLiftScope oldWidget) =>
      animation != oldWidget.animation;
}

/// Frosted, lifted dialog chrome. Glass on the card; content stays opaque.
class AppGlassLiftShell extends StatelessWidget {
  const AppGlassLiftShell({
    super.key,
    this.header,
    required this.body,
    this.actions,
    this.width,
    this.maxWidth = 560,
  });

  final Widget? header;
  final Widget body;
  final Widget? actions;
  final double? width;
  final double maxWidth;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final animation = AppGlassLiftScope.maybeOf(context);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.10),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer.withValues(alpha: 0.88),
              borderRadius: _radius,
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header != null)
                  _StaggerSlot(
                    animation: animation,
                    reduceMotion: reduce,
                    interval: const Interval(0.0, 0.55, curve: Curves.easeOut),
                    child: header!,
                  ),
                _StaggerSlot(
                  animation: animation,
                  reduceMotion: reduce,
                  interval: const Interval(0.18, 0.75, curve: Curves.easeOut),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                    ),
                    child: body,
                  ),
                ),
                if (actions != null)
                  _StaggerSlot(
                    animation: animation,
                    reduceMotion: reduce,
                    interval: const Interval(0.36, 1.0, curve: Curves.easeOut),
                    child: actions!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _radius,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.22),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        card,
      ],
    );

    final sized = width != null
        ? SizedBox(width: width, child: stack)
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: stack,
          );

    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: sized,
      ),
    );
  }
}

/// Lifts [child] 2px on pointer hover. Used on primary dialog actions.
class AppHoverLift extends StatefulWidget {
  const AppHoverLift({super.key, required this.child});

  final Widget child;

  @override
  State<AppHoverLift> createState() => _AppHoverLiftState();
}

class _AppHoverLiftState extends State<AppHoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final dy = (!reduce && _hover) ? -2.0 : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: dy),
        duration: reduce ? Duration.zero : kGlassLiftHoverDuration,
        curve: Curves.easeOut,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Glass-lift route: scale + fade + translate. Barrier is dim only.
Future<T?> showAppGlassLiftDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  final capturedThemes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: useRootNavigator).context,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    _GlassLiftDialogRoute<T>(
      exitDuration: reduce ? Duration.zero : kGlassLiftExitDuration,
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return capturedThemes.wrap(
          AppGlassLiftScope(
            animation: animation,
            child: builder(ctx),
          ),
        );
      },
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.36),
      transitionDuration: reduce ? Duration.zero : kGlassLiftEnterDuration,
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        if (reduce) {
          return FadeTransition(opacity: animation, child: child);
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: AnimatedBuilder(
            animation: curved,
            builder: (context, framed) => Transform.translate(
              offset: Offset(0, 12 * (1 - curved.value)),
              child: Transform.scale(
                scale: 0.94 + (0.06 * curved.value),
                child: framed,
              ),
            ),
            child: child,
          ),
        );
      },
    ),
  );
}

class _GlassLiftDialogRoute<T> extends RawDialogRoute<T> {
  _GlassLiftDialogRoute({
    required this.exitDuration,
    required super.pageBuilder,
    super.barrierDismissible,
    super.barrierLabel,
    super.barrierColor,
    super.transitionDuration,
    super.transitionBuilder,
  });

  final Duration exitDuration;

  @override
  Duration get reverseTransitionDuration => exitDuration;
}

class _StaggerSlot extends StatelessWidget {
  const _StaggerSlot({
    required this.animation,
    required this.reduceMotion,
    required this.interval,
    required this.child,
  });

  final Animation<double>? animation;
  final bool reduceMotion;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = animation;
    if (parent == null || reduceMotion) {
      return child;
    }
    final curved = CurvedAnimation(parent: parent, curve: interval);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, framed) => Transform.translate(
          offset: Offset(0, 8 * (1 - curved.value)),
          child: framed,
        ),
        child: child,
      ),
    );
  }
}
