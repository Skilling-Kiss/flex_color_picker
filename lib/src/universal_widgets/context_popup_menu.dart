import 'package:flutter/material.dart';

import '../functions/picker_functions.dart';

/// A context popup menu.
///
/// Wrap a child with [ContextPopupMenu] and provide it a list of
/// [PopupMenuEntry], typically it is a [PopupMenuItem] where each item have a
/// unique value. Often the [PopupMenuItem] has a child of type [ListTile], with
/// and int as value for its list index. The child can also be a custom widget
/// with any type of row content or even images, their values could be an
/// enum for its selection as well.
///
/// The popup menu with the provided entries will show up next to the long press
/// location on the child in a way that fits best on the screen and child.
///
/// The [onSelected] returns the associated value of the selected
/// [PopupMenuEntry]. If the menu is closed without selection, which happens
/// when user clicks outside it, null is returned. In all cases an [onSelected]
/// event also signals that the menu was closed.
///
/// The optional [onOpen] callback event is triggered when the menu is opened.
///
/// The menu can be styled with [PopupMenuThemeData] either via
/// Theme.of(context).PopupMenuThemeData globally for the app and all other
/// popup menus in it, or you can wrap just your custom popup widget that
/// composes its content using [ContextPopupMenu] with a [Theme] that defines
/// the [PopupMenuThemeData] just for that popup menu widget.
///
/// Not library exposed, private to the library.
@immutable
class ContextPopupMenu<T> extends StatefulWidget {
  /// Default const constructor.
  const ContextPopupMenu({
    Key? key,
    required this.items,
    required this.onSelected,
    this.onOpen,
    required this.child,
    this.useLongPress = false,
    this.useSecondaryTapDown = false,
    this.useSecondaryOnDesktopLongOnDevice = true,
  }) : super(key: key);

  /// The popup menu entries for the long press menu.
  final List<PopupMenuEntry<T>> items;

  /// ValueChanged callback with selected item in the long press menu.
  /// Is null if menu closed without selection by clicking outside the menu.
  final ValueChanged<T?> onSelected;

  /// Optional void callback, called when the long press menu is opened.
  /// A way to tell when a long press opened the menu.
  final VoidCallback? onOpen;

  /// The child that can be long pressed to activate the long press menu.
  final Widget child;

  /// Use long press to show context menu.
  ///
  /// Defaults to false.
  final bool useLongPress;

  /// Use secondary button tap down to show context menu.
  ///
  /// Secondary button is typically the right button on a mouse, but may in the
  /// host system be configured to be some other buttons as well, often by
  /// switching mouse right and left buttons.
  /// Defaults to false.
  final bool useSecondaryTapDown;

  /// Use secondary tap down on desktop and web, but long press on
  /// iOS/Android device.
  ///
  /// Secondary button is typically the right button on a mouse, but may in the
  /// host system be configured to be some other buttons as well, often by
  /// switching mouse right and left buttons.
  ///
  /// Defaults to true.
  final bool useSecondaryOnDesktopLongOnDevice;

  @override
  State<StatefulWidget> createState() => _ContextPopupMenuState<T>();
}

class _ContextPopupMenuState<T> extends State<ContextPopupMenu<T>> {
  Offset _downPosition = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    final TargetPlatform _platform = Theme.of(context).platform;
    final bool _useLongPress = widget.useLongPress ||
        (widget.useSecondaryOnDesktopLongOnDevice && !isDesktop(_platform));
    final bool _useSecondaryClick = widget.useSecondaryTapDown ||
        (widget.useSecondaryOnDesktopLongOnDevice && isDesktop(_platform));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: _useLongPress
          ? (LongPressStartDetails details) async {
              if (widget.onOpen != null) widget.onOpen!();
              _downPosition = details.globalPosition;
              await _showMenu(_downPosition);
            }
          : null,
      onSecondaryTapDown: _useSecondaryClick
          ? (TapDownDetails details) async {
              if (widget.onOpen != null) widget.onOpen!();
              _downPosition = details.globalPosition;
              await _showMenu(_downPosition);
            }
          : null,
      child: widget.child,
    );
  }

  Future<void> _showMenu(Offset position) async {
    if (widget.onOpen != null) widget.onOpen!();
    final RenderBox? overlay =
        Overlay.of(context)?.context.findRenderObject() as RenderBox?;
    if (overlay != null) {
      final T? value = await showMenu<T>(
        context: context,
        items: widget.items,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          overlay.size.width - position.dx,
          overlay.size.height - position.dy,
        ),
      );
      widget.onSelected(value);
    }
  }
}