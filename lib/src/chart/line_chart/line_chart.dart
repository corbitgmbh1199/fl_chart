import 'dart:async';

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

  Timer? _tooltipDebounceTimer;
  TouchedBackgroundBlock? _pendingBackgroundBlock;

  @override
  void dispose() {
    _tooltipDebounceTimer?.cancel();
    super.dispose();
  }

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
            _buildBackgroundBlockTooltip(context, chartVirtualRect),
        ],
      ),
      data: showingData,
    );
  }

    /// 建構背景區塊的 tooltip Widget
  Widget _buildBackgroundBlockTooltip(BuildContext context, Rect? chartVirtualRect) {
    final block = _touchedBackgroundBlock!;
    final tooltipData = block.blockData.tooltipData!;
    
    if (tooltipData.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundBlockTooltipPainter(
          touchedBlock: block,
          chartData: _getData(),
          chartVirtualRect: chartVirtualRect,
        ),
      ),
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

  void _handleBuiltInTouch(
    FlTouchEvent event,
    LineTouchResponse? touchResponse,
  ) {
    if (!mounted) {
      return;
    }
    _providedTouchCallback?.call(event, touchResponse);

    // 修改條件邏輯，避免不必要的清除
    if (!event.isInterestedForInteractions) {
      setState(() {
        _showingTouchedTooltips.clear();
        _showingTouchedIndicators.clear();
        _touchedBackgroundBlock = null;
      });
      return;
    }

    // 處理背景區塊觸碰（使用防抖動）
    if (touchResponse?.touchedBackgroundBlock != null) {
      final newBlock = touchResponse!.touchedBackgroundBlock!;
      
      // 如果是同一個區塊，立即更新
      if (_touchedBackgroundBlock?.blockIndex == newBlock.blockIndex) {
        return; // 避免不必要的重繪
      }

      // 使用防抖動機制
      _tooltipDebounceTimer?.cancel();
      _tooltipDebounceTimer = Timer(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            _touchedBackgroundBlock = newBlock;
            _showingTouchedTooltips.clear();
            _showingTouchedIndicators.clear();
          });
        }
      });
      return;
    }

    // 處理線條觸碰
    if (touchResponse?.lineBarSpots != null && 
        touchResponse!.lineBarSpots!.isNotEmpty) {
      _tooltipDebounceTimer?.cancel();
      setState(() {
        _touchedBackgroundBlock = null;

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

    // 清除所有狀態
    _tooltipDebounceTimer?.cancel();
    if (_touchedBackgroundBlock != null || 
        _showingTouchedTooltips.isNotEmpty || 
        _showingTouchedIndicators.isNotEmpty) {
      setState(() {
        _showingTouchedTooltips.clear();
        _showingTouchedIndicators.clear();
        _touchedBackgroundBlock = null;
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
    final tooltipData = touchedBlock.blockData.tooltipData!;

    if (tooltipData.text.isEmpty) return;

    // 計算 tooltip 位置 - 使用區塊中心而不是觸碰點
    final blockCenterX =
        (touchedBlock.blockData.startX + touchedBlock.blockData.endX) / 2;
    final chartUsableSize = _getChartUsableSize(size);
    final deltaX = chartData.maxX - chartData.minX;

    // 避免除以零的情況
    if (deltaX == 0) return;

    final pixelPerX = chartUsableSize.width / deltaX;
    final tooltipX = (blockCenterX - chartData.minX) * pixelPerX;

    // 建立文字繪製器並使用 cascade 操作符
    final textPainter = TextPainter(
      text: TextSpan(
        text: tooltipData.text,
        style: tooltipData.textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 計算 tooltip 背景尺寸
    final tooltipWidth = textPainter.width + tooltipData.padding.horizontal;
    final tooltipHeight = textPainter.height + tooltipData.padding.vertical;

    // 計算 tooltip 位置（在圖表頂部），確保位置穩定
    var tooltipLeft = tooltipX - tooltipWidth / 2;
    const tooltipTop = 20.0;

    // 確保 tooltip 不會超出邊界
    tooltipLeft = tooltipLeft.clamp(0.0,
        (chartUsableSize.width - tooltipWidth).clamp(0.0, double.infinity));

    // 繪製 tooltip 背景
    final tooltipRect = Rect.fromLTWH(
      tooltipLeft,
      tooltipTop,
      tooltipWidth,
      tooltipHeight,
    );

    final backgroundPaint = Paint()
      ..color = tooltipData.backgroundColor
      ..style = PaintingStyle.fill;

    // 繪製背景陰影（可選）
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        tooltipRect.translate(2, 2), // 陰影偏移
        topLeft: tooltipData.borderRadius.topLeft,
        topRight: tooltipData.borderRadius.topRight,
        bottomLeft: tooltipData.borderRadius.bottomLeft,
        bottomRight: tooltipData.borderRadius.bottomRight,
      ),
      shadowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        tooltipRect,
        topLeft: tooltipData.borderRadius.topLeft,
        topRight: tooltipData.borderRadius.topRight,
        bottomLeft: tooltipData.borderRadius.bottomLeft,
        bottomRight: tooltipData.borderRadius.bottomRight,
      ),
      backgroundPaint,
    );

    // 繪製文字
    textPainter.paint(
      canvas,
      Offset(
        tooltipLeft + tooltipData.padding.left,
        tooltipTop + tooltipData.padding.top,
      ),
    );
  }

  Size _getChartUsableSize(Size size) {
    // 簡化的計算，實際應該考慮 padding 和 margin
    return size;
  }

  @override
  bool shouldRepaint(_BackgroundBlockTooltipPainter oldDelegate) {
    // 只有當重要屬性改變時才重繪
    return touchedBlock.blockIndex != oldDelegate.touchedBlock.blockIndex ||
        touchedBlock.blockData != oldDelegate.touchedBlock.blockData ||
        chartData != oldDelegate.chartData ||
        chartVirtualRect != oldDelegate.chartVirtualRect;
  }
}
