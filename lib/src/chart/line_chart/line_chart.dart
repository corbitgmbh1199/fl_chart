import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_scaffold_widget.dart';
import 'package:fl_chart/src/chart/base/axis_chart/scale_axis.dart';
import 'package:fl_chart/src/chart/base/axis_chart/transformation_config.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_data.dart';
import 'package:fl_chart/src/chart/base/base_chart/fl_touch_event.dart';
import 'package:fl_chart/src/chart/line_chart/line_chart_data.dart';
import 'package:fl_chart/src/chart/line_chart/line_chart_helper.dart';
import 'package:fl_chart/src/chart/line_chart/line_chart_renderer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Renders a line chart as a widget, using provided [LineChartData].
class LineChart extends ImplicitlyAnimatedWidget {
  /// [data] determines how the [LineChart] should be look like,
  /// when you make any change in the [LineChartData], it updates
  /// new values with animation, and duration is [duration].
  /// also you can change the [curve]
  /// which default is [Curves.linear].
  const LineChart(
    this.data, {
    this.chartRendererKey,
    super.key,
    super.duration = const Duration(milliseconds: 150),
    super.curve = Curves.linear,
    this.transformationConfig = const FlTransformationConfig(),
  });

  /// Determines how the [LineChart] should be look like.
  final LineChartData data;

  /// {@macro fl_chart.AxisChartScaffoldWidget.transformationConfig}
  final FlTransformationConfig transformationConfig;

  /// We pass this key to our renderers which are supposed to
  /// render the chart itself (without anything around the chart).
  final Key? chartRendererKey;

  /// Creates a [_LineChartState]
  @override
  _LineChartState createState() => _LineChartState();
}

class _LineChartState extends AnimatedWidgetBaseState<LineChart> {
  /// we handle under the hood animations (implicit animations) via this tween,
  /// it lerps between the old [LineChartData] to the new one.
  LineChartDataTween? _lineChartDataTween;

  /// If [LineTouchData.handleBuiltInTouches] is true, we override the callback to handle touches internally,
  /// but we need to keep the provided callback to notify it too.
  BaseTouchCallback<LineTouchResponse>? _providedTouchCallback;

  final List<ShowingTooltipIndicators> _showingTouchedTooltips = [];

  final Map<int, List<int>> _showingTouchedIndicators = {};

  TouchedBackgroundBlock? _touchedBackgroundBlock;

  final _lineChartHelper = LineChartHelper();

  int? _lastTouchedBlockIndex;

