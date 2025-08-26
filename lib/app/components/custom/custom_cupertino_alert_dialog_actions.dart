part of 'custom_cupertino_alert_dialog.dart';

class _CupertinoAlertActionSection extends StatefulWidget {
  const _CupertinoAlertActionSection({
    required this.children,
    this.scrollController,
  });

  final List<Widget> children;

  // A scroll controller that can be used to control the scrolling of the
  // actions in the dialog.
  //
  // Defaults to null, and is typically not needed, since most alert dialogs
  // don't have many actions.
  final ScrollController? scrollController;

  @override
  _CupertinoAlertActionSectionState createState() => _CupertinoAlertActionSectionState();
}

class _CupertinoAlertActionSectionState extends State<_CupertinoAlertActionSection> {
  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final List<Widget> interactiveButtons = <Widget>[];
    for (int i = 0; i < widget.children.length; i += 1) {
      interactiveButtons.add(
        _PressableActionButton(
          child: widget.children[i],
        ),
      );
    }

    return CupertinoScrollbar(
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: _CupertinoDialogActionsRenderWidget(
          actionButtons: interactiveButtons,
          dividerThickness: _kDividerThickness / devicePixelRatio,
        ),
      ),
    );
  }
}

// Button that updates its render state when pressed.
//
// The pressed state is forwarded to an _ActionButtonParentDataWidget. The
// corresponding _ActionButtonParentData is then interpreted and rendered
// appropriately by _RenderCupertinoDialogActions.
class _PressableActionButton extends StatefulWidget {
  const _PressableActionButton({
    required this.child,
  });

  final Widget child;

  @override
  _PressableActionButtonState createState() => _PressableActionButtonState();
}

class _PressableActionButtonState extends State<_PressableActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return _ActionButtonParentDataWidget(
      isPressed: _isPressed,
      child: MergeSemantics(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {
            setState(() => _isPressed = true);
          },
          onPointerUp: (_) {
            setState(() => _isPressed = false);
          },
          onPointerCancel: (_) {
            setState(() => _isPressed = false);
          },
          onPointerMove: (event) {
            final RenderBox box = context.findRenderObject()! as RenderBox;
            final Offset localPosition = box.globalToLocal(event.position);
            final bool inside = localPosition.dx >= 0 &&
                localPosition.dy >= 0 &&
                localPosition.dx <= box.size.width &&
                localPosition.dy <= box.size.height;
            if (inside != _isPressed) {
              setState(() => _isPressed = inside);
            }
          },
          child: widget.child,
        ),
      ),
    );
  }
}

// ParentDataWidget that updates _ActionButtonParentData for an action button.
//
// Each action button requires knowledge of whether or not it is pressed so that
// the dialog can correctly render the button. The pressed state is held within
// _ActionButtonParentData. _ActionButtonParentDataWidget is responsible for
// updating the pressed state of an _ActionButtonParentData based on the
// incoming [isPressed] property.
class _ActionButtonParentDataWidget extends ParentDataWidget<_ActionButtonParentData> {
  const _ActionButtonParentDataWidget({
    required this.isPressed,
    required super.child,
  });

