import 'package:flutter/material.dart';
import 'measure_size.dart';

class AnchorToolTip extends StatefulWidget{
  final GetPosition? position;
  final Offset? offset;
  final Size? screenSize;

  final Color? tooltipColor;
  final bool showArrow;
  final double? contentHeight;
  final double? contentWidth;
  final VoidCallback? onTooltipTap;
  final EdgeInsets? contentPadding;
  final Duration animationDuration;
  final bool disableAnimation;
  final Column? bodyColumn;
  final BorderRadius? borderRadius;

  AnchorToolTip({
    required this.position,
    required this.offset,
    required this.screenSize,
    required this.bodyColumn,
    required this.tooltipColor,
    required this.showArrow,
    required this.contentHeight,
    required this.contentWidth,
    required this.onTooltipTap,
    required this.animationDuration,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 8),
    required this.disableAnimation,
    required this.borderRadius,
  });

  @override
  _ToolTipWidgetState createState() => _ToolTipWidgetState();
}

class _ToolTipWidgetState extends State<AnchorToolTip>
    with SingleTickerProviderStateMixin {
  Offset? position;

  bool isArrowUp = false;

  late final AnimationController _parentController;
  late final Animation<double> _curvedAnimation;

  bool isCloseToTopOrBottom(Offset position) {
    var height = 120.0;
    height = widget.contentHeight ?? height;
    final bottomPosition =
        position.dy + ((widget.position?.getHeight() ?? 0) / 2);
    final topPosition = position.dy - ((widget.position?.getHeight() ?? 0) / 2);
    return ((widget.screenSize?.height ?? MediaQuery.of(context).size.height) -
        bottomPosition) <=
        height &&
        topPosition >= height;
  }

  String findPositionForContent(Offset position) {
    if (isCloseToTopOrBottom(position)) {
      return 'ABOVE';
    } else {
      return 'BELOW';
    }
  }

  double _getTooltipWidth() {
    final bodyLength = MediaQuery.of(context).size.width - 40;
    if (bodyLength > widget.screenSize!.width - 20) {
      return widget.screenSize!.width - 20;
    } else {
      return bodyLength + 15;
    }
  }

  bool _isLeft() {
    final screenWidth = widget.screenSize!.width / 3;
    return !(screenWidth <= widget.position!.getCenter());
  }

  bool _isRight() {
    final screenWidth = widget.screenSize!.width / 3;
    return ((screenWidth * 2) <= widget.position!.getCenter());
  }

  double? _getLeft() {
    if (_isLeft()) {
      var leftPadding =
          widget.position!.getCenter() - (_getTooltipWidth() * 0.1);
      if (leftPadding + _getTooltipWidth() > widget.screenSize!.width) {
        leftPadding = (widget.screenSize!.width - 20) - _getTooltipWidth();
      }
      if (leftPadding < 20) {
        leftPadding = 14;
      }
      return leftPadding;
    } else if (!(_isRight())) {
      return widget.position!.getCenter() - (_getTooltipWidth() * 0.5);
    } else {
      return null;
    }
  }

  double? _getRight() {
    if (_isRight()) {
      var rightPadding =
          widget.position!.getCenter() + (_getTooltipWidth() / 2);
      if (rightPadding + _getTooltipWidth() > widget.screenSize!.width) {
        rightPadding = 14;
      }
      return rightPadding;
    } else if (!(_isLeft())) {
      return widget.position!.getCenter() - (_getTooltipWidth() * 0.5);
    } else {
      return null;
    }
  }

  double _getSpace() {
    var space = widget.position!.getCenter() - (widget.contentWidth! / 2);
    if (space + widget.contentWidth! > widget.screenSize!.width) {
      space = widget.screenSize!.width - widget.contentWidth! - 8;
    } else if (space < (widget.contentWidth! / 2)) {
      space = 16;
    }
    return space;
  }

  @override
  void initState() {
    super.initState();
    _parentController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _parentController.reverse();
      }
      if (_parentController.isDismissed) {
        if (!widget.disableAnimation) {
          _parentController.forward();
        }
      }
    });

    _curvedAnimation = CurvedAnimation(
      parent: _parentController,
      curve: Curves.easeInOut,
    );

    if (!widget.disableAnimation) {
      _parentController.forward();
    }
  }

  @override
  void dispose() {
    _parentController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    position = widget.offset;
    final contentOrientation = findPositionForContent(position!);
    final contentOffsetMultiplier = contentOrientation == "BELOW" ? 1.0 : -1.0;
    isArrowUp = contentOffsetMultiplier == 1.0;

    final contentY = isArrowUp
        ? widget.position!.getBottom() + (contentOffsetMultiplier * 3)
        : widget.position!.getTop() + (contentOffsetMultiplier * 3);

    final num contentFractionalOffset =
    contentOffsetMultiplier.clamp(-1.0, 0.0);

    var paddingTop = isArrowUp ? 22.0 : 0.0;
    var paddingBottom = isArrowUp ? 0.0 : 27.0;

    if (!widget.showArrow) {
      paddingTop = 10;
      paddingBottom = 10;
    }

    final arrowWidth = 18.0;
    final arrowHeight = 9.0;

    if (widget.bodyColumn == null) {
      return Positioned(
        top: contentY,
        left: _getLeft(),
        right: _getRight(),
        child: FractionalTranslation(
          translation: Offset(0.0, contentFractionalOffset as double),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, contentFractionalOffset / 10),
              end: Offset(0.0, 0.100),
            ).animate(_curvedAnimation),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: widget.showArrow
                    ? EdgeInsets.only(
                  top: paddingTop - (isArrowUp ? arrowHeight : 0),
                  bottom: paddingBottom - (isArrowUp ? 0 : arrowHeight),
                )
                    : null,
                child: Stack(
                  alignment: isArrowUp
                      ? Alignment.topLeft
                      : _getLeft() == null
                      ? Alignment.bottomRight
                      : Alignment.bottomLeft,
                  children: [
                    if (widget.showArrow)
                      Positioned(
                        left: _getLeft() == null
                            ? null
                            : (widget.position!.getCenter() -
                            (arrowWidth / 2) -
                            (_getLeft() ?? 0)),
                        right: _getLeft() == null
                            ? (MediaQuery.of(context).size.width -
                            widget.position!.getCenter()) -
                            (_getRight() ?? 0) -
                            (arrowWidth / 2)
                            : null,
                        child: CustomPaint(
                          painter: _Arrow(
                            strokeColor: widget.tooltipColor!,
                            strokeWidth: 10,
                            paintingStyle: PaintingStyle.fill,
                            isUpArrow: isArrowUp,
                          ),
                          child: SizedBox(
                            height: arrowHeight,
                            width: arrowWidth,
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: isArrowUp ? arrowHeight - 1 : 0,
                        bottom: isArrowUp ? 0 : arrowHeight - 1,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GestureDetector(
                          onTap: widget.onTooltipTap,
                          child: Container(
                            width: _getTooltipWidth(),
                            padding: widget.contentPadding,
                            color: widget.tooltipColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                widget.bodyColumn ?? SizedBox.shrink()
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Stack(
        children: <Widget>[
          Positioned(
            left: _getSpace(),
            top: contentY - 10,
            child: FractionalTranslation(
              translation: Offset(0.0, contentFractionalOffset as double),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0.0, contentFractionalOffset / 10),
                  end: !widget.showArrow && !isArrowUp
                      ? Offset(0.0, 0.0)
                      : Offset(0.0, 0.100),
                ).animate(_curvedAnimation),
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: widget.onTooltipTap,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: paddingTop,
                      ),
                      color: Colors.transparent,
                      child: Center(
                        child: MeasureSize(
                            onSizeChange: (size) {
                              setState(() {
                                var tempPos = position;
                                tempPos = Offset(
                                    position!.dx, position!.dy + size!.height);
                                position = tempPos;
                              });
                            },
                            child: const SizedBox.shrink()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}

class _Arrow extends CustomPainter {
  final Color strokeColor;
  final PaintingStyle paintingStyle;
  final double strokeWidth;
  final bool isUpArrow;

  _Arrow(
      {this.strokeColor = Colors.black,
        this.strokeWidth = 3,
        this.paintingStyle = PaintingStyle.stroke,
        this.isUpArrow = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = paintingStyle;

    canvas.drawPath(getTrianglePath(size.width, size.height), paint);
  }

  Path getTrianglePath(double x, double y) {
    if (isUpArrow) {
      return Path()
        ..moveTo(0, y)
        ..lineTo(x / 2, 0)
        ..lineTo(x, y)
        ..lineTo(0, y);
    } else {
      return Path()
        ..moveTo(0, 0)
        ..lineTo(x, 0)
        ..lineTo(x / 2, y)
        ..lineTo(0, 0);
    }
  }

  @override
  bool shouldRepaint(_Arrow oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.paintingStyle != paintingStyle ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class GetPosition {
  final GlobalKey? key;
  final EdgeInsets padding;
  final double? screenWidth;
  final double? screenHeight;

  GetPosition(
      {this.key,
        this.padding = EdgeInsets.zero,
        this.screenWidth,
        this.screenHeight});

  Rect getRect() {
    final box = key!.currentContext!.findRenderObject() as RenderBox;

    var boxOffset = box.localToGlobal(const Offset(0.0, 0.0));
    if (boxOffset.dx.isNaN || boxOffset.dy.isNaN) {
      return Rect.fromLTRB(0, 0, 0, 0);
    }
    final topLeft = box.size.topLeft(boxOffset);
    final bottomRight = box.size.bottomRight(boxOffset);

    final rect = Rect.fromLTRB(
      topLeft.dx - padding.left < 0 ? 0 : topLeft.dx - padding.left,
      topLeft.dy - padding.top < 0 ? 0 : topLeft.dy - padding.top,
      bottomRight.dx + padding.right > screenWidth!
          ? screenWidth!
          : bottomRight.dx + padding.right,
      bottomRight.dy + padding.bottom > screenHeight!
          ? screenHeight!
          : bottomRight.dy + padding.bottom,
    );
    return rect;
  }

  ///Get the bottom position of the widget
  double getBottom() {
    final box = key!.currentContext!.findRenderObject() as RenderBox;
    final boxOffset = box.localToGlobal(const Offset(0.0, 0.0));
    if (boxOffset.dy.isNaN) return padding.bottom;
    final bottomRight = box.size.bottomRight(boxOffset);
    return bottomRight.dy + padding.bottom;
  }

  ///Get the top position of the widget
  double getTop() {
    final box = key!.currentContext!.findRenderObject() as RenderBox;
    final boxOffset = box.localToGlobal(const Offset(0.0, 0.0));
    if (boxOffset.dy.isNaN) return 0 - padding.top;
    final topLeft = box.size.topLeft(boxOffset);
    return topLeft.dy - padding.top;
  }

  ///Get the left position of the widget
  double getLeft() {
    final box = key!.currentContext!.findRenderObject() as RenderBox;
    final boxOffset = box.localToGlobal(const Offset(0.0, 0.0));
    if (boxOffset.dx.isNaN) return 0 - padding.left;
    final topLeft = box.size.topLeft(boxOffset);
    return topLeft.dx - padding.left;
  }

  ///Get the right position of the widget
  double getRight() {
    final box = key!.currentContext!.findRenderObject() as RenderBox;
    final boxOffset = box.localToGlobal(const Offset(0.0, 0.0));
    if (boxOffset.dx.isNaN) return padding.right;
    final bottomRight =
    box.size.bottomRight(box.localToGlobal(const Offset(0.0, 0.0)));
    return bottomRight.dx + padding.right;
  }

  double getHeight() {
    return getBottom() - getTop();
  }

  double getWidth() {
    return getRight() - getLeft();
  }

  double getCenter() {
    return (getLeft() + getRight()) / 2;
  }
}