  @override
  Widget build(BuildContext context) {

    final showingData = _getData();

    return AxisChartScaffoldWidget(
      transformationConfig: widget.transformationConfig,
      chartBuilder: (context, chartVirtualRect) => Stack(
        children: [
          LineChartLeaf(
            data: _withTouchedIndicators(
              _lineChartDataTween!.evaluate(animation),
            ),
            targetData: _withTouchedIndicators(showingData),
            key: widget.chartRendererKey,
            chartVirtualRect: chartVirtualRect,
            canBeScaled: widget.transformationConfig.scaleAxis != FlScaleAxis.none,
          ),
          // 顯示背景區塊的 tooltip
          if (_touchedBackgroundBlock != null)
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundBlockTooltipPainter(
                  touchedBlock: _touchedBackgroundBlock!,
                  chartData: showingData,
                  chartVirtualRect: chartVirtualRect,
                ),
              ),
            ),
        ],
      ),
      data: showingData,
    );
  }

  LineChartData _withTouchedIndicators(LineChartData lineChartData) {
    if (!lineChartData.lineTouchData.enabled ||
        !lineChartData.lineTouchData.handleBuiltInTouches) {
      return lineChartData;
    }

    return lineChartData.copyWith(
      showingTooltipIndicators: _showingTouchedTooltips,
      lineBarsData: lineChartData.lineBarsData.map((barData) {
        final index = lineChartData.lineBarsData.indexOf(barData);
        return barData.copyWith(
          showingIndicators: _showingTouchedIndicators[index] ?? [],
        );
      }).toList(),
    );
  }

  LineChartData _getData() {
    var newData = widget.data;

    /// Calculate minX, maxX, minY, maxY for [LineChartData] if they are null,
    /// it is necessary to render the chart correctly.
    if (newData.minX.isNaN ||
        newData.maxX.isNaN ||
        newData.minY.isNaN ||
        newData.maxY.isNaN) {
      final (minX, maxX, minY, maxY) = _lineChartHelper.calculateMaxAxisValues(
        newData.lineBarsData,
      );
      newData = newData.copyWith(
        minX: newData.minX.isNaN ? minX : newData.minX,
        maxX: newData.maxX.isNaN ? maxX : newData.maxX,
        minY: newData.minY.isNaN ? minY : newData.minY,
        maxY: newData.maxY.isNaN ? maxY : newData.maxY,
      );
    }

    final lineTouchData = newData.lineTouchData;
    if (lineTouchData.enabled && lineTouchData.handleBuiltInTouches) {
      _providedTouchCallback = lineTouchData.touchCallback;
      newData = newData.copyWith(
        lineTouchData:
            newData.lineTouchData.copyWith(touchCallback: _handleBuiltInTouch),
      );
    }

    return newData;
  }

  // 修正 _handleBuiltInTouch 方法，確保 spots tooltip 優先顯示
  void _handleBuiltInTouch(
    FlTouchEvent event,
    LineTouchResponse? touchResponse,
  ) {
    if (!mounted) {
      return;
    }

    _providedTouchCallback?.call(event, touchResponse);

    if (!event.isInterestedForInteractions) {
      setState(() {
        _showingTouchedTooltips.clear();
        _showingTouchedIndicators.clear();
        _touchedBackgroundBlock = null;
        _lastTouchedBlockIndex = null;
      });
      return;
    }

    // 優先處理線條觸碰（spots tooltip 優先）
    if (touchResponse?.lineBarSpots != null &&
        touchResponse!.lineBarSpots!.isNotEmpty) {
      setState(() {
        _touchedBackgroundBlock = null;
        _lastTouchedBlockIndex = null;

        final sortedLineSpots = List.of(touchResponse.lineBarSpots!)
          ..sort((spot1, spot2) => spot2.y.compareTo(spot1.y));

        _showingTouchedIndicators.clear();
        for (var i = 0; i < touchResponse.lineBarSpots!.length; i++) {
          final touchedBarSpot = touchResponse.lineBarSpots![i];
          final barPos = touchedBarSpot.barIndex;
          _showingTouchedIndicators[barPos] = [touchedBarSpot.spotIndex];
        }

        _showingTouchedTooltips
          ..clear()
          ..add(ShowingTooltipIndicators(sortedLineSpots));
      });
      return;
    }

    // 只有在沒有線條觸碰時才處理背景區塊觸碰
    final newBackgroundBlock = touchResponse?.touchedBackgroundBlock;
    if (newBackgroundBlock != null) {
      final newBlockIndex = newBackgroundBlock.blockIndex;

      if (_lastTouchedBlockIndex != newBlockIndex) {
        setState(() {
          _touchedBackgroundBlock = newBackgroundBlock;
          _showingTouchedTooltips.clear();
          _showingTouchedIndicators.clear();
          _lastTouchedBlockIndex = newBlockIndex;
        });
      } else {
      }
      return;
    }

    // 清除所有狀態
    if (_touchedBackgroundBlock != null ||
        _showingTouchedTooltips.isNotEmpty ||
        _showingTouchedIndicators.isNotEmpty) {
      setState(() {
        _showingTouchedTooltips.clear();
        _showingTouchedIndicators.clear();
        _touchedBackgroundBlock = null;
        _lastTouchedBlockIndex = null;
      });
    }
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _lineChartDataTween = visitor(
      _lineChartDataTween,
      _getData(),
      (dynamic value) =>
          LineChartDataTween(begin: value as LineChartData, end: widget.data),
    ) as LineChartDataTween?;
  }
}

// 修正 _BackgroundBlockTooltipPainter 類別，使其像 touchTooltipData 一樣在整個圖表區域內顯示

class _BackgroundBlockTooltipPainter extends CustomPainter {
  _BackgroundBlockTooltipPainter({
    required this.touchedBlock,
    required this.chartData,
    this.chartVirtualRect,
  });

  final TouchedBackgroundBlock touchedBlock;
  final LineChartData chartData;
  final Rect? chartVirtualRect;

  @override
  void paint(Canvas canvas, Size size) {
    // 使用全域的背景區塊 tooltip 設定
    final tooltipData = chartData.lineTouchData.backgroundBlockTooltipData;

    // 使用全域 tooltip 系統取得項目
    final tooltipItems = tooltipData.getTooltipItems(touchedBlock);
    if (tooltipItems.isEmpty || tooltipItems.every((item) => item == null)) {
      return;
    }

    // 建立文字繪製器清單
    final textPainters = <TextPainter>[];
    for (final item in tooltipItems) {
      if (item == null) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: item.text,
          style: item.textStyle,
          children: item.children,
        ),
        textAlign: item.textAlign,
        textDirection: item.textDirection,
      )..layout(maxWidth: tooltipData.maxContentWidth);

