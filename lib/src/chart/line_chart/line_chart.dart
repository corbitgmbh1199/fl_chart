import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_scaffold_widget.dart';
import 'package:fl_chart/src/chart/base/axis_chart/scale_axis.dart';
import 'package:fl_chart/src/chart/base/axis_chart/transformation_config.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_data.dart';
import 'package:fl_chart/src/chart/base/base_chart/fl_touch_event.dart';
import 'package:fl_chart/src/chart/line_chart/background_block/background_block_icon_widget.dart';
import 'package:fl_chart/src/chart/line_chart/background_block/background_block_tooltip_painter.dart';
import 'package:fl_chart/src/chart/line_chart/custom_axis_line/custom_axis_lines_painter.dart';
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
          // 1. 最底層：客製化軸線（比BackgroundBlock還要下面）
          if (showingData.customAxisLines.show)
            Positioned.fill(
              child: CustomPaint(
                painter: CustomAxisLinesPainter(
                  customAxisLinesData: showingData.customAxisLines,
                  chartData: showingData,
                  chartVirtualRect: chartVirtualRect,
                ),
              ),
            ),
          // 2. 然後渲染背景區塊的 Widget 圖示（軸線上方）
          ..._buildBackgroundBlockIcons(showingData, chartVirtualRect),
          // 2. 接著渲染圖表主體（線條、點等會在圖示上方）
          LineChartLeaf(
            data: _withTouchedIndicators(
              _lineChartDataTween!.evaluate(animation),
            ),
            targetData: _withTouchedIndicators(showingData),
            key: widget.chartRendererKey,
            chartVirtualRect: chartVirtualRect,
            canBeScaled:
                widget.transformationConfig.scaleAxis != FlScaleAxis.none,
          ),
          // 4. 最後顯示背景區塊的 tooltip（最頂層）
          if (_touchedBackgroundBlock != null)
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundBlockTooltipPainter(
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

  /// 建構背景區塊的 Widget 圖示
  List<Widget> _buildBackgroundBlockIcons(
    LineChartData data,
    Rect? chartVirtualRect,
  ) {
    final iconWidgets = <Widget>[];

    for (var i = 0; i < data.backgroundBlocks.length; i++) {
      final blockData = data.backgroundBlocks[i];

      if (!blockData.show || blockData.iconWidget == null) {
        continue;
      }

      final iconWidget = BackgroundBlockIconWidget(
        key: ValueKey('bg_icon_$i'),
        blockData: blockData,
        chartData: data,
        chartVirtualRect: chartVirtualRect,
      );

      iconWidgets.add(iconWidget);
    }

    return iconWidgets;
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
