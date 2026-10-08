import 'package:flutter/material.dart';

/// A Material 3 Card wrapping a [ListView.separated] with standard dividers.
///
/// Ensures consistent card styling, clipping, elevation, and divider appearance
/// across all listing views (Item Categories, Items, Members, Bills, etc.).
class AppSeparatedListCard extends StatelessWidget {
  const AppSeparatedListCard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.margin = EdgeInsets.zero,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
    this.elevation,
    this.physics,
    this.shrinkWrap = false,
    this.scrollController,
  });

  /// The number of items the list will build.
  final int itemCount;

  /// Called to build children for the list with an index in range `[0, itemCount)`.
  final NullableIndexedWidgetBuilder itemBuilder;

  /// Optional separator builder. Defaults to `const Divider(height: 1)`.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Outer margin around the card container.
  final EdgeInsetsGeometry margin;

  /// Internal padding for the scrollable list.
  final EdgeInsetsGeometry? padding;

  /// The content will be clipped (or not) according to this option.
  final Clip clipBehavior;

  /// Elevation of the card.
  final double? elevation;

  /// How the scroll view should respond to user input.
  final ScrollPhysics? physics;

  /// Whether the extent of the scroll view in the scrollDirection should be determined by the contents.
  final bool shrinkWrap;

  /// Controller for the internal scroll view.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      clipBehavior: clipBehavior,
      elevation: elevation,
      child: ListView.separated(
        controller: scrollController,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding ?? EdgeInsets.zero,
        itemCount: itemCount,
        separatorBuilder: separatorBuilder ??
            (context, index) => const Divider(height: 1),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