      textPainters.add(textPainter);
    }

    if (textPainters.isEmpty) {
      return;
    }

    // 計算 tooltip 尺寸
    var maxWidth = 0.0;
    var totalHeight = 0.0;
    const textMargin = 4.0;

    for (final painter in textPainters) {
      if (painter.width > maxWidth) {
        maxWidth = painter.width;
      }
      totalHeight += painter.height;
    }
    totalHeight += (textPainters.length - 1) * textMargin;

    final tooltipWidth = maxWidth + tooltipData.tooltipPadding.horizontal;
    final tooltipHeight = totalHeight + tooltipData.tooltipPadding.vertical;

    // 計算觸碰點在圖表中的像素位置（類似 touchTooltipData 的做法）
    final blockCenterX =
        (touchedBlock.blockData.startX + touchedBlock.blockData.endX) / 2;
    final touchPoint = Offset(
      _getPixelX(blockCenterX, size),
      size.height / 2, // 可以設定為圖表中央或其他位置
    );

    // 動態取得對齊方式和偏移量
    final alignment =
        tooltipData.getTooltipAlignment?.call(touchedBlock, size) ??
            tooltipData.tooltipHorizontalAlignment;

    final horizontalOffset =
        tooltipData.getTooltipHorizontalOffset?.call(touchedBlock, size) ??
            tooltipData.tooltipHorizontalOffset;

    // 計算 tooltip 位置（在整個圖表區域內，不受背景區塊限制）
    double tooltipTop;
    if (tooltipData.showOnTopOfTheChartBoxArea) {
      tooltipTop = -tooltipHeight - tooltipData.tooltipMargin;
    } else {
      tooltipTop = tooltipData.tooltipMargin;
    }

    // 根據對齊方式計算 tooltip 水平位置（相對於整個圖表寬度）
    double tooltipLeft;
    switch (alignment) {
      case FLHorizontalAlignment.left:
        tooltipLeft = touchPoint.dx + horizontalOffset;
        break;
      case FLHorizontalAlignment.right:
        tooltipLeft = touchPoint.dx - tooltipWidth + horizontalOffset;
        break;
      case FLHorizontalAlignment.center:
      default:
        tooltipLeft = touchPoint.dx - tooltipWidth / 2 + horizontalOffset;
        break;
    }

    // 邊界檢查（相對於整個圖表區域）
    if (tooltipData.fitInsideHorizontally) {
      final maxRight = size.width;
      const minLeft = 0.0;

      if (tooltipLeft < minLeft) {
        tooltipLeft = minLeft;
      } else if (tooltipLeft + tooltipWidth > maxRight) {
        tooltipLeft = maxRight - tooltipWidth;
      }
    }

    if (tooltipData.fitInsideVertically) {
      if (tooltipTop < 0) {
        tooltipTop = 0;
      } else if (tooltipTop + tooltipHeight > size.height) {
        tooltipTop = size.height - tooltipHeight;
      }
    }

    // 繪製 tooltip 背景
    final tooltipRect = Rect.fromLTWH(
      tooltipLeft,
      tooltipTop,
      tooltipWidth,
      tooltipHeight,
    );

    final backgroundColor = tooltipData.getTooltipColor(touchedBlock);
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // 繪製背景
    final roundedRect = RRect.fromRectAndCorners(
      tooltipRect,
      topLeft: tooltipData.tooltipBorderRadius.topLeft,
      topRight: tooltipData.tooltipBorderRadius.topRight,
      bottomLeft: tooltipData.tooltipBorderRadius.bottomLeft,
      bottomRight: tooltipData.tooltipBorderRadius.bottomRight,
    );

    canvas.drawRRect(roundedRect, backgroundPaint);

    // 繪製邊框
    if (tooltipData.tooltipBorder != BorderSide.none) {
      final borderPaint = Paint()
        ..color = tooltipData.tooltipBorder.color
        ..strokeWidth = tooltipData.tooltipBorder.width
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(roundedRect, borderPaint);
    }

    // 繪製文字
    var currentY = tooltipTop + tooltipData.tooltipPadding.top;
    for (final textPainter in textPainters) {
      textPainter.paint(
        canvas,
        Offset(
          tooltipLeft + tooltipData.tooltipPadding.left,
          currentY,
        ),
      );
      currentY += textPainter.height + textMargin;
    }
  }

  /// 計算圖表座標對應的像素 X 位置（類似 LineChartPainter 的實作）
  double _getPixelX(double chartX, Size size) {
    final deltaX = chartData.maxX - chartData.minX;
    if (deltaX == 0) return 0.0;

    // 考慮變換後的座標計算
    if (chartVirtualRect != null) {
      final virtualWidth = chartVirtualRect!.width;
      final virtualLeft = chartVirtualRect!.left;
      final normalizedX = (chartX - chartData.minX) / deltaX;
      return virtualLeft + (normalizedX * virtualWidth);
    } else {
      final pixelPerX = size.width / deltaX;
      return (chartX - chartData.minX) * pixelPerX;
    }
  }

  @override
  bool shouldRepaint(_BackgroundBlockTooltipPainter oldDelegate) {
    return touchedBlock.blockIndex != oldDelegate.touchedBlock.blockIndex ||
        !identical(
            touchedBlock.blockData, oldDelegate.touchedBlock.blockData) ||
        chartData != oldDelegate.chartData ||
        chartVirtualRect != oldDelegate.chartVirtualRect;
  }
}