  final bool isPressed;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is _ActionButtonParentData);
    final _ActionButtonParentData parentData = renderObject.parentData! as _ActionButtonParentData;
    if (parentData.isPressed != isPressed) {
      parentData.isPressed = isPressed;

      // Force a repaint.
      final RenderObject? targetParent = renderObject.parent;
      if (targetParent is RenderObject) {
        targetParent.markNeedsPaint();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _CupertinoDialogActionsRenderWidget;
}

// ParentData applied to individual action buttons that report whether or not
// that button is currently pressed by the user.
class _ActionButtonParentData extends MultiChildLayoutParentData {
  _ActionButtonParentData();

  bool isPressed = false;
}

/// A button typically used in a [CupertinoAlertDialog].
///
/// See also:
///
///  * [CupertinoAlertDialog], a dialog that informs the user about situations
///    that require acknowledgement.
class CupertinoDialogAction extends StatelessWidget {
  /// Creates an action for an iOS-style dialog.
  const CupertinoDialogAction({
    super.key,
    this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.textStyle,
    required this.child,
  });

  /// The callback that is called when the button is tapped or otherwise
  /// activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback? onPressed;

  /// Set to true if button is the default choice in the dialog.
  ///
  /// Default buttons have bold text. Similar to
  /// [UIAlertController.preferredAction](https://developer.apple.com/documentation/uikit/uialertcontroller/1620102-preferredaction),
  /// but more than one action can have this attribute set to true in the same
  /// [CupertinoAlertDialog].
  ///
  /// This parameters defaults to false and cannot be null.
  final bool isDefaultAction;

  /// Whether this action destroys an object.
  ///
  /// For example, an action that deletes an email is destructive.
  ///
  /// Defaults to false and cannot be null.
  final bool isDestructiveAction;

  /// [TextStyle] to apply to any text that appears in this button.
  ///
  /// Dialog actions have a built-in text resizing policy for long text. To
  /// ensure that this resizing policy always works as expected, [textStyle]
  /// must be used if a text size is desired other than that specified in
  /// [kCupertinoDialogActionStyle].
  final TextStyle? textStyle;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  /// Whether the button is enabled or disabled. Buttons are disabled by
  /// default. To enable a button, set its [onPressed] property to a non-null
  /// value.
  bool get enabled => onPressed != null;

  double _calculatePadding(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(8.0);
  }

  // Dialog action content shrinks to fit, up to a certain point, and if it still
  // cannot fit at the minimum size, the text content is ellipsized.
  //
  // This policy only applies when the device is not in accessibility mode.
  Widget _buildContentWithRegularSizingPolicy({
    required BuildContext context,
    required TextStyle textStyle,
    required Widget content,
  }) {
    final bool isInAccessibilityMode = _isInAccessibilityMode(context);
    final double dialogWidth = isInAccessibilityMode ? _kAccessibilityCupertinoDialogWidth : _kCupertinoDialogWidth;
    // The fontSizeRatio is the ratio of the current text size (including any
    // iOS scale factor) vs the minimum text size that we allow in action
    // buttons. This ratio information is used to automatically scale down action
    // button text to fit the available space.
    final double fontSizeRatio = MediaQuery.of(context).textScaler.scale(textStyle.fontSize!) / _kMinButtonFontSize;
    final double padding = _calculatePadding(context);

    bool shouldWrap = false;
    if (content is Text) {
      final String? data = content.data ?? content.textSpan?.toPlainText();
      if (data != null && !data.contains(' ')) {
        shouldWrap = true;
      }
    }

    return IntrinsicHeight(
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: fontSizeRatio * (dialogWidth - (2 * padding)),
            ),
            child: Semantics(
              button: true,
              onTap: onPressed,
              child: DefaultTextStyle(
                style: textStyle,
                textAlign: TextAlign.center,
                overflow: shouldWrap ? TextOverflow.visible : TextOverflow.ellipsis,
                softWrap: shouldWrap,
                maxLines: shouldWrap ? null : 1,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dialog action content is permitted to be as large as it wants when in
  // accessibility mode. If text is used as the content, the text wraps instead
  // of ellipsizing.
  Widget _buildContentWithAccessibilitySizingPolicy({
    required TextStyle textStyle,
    required Widget content,
  }) {
    return DefaultTextStyle(
      style: textStyle,
      textAlign: TextAlign.center,
      overflow: TextOverflow.visible,
      softWrap: true,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = kCupertinoDialogActionStyle.copyWith(
      color: CupertinoDynamicColor.resolve(
        isDestructiveAction ? CupertinoColors.systemRed : CupertinoColors.systemBlue,
        context,
      ),
    );
    style = style.merge(textStyle);

    if (isDefaultAction) {
      style = style.copyWith(fontWeight: FontWeight.w600);
    }

    if (!enabled) {
      style = style.copyWith(color: style.color!.withOpacity(0.5));
    }

    // Apply a sizing policy to the action button's content based on whether or
    // not the device is in accessibility mode.
    final Widget sizedContent = _isInAccessibilityMode(context)
        ? _buildContentWithAccessibilitySizingPolicy(
            textStyle: style,
            content: child,
          )
        : _buildContentWithRegularSizingPolicy(
            context: context,
            textStyle: style,
            content: child,
          );

    return GestureDetector(
      excludeFromSemantics: true,
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _kMinButtonHeight,
        ),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(_calculatePadding(context)),
          child: sizedContent,
        ),
      ),
    );
  }
}

// iOS style dialog action button layout.
//
// [_CupertinoDialogActionsRenderWidget] does not provide any scrolling
// behavior for its buttons. It only handles the sizing and layout of buttons.
// Scrolling behavior can be composed on top of this widget, if desired.
//
// See [_RenderCupertinoDialogActions] for specific layout policy details.
class _CupertinoDialogActionsRenderWidget extends MultiChildRenderObjectWidget {
  _CupertinoDialogActionsRenderWidget({
    required List<Widget> actionButtons,
    double dividerThickness = 0.0,
  })  : _dividerThickness = dividerThickness,
        super(children: actionButtons);

  final double _dividerThickness;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCupertinoDialogActions(
      dialogWidth: _isInAccessibilityMode(context) ? _kAccessibilityCupertinoDialogWidth : _kCupertinoDialogWidth,
      dividerThickness: _dividerThickness,
      dialogColor: CupertinoDynamicColor.resolve(_kDialogColor, context),
      dialogPressedColor: CupertinoDynamicColor.resolve(_kDialogPressedColor, context),
      dividerColor: CupertinoDynamicColor.resolve(CupertinoColors.separator, context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCupertinoDialogActions renderObject) {
    renderObject
      ..dialogWidth = _isInAccessibilityMode(context) ? _kAccessibilityCupertinoDialogWidth : _kCupertinoDialogWidth
      ..dividerThickness = _dividerThickness
      ..dialogColor = CupertinoDynamicColor.resolve(_kDialogColor, context)
      ..dialogPressedColor = CupertinoDynamicColor.resolve(_kDialogPressedColor, context)
      ..dividerColor = CupertinoDynamicColor.resolve(CupertinoColors.separator, context);
  }
}

// iOS style layout policy for sizing and positioning an alert dialog's action
// buttons.
//
// The policy is as follows:
//
// If a single action button is provided, or if 2 action buttons are provided
// that can fit side-by-side, then action buttons are sized and laid out in a
// single horizontal row. The row is exactly as wide as the dialog, and the row
// is as tall as the tallest action button. A horizontal divider is drawn above
// the button row. If 2 action buttons are provided, a vertical divider is
// drawn between them. The thickness of the divider is set by [dividerThickness].
//
// If 2 action buttons are provided but they cannot fit side-by-side, then the
// 2 buttons are stacked vertically. A horizontal divider is drawn above each
// button. The thickness of the divider is set by [dividerThickness]. The minimum
// height of this [RenderBox] in the case of 2 stacked buttons is as tall as
// the 2 buttons stacked. This is different than the 3+ button case where the
// minimum height is only 1.5 buttons tall. See the 3+ button explanation for
// more info.
//
// If 3+ action buttons are provided then they are all stacked vertically. A
// horizontal divider is drawn above each button. The thickness of the divider
// is set by [dividerThickness]. The minimum height of this [RenderBox] in the case
// of 3+ stacked buttons is as tall as the 1st button + 50% the height of the
// 2nd button. In other words, the minimum height is 1.5 buttons tall. This
// minimum height of 1.5 buttons is expected to work in tandem with a surrounding
// [ScrollView] to match the iOS dialog behavior.
//
// Each button is expected to have an _ActionButtonParentData which reports
// whether or not that button is currently pressed. If a button is pressed,
// then the dividers above and below that pressed button are not drawn - instead
// they are filled with the standard white dialog background color. The one
// exception is the very 1st divider which is always rendered. This policy comes
// from observation of native iOS dialogs.
class _RenderCupertinoDialogActions extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderCupertinoDialogActions({
    List<RenderBox>? children,
    required double dialogWidth,
    double dividerThickness = 0.0,
    required Color dialogColor,
    required Color dialogPressedColor,
    required Color dividerColor,
  })  : _dialogWidth = dialogWidth,
        _buttonBackgroundPaint = Paint()
          ..color = dialogColor
          ..style = PaintingStyle.fill,
        _pressedButtonBackgroundPaint = Paint()
          ..color = dialogPressedColor
          ..style = PaintingStyle.fill,
        _dividerPaint = Paint()
          ..color = dividerColor
          ..style = PaintingStyle.fill,
        _dividerThickness = dividerThickness {
    addAll(children);
  }

  double get dialogWidth => _dialogWidth;
  double _dialogWidth;

  set dialogWidth(double newWidth) {
    if (newWidth != _dialogWidth) {
      _dialogWidth = newWidth;
      markNeedsLayout();
    }
  }

  // The thickness of the divider between buttons.
  double get dividerThickness => _dividerThickness;
  double _dividerThickness;

  set dividerThickness(double newValue) {
    if (newValue != _dividerThickness) {
      _dividerThickness = newValue;
      markNeedsLayout();
    }
  }

  final Paint _buttonBackgroundPaint;

  set dialogColor(Color value) {
    if (value == _buttonBackgroundPaint.color) {
      return;
    }

    _buttonBackgroundPaint.color = value;
    markNeedsPaint();
  }

  final Paint _pressedButtonBackgroundPaint;

  set dialogPressedColor(Color value) {
    if (value == _pressedButtonBackgroundPaint.color) {
      return;
    }

    _pressedButtonBackgroundPaint.color = value;
    markNeedsPaint();
  }

  final Paint _dividerPaint;

  set dividerColor(Color value) {
    if (value == _dividerPaint.color) {
      return;
    }

    _dividerPaint.color = value;
    markNeedsPaint();
  }

  Iterable<RenderBox> get _pressedButtons sync* {
    RenderBox? currentChild = firstChild;
    while (currentChild != null) {
      assert(currentChild.parentData is _ActionButtonParentData);
      final _ActionButtonParentData parentData = currentChild.parentData! as _ActionButtonParentData;
      if (parentData.isPressed) {
        yield currentChild;
      }
      currentChild = childAfter(currentChild);
    }
  }

  bool get _isButtonPressed {
    RenderBox? currentChild = firstChild;
    while (currentChild != null) {
      assert(currentChild.parentData is _ActionButtonParentData);
      final _ActionButtonParentData parentData = currentChild.parentData! as _ActionButtonParentData;
      if (parentData.isPressed) {
        return true;
      }
      currentChild = childAfter(currentChild);
    }
    return false;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionButtonParentData) {
      child.parentData = _ActionButtonParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return dialogWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return dialogWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double minHeight;
    if (childCount == 0) {
      minHeight = 0.0;
    } else if (childCount == 1) {
      // If only 1 button, display the button across the entire dialog.
      minHeight = _computeMinIntrinsicHeightSideBySide(width);
    } else {
      if (childCount == 2 && _isSingleButtonRow(width)) {
        // The first 2 buttons fit side-by-side. Display them horizontally.
        minHeight = _computeMinIntrinsicHeightSideBySide(width);
      } else {
        // 3+ buttons are always stacked. The minimum height when stacked is
        // 1.5 buttons tall.
        minHeight = _computeMinIntrinsicHeightStacked(width);
      }
    }
    return minHeight;
  }

  // The minimum height for a single row of buttons is the larger of the buttons'
  // min intrinsic heights.
  double _computeMinIntrinsicHeightSideBySide(double width) {
    assert(childCount >= 1 && childCount <= 2);

    final double minHeight;
    if (childCount == 1) {
      minHeight = firstChild!.getMinIntrinsicHeight(width);
    } else {
      final double perButtonWidth = (width - dividerThickness) / 2.0;
      minHeight = math.max(
        firstChild!.getMinIntrinsicHeight(perButtonWidth),
        lastChild!.getMinIntrinsicHeight(perButtonWidth),
      );
    }
    return minHeight;
  }

  // The minimum height for 2+ stacked buttons is the height of the 1st button
  // + 50% the height of the 2nd button + the divider between the two.
  double _computeMinIntrinsicHeightStacked(double width) {
    assert(childCount >= 2);

    return firstChild!.getMinIntrinsicHeight(width) +
        dividerThickness +
        (0.5 * childAfter(firstChild!)!.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double maxHeight;
    if (childCount == 0) {
      // No buttons. Zero height.
      maxHeight = 0.0;
    } else if (childCount == 1) {
      // One button. Our max intrinsic height is equal to the button's.
      maxHeight = firstChild!.getMaxIntrinsicHeight(width);
    } else if (childCount == 2) {
      // Two buttons...
      if (_isSingleButtonRow(width)) {
        // The 2 buttons fit side by side so our max intrinsic height is equal
        // to the taller of the 2 buttons.
        final double perButtonWidth = (width - dividerThickness) / 2.0;
        maxHeight = math.max(
          firstChild!.getMaxIntrinsicHeight(perButtonWidth),
          lastChild!.getMaxIntrinsicHeight(perButtonWidth),
        );
      } else {
        // The 2 buttons do not fit side by side. Measure total height as a
        // vertical stack.
        maxHeight = _computeMaxIntrinsicHeightStacked(width);
      }
    } else {
      // Three+ buttons. Stack the buttons vertically with dividers and measure
      // the overall height.
      maxHeight = _computeMaxIntrinsicHeightStacked(width);
    }
    return maxHeight;
  }

  // Max height of a stack of buttons is the sum of all button heights + a
  // divider for each button.
  double _computeMaxIntrinsicHeightStacked(double width) {
    assert(childCount >= 2);

    final double allDividersHeight = (childCount - 1) * dividerThickness;
    double heightAccumulation = allDividersHeight;
    RenderBox? button = firstChild;
    while (button != null) {
      heightAccumulation += button.getMaxIntrinsicHeight(width);
      button = childAfter(button);
    }
    return heightAccumulation;
  }

  bool _isSingleButtonRow(double width) {
    final bool isSingleButtonRow;
    if (childCount == 1) {
      isSingleButtonRow = true;
    } else if (childCount == 2) {
      // There are 2 buttons. If they can fit side-by-side then that's what
      // we want to do. Otherwise, stack them vertically.
      final double sideBySideWidth = firstChild!.getMaxIntrinsicWidth(double.infinity) +
          dividerThickness +
          lastChild!.getMaxIntrinsicWidth(double.infinity);
      isSingleButtonRow = sideBySideWidth <= width;
    } else {
      isSingleButtonRow = false;
    }
    return isSingleButtonRow;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _computeLayout(constraints: constraints, dry: true);
  }

  @override
  void performLayout() {
    size = _computeLayout(constraints: constraints, dry: false);
  }

  Size _computeLayout({required BoxConstraints constraints, bool dry = false}) {
    final ChildLayouter layoutChild = dry ? ChildLayoutHelper.dryLayoutChild : ChildLayoutHelper.layoutChild;

    if (_isSingleButtonRow(dialogWidth)) {
      if (childCount == 1) {
        // We have 1 button. Our size is the width of the dialog and the height
        // of the single button.
        final Size childSize = layoutChild(
          firstChild!,
          constraints,
        );

        return constraints.constrain(
          Size(dialogWidth, childSize.height),
        );
      } else {
        // Each button gets half the available width, minus a single divider.
        final BoxConstraints perButtonConstraints = BoxConstraints(
          minWidth: (constraints.minWidth - dividerThickness) / 2.0,
          maxWidth: (constraints.maxWidth - dividerThickness) / 2.0,
          minHeight: 0.0,
          maxHeight: double.infinity,
        );

        // Layout the 2 buttons.
        final Size firstChildSize = layoutChild(
          firstChild!,
          perButtonConstraints,
        );
        final Size lastChildSize = layoutChild(
          lastChild!,
          perButtonConstraints,
        );

        if (!dry) {
          // The 2nd button needs to be offset to the right.
          assert(lastChild!.parentData is MultiChildLayoutParentData);
          final MultiChildLayoutParentData secondButtonParentData =
              lastChild!.parentData! as MultiChildLayoutParentData;
          secondButtonParentData.offset = Offset(firstChildSize.width + dividerThickness, 0.0);
        }

        // Calculate our size based on the button sizes.
        return constraints.constrain(
          Size(
            dialogWidth,
            math.max(
              firstChildSize.height,
              lastChildSize.height,
            ),
          ),
        );
      }
    } else {
      // We need to stack buttons vertically, plus dividers above each button (except the 1st).
      final BoxConstraints perButtonConstraints = constraints.copyWith(
        minHeight: 0.0,
        maxHeight: double.infinity,
      );

      RenderBox? child = firstChild;
      int index = 0;
      double verticalOffset = 0.0;
      while (child != null) {
        final Size childSize = layoutChild(
          child,
          perButtonConstraints,
        );

        if (!dry) {
          assert(child.parentData is MultiChildLayoutParentData);
          final MultiChildLayoutParentData parentData = child.parentData! as MultiChildLayoutParentData;
          parentData.offset = Offset(0.0, verticalOffset);
        }
        verticalOffset += childSize.height;
        if (index < childCount - 1) {
          // Add a gap for the next divider.
          verticalOffset += dividerThickness;
        }

        index += 1;
        child = childAfter(child);
      }

      // Our height is the accumulated height of all buttons and dividers.
      return constraints.constrain(
        Size(dialogWidth, verticalOffset),
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    if (_isSingleButtonRow(size.width)) {
      _drawButtonBackgroundsAndDividersSingleRow(canvas, offset);
    } else {
      _drawButtonBackgroundsAndDividersStacked(canvas, offset);
    }

    _drawButtons(context, offset);
  }

  void _drawButtonBackgroundsAndDividersSingleRow(Canvas canvas, Offset offset) {
    // The vertical divider sits between the left button and right button (if
    // the dialog has 2 buttons).  The vertical divider is hidden if either the
    // left or right button is pressed.
    final Rect verticalDivider = childCount == 2 && !_isButtonPressed
        ? Rect.fromLTWH(
            offset.dx + firstChild!.size.width,
            offset.dy,
            dividerThickness,
            math.max(
              firstChild!.size.height,
              lastChild!.size.height,
            ),
          )
        : Rect.zero;

    final List<Rect> pressedButtonRects = _pressedButtons.map<Rect>((RenderBox pressedButton) {
      final MultiChildLayoutParentData buttonParentData = pressedButton.parentData! as MultiChildLayoutParentData;

      return Rect.fromLTWH(
        offset.dx + buttonParentData.offset.dx,
        offset.dy + buttonParentData.offset.dy,
        pressedButton.size.width,
        pressedButton.size.height,
      );
    }).toList();

    // Create the button backgrounds path and paint it.
    final Path backgroundFillPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..addRect(verticalDivider);

    for (int i = 0; i < pressedButtonRects.length; i += 1) {
      backgroundFillPath.addRect(pressedButtonRects[i]);
    }

    canvas.drawPath(
      backgroundFillPath,
      _buttonBackgroundPaint,
    );

    // Create the pressed buttons background path and paint it.
    final Path pressedBackgroundFillPath = Path();
    for (int i = 0; i < pressedButtonRects.length; i += 1) {
      pressedBackgroundFillPath.addRect(pressedButtonRects[i]);
    }

    canvas.drawPath(
      pressedBackgroundFillPath,
      _pressedButtonBackgroundPaint,
    );

    // Create the dividers path and paint it.
    final Path dividersPath = Path()..addRect(verticalDivider);

    canvas.drawPath(
      dividersPath,
      _dividerPaint,
    );
  }

  void _drawButtonBackgroundsAndDividersStacked(Canvas canvas, Offset offset) {
    final Offset dividerOffset = Offset(0.0, dividerThickness);

    final Path backgroundFillPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height));

    final Path pressedBackgroundFillPath = Path();

    final Path dividersPath = Path();

    Offset accumulatingOffset = offset;

    RenderBox? child = firstChild;
    RenderBox? prevChild;
    while (child != null) {
      assert(child.parentData is _ActionButtonParentData);
      final _ActionButtonParentData currentButtonParentData = child.parentData! as _ActionButtonParentData;
      final bool isButtonPressed = currentButtonParentData.isPressed;

      bool isPrevButtonPressed = false;
      if (prevChild != null) {
        assert(prevChild.parentData is _ActionButtonParentData);
        final _ActionButtonParentData previousButtonParentData = prevChild.parentData! as _ActionButtonParentData;
        isPrevButtonPressed = previousButtonParentData.isPressed;
      }

      final bool isDividerPresent = child != firstChild;
      final bool isDividerPainted = isDividerPresent && !(isButtonPressed || isPrevButtonPressed);
      final Rect dividerRect = Rect.fromLTWH(
        accumulatingOffset.dx,
        accumulatingOffset.dy,
        size.width,
        dividerThickness,
      );

      final Rect buttonBackgroundRect = Rect.fromLTWH(
        accumulatingOffset.dx,
        accumulatingOffset.dy + (isDividerPresent ? dividerThickness : 0.0),
        size.width,
        child.size.height,
      );

      // If this button is pressed, then we don't want a white background to be
      // painted, so we erase this button from the background path.
      if (isButtonPressed) {
        backgroundFillPath.addRect(buttonBackgroundRect);
        pressedBackgroundFillPath.addRect(buttonBackgroundRect);
      }

      // If this divider is needed, then we erase the divider area from the
      // background path, and on top of that we paint a translucent gray to
      // darken the divider area.
      if (isDividerPainted) {
        backgroundFillPath.addRect(dividerRect);
        dividersPath.addRect(dividerRect);
      }

      accumulatingOffset += (isDividerPresent ? dividerOffset : Offset.zero) + Offset(0.0, child.size.height);

      prevChild = child;
      child = childAfter(child);
    }

    canvas.drawPath(backgroundFillPath, _buttonBackgroundPaint);
    canvas.drawPath(pressedBackgroundFillPath, _pressedButtonBackgroundPaint);
    canvas.drawPath(dividersPath, _dividerPaint);
  }

  void _drawButtons(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final MultiChildLayoutParentData childParentData = child.parentData! as MultiChildLayoutParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childAfter(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
