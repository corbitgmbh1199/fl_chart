// coverage:ignore-file
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/line_chart/custom_axis_line/custom_axis_lines_data.dart';
import 'package:fl_chart/src/extensions/color_extension.dart';
import 'package:fl_chart/src/extensions/gradient_extension.dart';
import 'package:fl_chart/src/utils/lerp.dart';
import 'package:flutter/material.dart' hide Image;

/// [LineChart] needs this class to render itself.
///
/// It holds data needed to draw a line chart,
/// including bar lines, spots, colors, touches, ...
class LineChartData extends AxisChartData with EquatableMixin {
  /// [LineChart] draws some lines in various shapes and overlaps them.
  /// lines are defined in [lineBarsData], sometimes you need to fill space between two bars
  /// with a color or gradient, you can use [betweenBarsData] to achieve that.
  ///
  /// It draws some titles on left, top, right, bottom sides per each axis number,
  /// you can modify [titlesData] to have your custom titles,
  /// also you can define the axis title (one text per axis) for each side
  /// using [axisTitleData], you can restrict the y axis using [minY] and [maxY] value,
  /// and restrict x axis using [minX] and [maxX].
  ///
  /// It draws a color as a background behind everything you can set it using [backgroundColor],
  /// then a grid over it, you can customize it using [gridData],
  /// and it draws 4 borders around your chart, you can customize it using [borderData].
  ///
  /// You can annotate some regions with a highlight color using [rangeAnnotations].
  ///
  /// You can modify [lineTouchData] to customize touch behaviors and responses.
  ///
  /// you can show some tooltipIndicators (a popup with an information)
  /// on top of each [LineChartBarData.spots] using [showingTooltipIndicators],
  /// just put line indicator number and spots indices you want to show it on top of them.
  ///
  /// [LineChart] draws some horizontal or vertical lines on above or below of everything,
  /// they are useful in some scenarios, for example you can show average line, you can fill
  /// [extraLinesData] property to have your extra lines.
  ///
  /// [clipData] forces the [LineChart] to draw lines inside the chart bounding box.
  LineChartData({
    this.lineBarsData = const [],
    this.betweenBarsData = const [],
    this.backgroundBlocks = const [],
    this.customAxisLines = const CustomAxisLinesData(), 
    super.titlesData = const FlTitlesData(),
    super.extraLinesData = const ExtraLinesData(),
    this.lineTouchData = const LineTouchData(),
    this.showingTooltipIndicators = const [],
    super.gridData = const FlGridData(),
    super.borderData,
    super.rangeAnnotations = const RangeAnnotations(),
    double? minX,
    double? maxX,
    super.baselineX,
    double? minY,
    double? maxY,
    super.baselineY,
    super.clipData = const FlClipData.none(),
    super.backgroundColor,
    super.rotationQuarterTurns,
  }) : super(
          minX: minX ?? double.nan,
          maxX: maxX ?? double.nan,
          minY: minY ?? double.nan,
          maxY: maxY ?? double.nan,
        );

  /// [LineChart] draws some lines in various shapes and overlaps them.
  final List<LineChartBarData> lineBarsData;

  /// Fills area between two [LineChartBarData] with a color or gradient.
  final List<BetweenBarsData> betweenBarsData;

  /// 背景區塊清單
  final List<BackgroundBlockData> backgroundBlocks;

  /// 客製化軸線資料
  final CustomAxisLinesData customAxisLines;

  /// Handles touch behaviors and responses.
  final LineTouchData lineTouchData;

  /// You can show some tooltipIndicators (a popup with an information)
  /// on top of each [LineChartBarData.spots] using [showingTooltipIndicators],
  /// just put line indicator number and spots indices you want to show it on top of them.
  ///
  /// An important point is that you have to disable the default touch behaviour
  /// to show the tooltip manually, see [LineTouchData.handleBuiltInTouches].
  final List<ShowingTooltipIndicators> showingTooltipIndicators;

  /// Lerps a [BaseChartData] based on [t] value, check [Tween.lerp].
  @override
  LineChartData lerp(BaseChartData a, BaseChartData b, double t) {
    if (a is LineChartData && b is LineChartData) {
      return LineChartData(
        minX: lerpDouble(a.minX, b.minX, t),
        maxX: lerpDouble(a.maxX, b.maxX, t),
        baselineX: lerpDouble(a.baselineX, b.baselineX, t),
        minY: lerpDouble(a.minY, b.minY, t),
        maxY: lerpDouble(a.maxY, b.maxY, t),
        baselineY: lerpDouble(a.baselineY, b.baselineY, t),
        backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
        borderData: FlBorderData.lerp(a.borderData, b.borderData, t),
        clipData: b.clipData,
        extraLinesData:
            ExtraLinesData.lerp(a.extraLinesData, b.extraLinesData, t),
        gridData: FlGridData.lerp(a.gridData, b.gridData, t),
        titlesData: FlTitlesData.lerp(a.titlesData, b.titlesData, t),
        rangeAnnotations:
            RangeAnnotations.lerp(a.rangeAnnotations, b.rangeAnnotations, t),
        lineBarsData:
            lerpLineChartBarDataList(a.lineBarsData, b.lineBarsData, t)!,
        betweenBarsData:
            lerpBetweenBarsDataList(a.betweenBarsData, b.betweenBarsData, t)!,
        backgroundBlocks: _lerpBackgroundBlockDataList(
            a.backgroundBlocks, b.backgroundBlocks, t,),
        customAxisLines: CustomAxisLinesData.lerp(a.customAxisLines, b.customAxisLines, t),
        lineTouchData: b.lineTouchData,
        showingTooltipIndicators: b.showingTooltipIndicators,
        rotationQuarterTurns: b.rotationQuarterTurns,
      );
    } else {
      throw Exception('Illegal State');
    }
  }

  /// 背景區塊清單的線性插值函式
  static List<BackgroundBlockData> _lerpBackgroundBlockDataList(
    List<BackgroundBlockData> a,
    List<BackgroundBlockData> b,
    double t,
  ) {
    if (a.length != b.length) {
      return b; // 如果長度不同，直接回傳目標清單
    }

    return List.generate(
      b.length,
      (index) => BackgroundBlockData.lerp(a[index], b[index], t),
    );
  }

  /// Copies current [LineChartData] to a new [LineChartData],
  /// and replaces provided values.
  LineChartData copyWith({
    List<LineChartBarData>? lineBarsData,
    List<BetweenBarsData>? betweenBarsData,
    List<BackgroundBlockData>? backgroundBlocks,
    CustomAxisLinesData? customAxisLines,
    FlTitlesData? titlesData,
    RangeAnnotations? rangeAnnotations,
    ExtraLinesData? extraLinesData,
    LineTouchData? lineTouchData,
    List<ShowingTooltipIndicators>? showingTooltipIndicators,
    FlGridData? gridData,
    FlBorderData? borderData,
    double? minX,
    double? maxX,
    double? baselineX,
    double? minY,
    double? maxY,
    double? baselineY,
    FlClipData? clipData,
    Color? backgroundColor,
    int? rotationQuarterTurns,
  }) =>
      LineChartData(
        lineBarsData: lineBarsData ?? this.lineBarsData,
        betweenBarsData: betweenBarsData ?? this.betweenBarsData,
        backgroundBlocks: backgroundBlocks ?? this.backgroundBlocks,
        customAxisLines: customAxisLines ?? this.customAxisLines,
        titlesData: titlesData ?? this.titlesData,
        rangeAnnotations: rangeAnnotations ?? this.rangeAnnotations,
        extraLinesData: extraLinesData ?? this.extraLinesData,
        lineTouchData: lineTouchData ?? this.lineTouchData,
        showingTooltipIndicators:
            showingTooltipIndicators ?? this.showingTooltipIndicators,
        gridData: gridData ?? this.gridData,
        borderData: borderData ?? this.borderData,
        minX: minX ?? this.minX,
        maxX: maxX ?? this.maxX,
        baselineX: baselineX ?? this.baselineX,
        minY: minY ?? this.minY,
        maxY: maxY ?? this.maxY,
        baselineY: baselineY ?? this.baselineY,
        clipData: clipData ?? this.clipData,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
      );

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        lineBarsData,
        betweenBarsData,
        backgroundBlocks,
        customAxisLines,
        titlesData,
        extraLinesData,
        lineTouchData,
        showingTooltipIndicators,
        gridData,
        borderData,
        rangeAnnotations,
        minX,
        maxX,
        baselineX,
        minY,
        maxY,
        baselineY,
        clipData,
        backgroundColor,
        rotationQuarterTurns,
      ];
}

/// Holds data for drawing each individual line in the [LineChart]
class LineChartBarData with EquatableMixin {
  /// [BarChart] draws some lines and overlaps them in the chart's view,
  /// You can have multiple lines by splitting them,
  /// put a [FlSpot.nullSpot] between each section.
  /// each line passes through [spots], with hard edges by default,
  /// [isCurved] makes it curve for drawing, and [curveSmoothness] determines the curve smoothness.
  ///
  /// [show] determines the drawing, if set to false, it draws nothing.
  ///
  /// [mainColors] determines the color of drawing line, if one color provided it applies a solid color,
  /// otherwise it gradients between provided colors for drawing the line.
  /// Gradient happens using provided [colorStops], [gradientFrom], [gradientTo].
  /// if you want it draw normally, don't touch them,
  /// check [LinearGradient] for understanding [colorStops]
  ///
  /// [barWidth] determines the thickness of drawing line,
  ///
  /// if [isCurved] is true, in some situations if the spots changes are in high values,
  /// an overshooting will happen, we don't have any idea to solve this at the moment,
  /// but you can set [preventCurveOverShooting] true, and update the threshold
  /// using [preventCurveOvershootingThreshold] to achieve an acceptable curve,
  /// check this [issue](https://github.com/imaNNeo/fl_chart/issues/25)
  /// to overshooting understand the problem.
  ///
  /// [isStrokeCapRound] determines the shape of line's cap.
  ///
  /// [isStrokeJoinRound] determines the shape of the line joins.
  ///
  /// [belowBarData], and  [aboveBarData] used to fill the space below or above the drawn line,
  /// you can fill with a solid color or a linear gradient.
  ///
  /// [LineChart] draws points that the line is going through [spots],
  /// you can customize it's appearance using [dotData].
  ///
  /// there are some indicators with a line and bold point on each spot,
  /// you can show them by filling [showingIndicators] with indices
  /// you want to show indicator on them.
  ///
  /// [LineChart] draws the lines with dashed effect if you fill [dashArray].
  ///
  /// If you want to have a Step Line Chart style, just set [isStepLineChart] true,
  /// also you can tweak the [LineChartBarData.lineChartStepData].
  LineChartBarData({
    this.spots = const [],
    this.show = true,
    Color? color,
    this.gradient,
    this.barWidth = 2.0,
    this.isCurved = false,
    this.curveSmoothness = 0.35,
    this.preventCurveOverShooting = false,
    this.preventCurveOvershootingThreshold = 10.0,
    this.isStrokeCapRound = false,
    this.isStrokeJoinRound = false,
    BarAreaData? belowBarData,
    BarAreaData? aboveBarData,
    this.dotData = const FlDotData(),
    this.errorIndicatorData =
        const FlErrorIndicatorData<LineChartSpotErrorRangeCallbackInput>(),
    this.showingIndicators = const [],
    this.dashArray,
    this.shadow = const Shadow(color: Colors.transparent),
    this.isStepLineChart = false,
    this.lineChartStepData = const LineChartStepData(),
  })  : color =
            color ?? ((color == null && gradient == null) ? Colors.cyan : null),
        belowBarData = belowBarData ?? BarAreaData(),
        aboveBarData = aboveBarData ?? BarAreaData() {
    FlSpot? mostLeft;
    FlSpot? mostTop;
    FlSpot? mostRight;
    FlSpot? mostBottom;

    FlSpot? firstValidSpot;
    try {
      firstValidSpot =
          spots.firstWhere((element) => element != FlSpot.nullSpot);
    } catch (_) {
      // There is no valid spot
    }
    if (firstValidSpot != null) {
      for (final spot in spots) {
        if (spot.isNull()) {
          continue;
        }
        if (mostLeft == null || spot.x < mostLeft.x) {
          mostLeft = spot;
        }

        if (mostRight == null || spot.x > mostRight.x) {
          mostRight = spot;
        }

        if (mostTop == null || spot.y > mostTop.y) {
          mostTop = spot;
        }

        if (mostBottom == null || spot.y < mostBottom.y) {
          mostBottom = spot;
        }
      }
      mostLeftSpot = mostLeft!;
      mostTopSpot = mostTop!;
      mostRightSpot = mostRight!;
      mostBottomSpot = mostBottom!;
    }
  }

  /// This line goes through this spots.
  ///
  /// You can have multiple lines by splitting them,
  /// put a [FlSpot.nullSpot] between each section.
  final List<FlSpot> spots;

  /// We keep the most left spot to prevent redundant calculations
  late final FlSpot mostLeftSpot;

  /// We keep the most top spot to prevent redundant calculations
  late final FlSpot mostTopSpot;

  /// We keep the most right spot to prevent redundant calculations
  late final FlSpot mostRightSpot;

  /// We keep the most bottom spot to prevent redundant calculations
  late final FlSpot mostBottomSpot;

  /// Determines to show or hide the line.
  final bool show;

  /// If provided, this [LineChartBarData] draws with this [color]
  /// Otherwise we use  [gradient] to draw the background.
  /// It throws an exception if you provide both [color] and [gradient]
  final Color? color;

  /// If provided, this [LineChartBarData] draws with this [gradient].
  /// Otherwise we use [color] to draw the background.
  /// It throws an exception if you provide both [color] and [gradient]
  final Gradient? gradient;

  /// Determines thickness of drawing line.
  final double barWidth;

  /// If it's true, [LineChart] draws the line with curved edges,
  /// otherwise it draws line with hard edges.
  final bool isCurved;

  /// If [isCurved] is true, it determines smoothness of the curved edges.
  final double curveSmoothness;

  /// Prevent overshooting when draw curve line with high value changes.
  /// check this [issue](https://github.com/imaNNeo/fl_chart/issues/25)
  final bool preventCurveOverShooting;

  /// Applies threshold for [preventCurveOverShooting] algorithm.
  final double preventCurveOvershootingThreshold;

  /// Determines the style of line's cap.
  final bool isStrokeCapRound;

  /// Determines the style of line joins.
  final bool isStrokeJoinRound;

  /// Fills the space blow the line, using a color or gradient.
  final BarAreaData belowBarData;

  /// Fills the space above the line, using a color or gradient.
  final BarAreaData aboveBarData;

  /// Responsible to showing [spots] on the line as a circular point.
  final FlDotData dotData;

  /// Holds data for showing error indicators on the spots in this line.
  final FlErrorIndicatorData<LineChartSpotErrorRangeCallbackInput>
      errorIndicatorData;

  /// Show indicators based on provided indexes
  final List<int> showingIndicators;

  /// Determines the dash length and space respectively, fill it if you want to have dashed line.
  final List<int>? dashArray;

  /// Drops a shadow behind the bar line.
  final Shadow shadow;

  /// If sets true, it draws the chart in Step Line Chart style, using [LineChartBarData.lineChartStepData].
  final bool isStepLineChart;

  /// Holds data for representing a Step Line Chart, and works only if [isStepChart] is true.
  final LineChartStepData lineChartStepData;

  /// Lerps a [LineChartBarData] based on [t] value, check [Tween.lerp].
  static LineChartBarData lerp(
    LineChartBarData a,
    LineChartBarData b,
    double t,
  ) =>
      LineChartBarData(
        show: b.show,
        barWidth: lerpDouble(a.barWidth, b.barWidth, t)!,
        belowBarData: BarAreaData.lerp(a.belowBarData, b.belowBarData, t),
        aboveBarData: BarAreaData.lerp(a.aboveBarData, b.aboveBarData, t),
        curveSmoothness: b.curveSmoothness,
        isCurved: b.isCurved,
        isStrokeCapRound: b.isStrokeCapRound,
        isStrokeJoinRound: b.isStrokeJoinRound,
        preventCurveOverShooting: b.preventCurveOverShooting,
        preventCurveOvershootingThreshold: lerpDouble(
          a.preventCurveOvershootingThreshold,
          b.preventCurveOvershootingThreshold,
          t,
        )!,
        dotData: FlDotData.lerp(a.dotData, b.dotData, t),
        errorIndicatorData: FlErrorIndicatorData.lerp(
          a.errorIndicatorData,
          b.errorIndicatorData,
          t,
        ),
        dashArray: lerpIntList(a.dashArray, b.dashArray, t),
        color: Color.lerp(a.color, b.color, t),
        gradient: Gradient.lerp(a.gradient, b.gradient, t),
        spots: lerpFlSpotList(a.spots, b.spots, t)!,
        showingIndicators: b.showingIndicators,
        shadow: Shadow.lerp(a.shadow, b.shadow, t)!,
        isStepLineChart: b.isStepLineChart,
        lineChartStepData:
            LineChartStepData.lerp(a.lineChartStepData, b.lineChartStepData, t),
      );

  /// Copies current [LineChartBarData] to a new [LineChartBarData],
  /// and replaces provided values.
  LineChartBarData copyWith({
    List<FlSpot>? spots,
    bool? show,
    Color? color,
    Gradient? gradient,
    double? barWidth,
    bool? isCurved,
    double? curveSmoothness,
    bool? preventCurveOverShooting,
    double? preventCurveOvershootingThreshold,
    bool? isStrokeCapRound,
    bool? isStrokeJoinRound,
    BarAreaData? belowBarData,
    BarAreaData? aboveBarData,
    FlDotData? dotData,
    FlErrorIndicatorData<LineChartSpotErrorRangeCallbackInput>?
        errorIndicatorData,
    List<int>? dashArray,
    List<int>? showingIndicators,
    Shadow? shadow,
    bool? isStepLineChart,
    LineChartStepData? lineChartStepData,
  }) =>
      LineChartBarData(
        spots: spots ?? this.spots,
        show: show ?? this.show,
        color: color ?? this.color,
        gradient: gradient ?? this.gradient,
        barWidth: barWidth ?? this.barWidth,
        isCurved: isCurved ?? this.isCurved,
        curveSmoothness: curveSmoothness ?? this.curveSmoothness,
        preventCurveOverShooting:
            preventCurveOverShooting ?? this.preventCurveOverShooting,
        preventCurveOvershootingThreshold: preventCurveOvershootingThreshold ??
            this.preventCurveOvershootingThreshold,
        isStrokeCapRound: isStrokeCapRound ?? this.isStrokeCapRound,
        isStrokeJoinRound: isStrokeJoinRound ?? this.isStrokeJoinRound,
        belowBarData: belowBarData ?? this.belowBarData,
        aboveBarData: aboveBarData ?? this.aboveBarData,
        dashArray: dashArray ?? this.dashArray,
        dotData: dotData ?? this.dotData,
        errorIndicatorData: errorIndicatorData ?? this.errorIndicatorData,
        showingIndicators: showingIndicators ?? this.showingIndicators,
        shadow: shadow ?? this.shadow,
        isStepLineChart: isStepLineChart ?? this.isStepLineChart,
        lineChartStepData: lineChartStepData ?? this.lineChartStepData,
      );

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        spots,
        show,
        color,
        gradient,
        barWidth,
        isCurved,
        curveSmoothness,
        preventCurveOverShooting,
        preventCurveOvershootingThreshold,
        isStrokeCapRound,
        isStrokeJoinRound,
        belowBarData,
        aboveBarData,
        dotData,
        errorIndicatorData,
        showingIndicators,
        dashArray,
        shadow,
        isStepLineChart,
        lineChartStepData,
      ];
}

/// Holds data for representing a Step Line Chart, and works only if [LineChartBarData.isStepChart] is true.
class LineChartStepData with EquatableMixin {
  /// Determines the [stepDirection] of each step;
  const LineChartStepData({this.stepDirection = stepDirectionMiddle});

  /// Go to the next spot directly, with the current point's y value.
  static const stepDirectionForward = 0.0;

  /// Go to the half with the current spot y, and with the next spot y for the rest.
  static const stepDirectionMiddle = 0.5;

  /// Go to the next spot y and direct line to the next spot.
  static const stepDirectionBackward = 1.0;

  /// Determines the direction of each step;
  final double stepDirection;

  /// Lerps a [LineChartStepData] based on [t] value, check [Tween.lerp].
  static LineChartStepData lerp(
    LineChartStepData a,
    LineChartStepData b,
    double t,
  ) =>
      LineChartStepData(
        stepDirection: lerpDouble(a.stepDirection, b.stepDirection, t)!,
      );

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [stepDirection];
}

/// Holds data for filling an area (above or below) of the line with a color or gradient.
class BarAreaData with EquatableMixin {
  /// if [show] is true, [LineChart] fills above and below area of each line
  /// with a color or gradient.
  ///
  /// [color] determines the color of above or below space area,
  /// if one color provided it applies a solid color,
  /// otherwise it gradients between provided colors for drawing the line.
  /// Gradient happens using provided [gradientColorStops], [gradientFrom], [gradientTo].
  /// if you want it draw normally, don't touch them,
  /// check [LinearGradient] for understanding [gradientColorStops]
  ///
  /// If [spotsLine] is provided, it draws some lines from each spot
  /// to the bottom or top of the chart.
  ///
  /// If [applyCutOffY] is true, it cuts the drawing by the [cutOffY] line.
  BarAreaData({
    this.show = false,
    Color? color,
    this.gradient,
    this.spotsLine = const BarAreaSpotsLine(),
    this.cutOffY = 0,
    this.applyCutOffY = false,
  }) : color = color ??
            ((color == null && gradient == null)
                ? Colors.blueGrey.withValues(alpha: 0.5)
                : null);

  final bool show;

  /// If provided, this [BarAreaData] draws with this [color]
  /// Otherwise we use  [gradient] to draw the background.
  /// It throws an exception if you provide both [color] and [gradient]
  final Color? color;

  /// If provided, this [BarAreaData] draws with this [gradient].
  /// Otherwise we use [color] to draw the background.
  /// It throws an exception if you provide both [color] and [gradient]
  final Gradient? gradient;

  /// holds data for drawing a line from each spot the the bottom, or top of the chart
  final BarAreaSpotsLine spotsLine;

  /// cut the drawing below or above area to this y value
  final double cutOffY;

  /// determines should or shouldn't apply cutOffY
  final bool applyCutOffY;

  /// Lerps a [BarAreaData] based on [t] value, check [Tween.lerp].
  static BarAreaData lerp(BarAreaData a, BarAreaData b, double t) =>
      BarAreaData(
        show: b.show,
        spotsLine: BarAreaSpotsLine.lerp(a.spotsLine, b.spotsLine, t),
        color: Color.lerp(a.color, b.color, t),
        gradient: Gradient.lerp(a.gradient, b.gradient, t),
        cutOffY: lerpDouble(a.cutOffY, b.cutOffY, t)!,
        applyCutOffY: b.applyCutOffY,
      );

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        show,
        color,
        gradient,
        spotsLine,
        cutOffY,
        applyCutOffY,
      ];
}

/// Holds data about filling below or above space of the bar line,
class BetweenBarsData with EquatableMixin {
  BetweenBarsData({
    required this.fromIndex,
    required this.toIndex,
    Color? color,
    this.gradient,
  }) : color = color ??
            ((color == null && gradient == null)
                ? Colors.blueGrey.withValues(alpha: 0.5)
                : null);

  /// The index of the lineBarsData from where the area has to be rendered
  final int fromIndex;

  /// The index of the lineBarsData until where the area has to be rendered
  final int toIndex;

  /// If provided, this [BetweenBarsData] draws with this [color]
  /// Otherwise we use  [gradient] to draw the background.
  /// It throws an exception if you provide both [color] and [gradient]
  final Color? color;

  /// If provided, this [BetweenBarsData] draws with this [gradient].
  /// Otherwise we use [color] to draw the background.
  /// It throws an exception if you provide both [color] and [gradient]
  final Gradient? gradient;

  /// Lerps a [BetweenBarsData] based on [t] value, check [Tween.lerp].
  static BetweenBarsData lerp(BetweenBarsData a, BetweenBarsData b, double t) {
    return BetweenBarsData(
      fromIndex: b.fromIndex,
      toIndex: b.toIndex,
      color: Color.lerp(a.color, b.color, t),
      gradient: Gradient.lerp(a.gradient, b.gradient, t),
    );
  }

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        fromIndex,
        toIndex,
        color,
        gradient,
      ];
}

/// Holds data for drawing line on the spots under the [BarAreaData].
class BarAreaSpotsLine with EquatableMixin {
  /// If [show] is true, [LineChart] draws some lines on above or below the spots,
  /// you can customize the appearance of the lines using [flLineStyle]
  /// and you can decide to show or hide the lines on each spot using [checkToShowSpotLine].
  const BarAreaSpotsLine({
    this.show = false,
    this.flLineStyle = const FlLine(),
    this.checkToShowSpotLine = showAllSpotsBelowLine,
    this.applyCutOffY = true,
  });

  /// Determines to show or hide all the lines.
  final bool show;

  /// Holds appearance of drawing line on the spots.
  final FlLine flLineStyle;

  /// Checks to show or hide lines on the spots.
  final CheckToShowSpotLine checkToShowSpotLine;

  /// Determines to inherit the cutOff properties from its parent [BarAreaData]
  final bool applyCutOffY;

  /// Lerps a [BarAreaSpotsLine] based on [t] value, check [Tween.lerp].
  static BarAreaSpotsLine lerp(
    BarAreaSpotsLine a,
    BarAreaSpotsLine b,
    double t,
  ) =>
      BarAreaSpotsLine(
        show: b.show,
        checkToShowSpotLine: b.checkToShowSpotLine,
        flLineStyle: FlLine.lerp(a.flLineStyle, b.flLineStyle, t),
        applyCutOffY: b.applyCutOffY,
      );

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        show,
        flLineStyle,
        checkToShowSpotLine,
        applyCutOffY,
      ];
}

/// It used for determine showing or hiding [BarAreaSpotsLine]s
///
/// Gives you the checking spot, and you have to decide to
/// show or not show the line on the provided spot.
typedef CheckToShowSpotLine = bool Function(FlSpot spot);

/// Shows all spot lines.
bool showAllSpotsBelowLine(FlSpot spot) => true;

/// The callback passed to get the color of a [FlSpot]
///
/// The callback receives [FlSpot], which is the target spot,
/// [double] is the percentage of spot along the bar line,
/// [LineChartBarData] is the chart's bar.
/// It should return a [Color] that needs to be used for drawing target.
typedef GetDotColorCallback = Color Function(FlSpot, double, LineChartBarData);

/// If there is one color in [LineChartBarData.mainColors], it returns that color,
/// otherwise it returns the color along the gradient colors based on the [xPercentage].
Color _defaultGetDotColor(FlSpot _, double xPercentage, LineChartBarData bar) {
  if (bar.gradient != null && bar.gradient is LinearGradient) {
    return lerpGradient(
      bar.gradient!.colors,
      bar.gradient!.getSafeColorStops(),
      xPercentage / 100,
    );
  }
  return bar.gradient?.colors.first ?? bar.color ?? Colors.blueGrey;
}

/// If there is one color in [LineChartBarData.mainColors], it returns that color in a darker mode,
/// otherwise it returns the color along the gradient colors based on the [xPercentage] in a darker mode.
Color _defaultGetDotStrokeColor(
  FlSpot spot,
  double xPercentage,
  LineChartBarData bar,
) {
  Color color;
  if (bar.gradient != null && bar.gradient is LinearGradient) {
    color = lerpGradient(
      bar.gradient!.colors,
      bar.gradient!.getSafeColorStops(),
      xPercentage / 100,
    );
  } else {
    color = bar.gradient?.colors.first ?? bar.color ?? Colors.blueGrey;
  }
  return color.darken();
}

/// The callback passed to get the painter of a [FlSpot]
///
/// The callback receives [FlSpot], which is the target spot,
/// [LineChartBarData] is the chart's bar.
/// [int] is the index position of the spot.
/// It should return a [FlDotPainter] that needs to be used for drawing target.
typedef GetDotPainterCallback = FlDotPainter Function(
  FlSpot,
  double,
  LineChartBarData,
  int,
);

FlDotPainter _defaultGetDotPainter(
  FlSpot spot,
  double xPercentage,
  LineChartBarData bar,
  int index, {
  double? size,
}) =>
    FlDotCirclePainter(
      radius: size,
      color: _defaultGetDotColor(spot, xPercentage, bar),
      strokeColor: _defaultGetDotStrokeColor(spot, xPercentage, bar),
    );

/// This class holds data about drawing spot dots on the drawing bar line.
class FlDotData with EquatableMixin {
  /// set [show] false to prevent dots from drawing,
  /// if you want to show or hide dots in some spots,
  /// override [checkToShowDot] to handle it in your way.
  const FlDotData({
    this.show = true,
    this.checkToShowDot = showAllDots,
    this.getDotPainter = _defaultGetDotPainter,
  });

  /// Determines show or hide all dots.
  final bool show;

  /// Checks to show or hide an individual dot.
  final CheckToShowDot checkToShowDot;

  /// Callback which is called to set the painter of the given [FlSpot].
  /// The [FlSpot] is provided as parameter to this callback
  final GetDotPainterCallback getDotPainter;

  /// Lerps a [FlDotData] based on [t] value, check [Tween.lerp].
  static FlDotData lerp(FlDotData a, FlDotData b, double t) => FlDotData(
        show: b.show,
        checkToShowDot: b.checkToShowDot,
        getDotPainter: b.getDotPainter,
      );

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        show,
        checkToShowDot,
        getDotPainter,
      ];
}

/// It determines showing or hiding [FlDotData] on the spots.
///
/// It gives you the checking [FlSpot] and you should decide to
/// show or hide the dot on this spot by returning true or false.
typedef CheckToShowDot = bool Function(FlSpot spot, LineChartBarData barData);

/// Shows all dots on spots.
bool showAllDots(FlSpot spot, LineChartBarData barData) => true;

enum LabelDirection { horizontal, vertical }

/// Shows a text label
abstract class FlLineLabel with EquatableMixin {
  /// Draws a title on the line, align it with [alignment] over the line,
  /// applies [padding] for spaces, and applies [style] for changing color,
  /// size, ... of the text.
  /// [show] determines showing label or not.
  /// [direction] determines if the direction of the text should be horizontal or vertical.
  const FlLineLabel({
    required this.show,
    required this.padding,
    required this.style,
    required this.alignment,
    required this.direction,
  });

  /// Determines showing label or not.
  final bool show;

  /// Inner spaces around the drawing text.
  final EdgeInsetsGeometry padding;

  /// Sets style of the drawing text.
  final TextStyle? style;

  /// Aligns the text on the line.
  final Alignment alignment;

  /// Determines the direction of the text.
  final LabelDirection direction;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        show,
        padding,
        style,
        alignment,
        direction,
      ];
}

/// Holds data to handle touch events, and touch responses in the [LineChart].
///
/// There is a touch flow, explained [here](https://github.com/imaNNeo/fl_chart/blob/main/repo_files/documentations/handle_touches.md)
/// in a simple way, each chart's renderer captures the touch events, and passes the pointerEvent
/// to the painter, and gets touched spot, and wraps it into a concrete [LineTouchResponse].
class LineTouchData extends FlTouchData<LineTouchResponse> with EquatableMixin {
  /// You can disable or enable the touch system using [enabled] flag,
  ///
  /// [touchCallback] notifies you about the happened touch/pointer events.
  /// It gives you a [FlTouchEvent] which is the happened event such as [FlPointerHoverEvent], [FlTapUpEvent], ...
  /// It also gives you a [LineTouchResponse] which contains information
  /// about the elements that has touched.
  ///
  /// Using [mouseCursorResolver] you can change the mouse cursor
  /// based on the provided [FlTouchEvent] and [LineTouchResponse]
  ///
  /// if [handleBuiltInTouches] is true, [LineChart] shows a tooltip popup on top of the spots if
  /// touch occurs (or you can show it manually using, [LineChartData.showingTooltipIndicators])
  /// and also it shows an indicator (contains a thicker line and larger dot on the targeted spot),
  /// You can define how this indicator looks like through [getTouchedSpotIndicator] callback,
  /// You can customize this tooltip using [touchTooltipData], indicator lines starts from position
  /// controlled by [getTouchLineStart] and ends at position controlled by [getTouchLineEnd].
  /// If you need to have a distance threshold for handling touches, use [touchSpotThreshold].
  /// 
  /// [backgroundBlockTooltipData] sets the appearance and behavior of background block tooltips.
  const LineTouchData({
    bool enabled = true,
    BaseTouchCallback<LineTouchResponse>? touchCallback,
    MouseCursorResolver<LineTouchResponse>? mouseCursorResolver,
    Duration? longPressDuration,
    this.touchTooltipData = const LineTouchTooltipData(),
    this.backgroundBlockTooltipData = const BackgroundBlockTooltipData(),
    this.getTouchedSpotIndicator = defaultTouchedIndicators,
    this.touchSpotThreshold = 10,
    this.distanceCalculator = _xDistance,
    this.handleBuiltInTouches = true,
    this.getTouchLineStart = defaultGetTouchLineStart,
    this.getTouchLineEnd = defaultGetTouchLineEnd,
  }) : super(
          enabled,
          touchCallback,
          mouseCursorResolver,
          longPressDuration,
        );

  /// Configs of how touch tooltip popup.
  final LineTouchTooltipData touchTooltipData;

  /// Configs of how background block tooltip popup appears.
  final BackgroundBlockTooltipData backgroundBlockTooltipData;

  /// Configs of how touch indicator looks like.
  final GetTouchedSpotIndicator getTouchedSpotIndicator;

  /// Distance threshold to handle the touch event.
  final double touchSpotThreshold;

  /// Distance function used when finding closest points to touch point
  final CalculateTouchDistance distanceCalculator;

  /// Determines to handle default built-in touch responses,
  /// [LineTouchResponse] shows a tooltip popup above the touched spot.
  final bool handleBuiltInTouches;

  /// The starting point on y axis of the touch line. By default, line starts on the bottom of
  /// the chart.
  final GetTouchLineY getTouchLineStart;

  /// The end point on y axis of the touch line. By default, line ends at the touched point.
  /// If line end is overlap with the dot, it will be automatically adjusted to the edge of the dot.
  final GetTouchLineY getTouchLineEnd;

  /// Copies current [LineTouchData] to a new [LineTouchData],
  /// and replaces provided values.
  LineTouchData copyWith({
    bool? enabled,
    BaseTouchCallback<LineTouchResponse>? touchCallback,
    MouseCursorResolver<LineTouchResponse>? mouseCursorResolver,
    Duration? longPressDuration,
    LineTouchTooltipData? touchTooltipData,
    BackgroundBlockTooltipData? backgroundBlockTooltipData,
    GetTouchedSpotIndicator? getTouchedSpotIndicator,
    double? touchSpotThreshold,
    CalculateTouchDistance? distanceCalculator,
    GetTouchLineY? getTouchLineStart,
    GetTouchLineY? getTouchLineEnd,
    bool? handleBuiltInTouches,
  }) =>
      LineTouchData(
        enabled: enabled ?? this.enabled,
        touchCallback: touchCallback ?? this.touchCallback,
        mouseCursorResolver: mouseCursorResolver ?? this.mouseCursorResolver,
        longPressDuration: longPressDuration ?? this.longPressDuration,
        touchTooltipData: touchTooltipData ?? this.touchTooltipData,
        backgroundBlockTooltipData: backgroundBlockTooltipData ?? this.backgroundBlockTooltipData,
        getTouchedSpotIndicator:
            getTouchedSpotIndicator ?? this.getTouchedSpotIndicator,
        touchSpotThreshold: touchSpotThreshold ?? this.touchSpotThreshold,
        distanceCalculator: distanceCalculator ?? this.distanceCalculator,
        getTouchLineStart: getTouchLineStart ?? this.getTouchLineStart,
        getTouchLineEnd: getTouchLineEnd ?? this.getTouchLineEnd,
        handleBuiltInTouches: handleBuiltInTouches ?? this.handleBuiltInTouches,
      );

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        enabled,
        touchCallback,
        mouseCursorResolver,
        longPressDuration,
        touchTooltipData,
        backgroundBlockTooltipData,
        getTouchedSpotIndicator,
        touchSpotThreshold,
        distanceCalculator,
        handleBuiltInTouches,
        getTouchLineStart,
        getTouchLineEnd,
      ];
}

/// Used for showing touch indicators (a thicker line and larger dot on the targeted spot).
///
/// It gives you the [spotIndexes] that touch happened, or manually targeted,
/// in the given [barData], you should return a list of [TouchedSpotIndicatorData],
/// length of this list should be equal to the [spotIndexes.length],
/// each [TouchedSpotIndicatorData] determines the look of showing indicator.
typedef GetTouchedSpotIndicator = List<TouchedSpotIndicatorData?> Function(
  LineChartBarData barData,
  List<int> spotIndexes,
);

/// Used for determine the touch indicator line's starting/end point.
typedef GetTouchLineY = double Function(
  LineChartBarData barData,
  int spotIndex,
);

/// Used to calculate the distance between coordinates of a touch event and a spot
typedef CalculateTouchDistance = double Function(
  Offset touchPoint,
  Offset spotPixelCoordinates,
);

/// Default distanceCalculator only considers distance on x axis
double _xDistance(Offset touchPoint, Offset spotPixelCoordinates) =>
    (touchPoint.dx - spotPixelCoordinates.dx).abs();

/// Default presentation of touched indicators.
List<TouchedSpotIndicatorData> defaultTouchedIndicators(
  LineChartBarData barData,
  List<int> indicators,
) =>
    indicators.map((int index) {
      /// Indicator Line
      var lineColor = barData.gradient?.colors.first ?? barData.color;
      if (barData.dotData.show) {
        lineColor = _defaultGetDotColor(barData.spots[index], 0, barData);
      }
      const lineStrokeWidth = 4.0;
      final flLine = FlLine(color: lineColor, strokeWidth: lineStrokeWidth);

      var dotSize = 10.0;
      if (barData.dotData.show) {
        dotSize = 4.0 * 1.8;
      }

      final dotData = FlDotData(
        getDotPainter: (spot, percent, bar, index) =>
            _defaultGetDotPainter(spot, percent, bar, index, size: dotSize),
      );

      return TouchedSpotIndicatorData(flLine, dotData);
    }).toList();

/// By default line starts from the bottom of the chart.
double defaultGetTouchLineStart(LineChartBarData barData, int spotIndex) {
  return -double.infinity;
}

/// By default line ends at the touched point.
double defaultGetTouchLineEnd(LineChartBarData barData, int spotIndex) =>
    barData.spots[spotIndex].y;

/// Holds representation data for showing tooltip popup on top of spots.
class LineTouchTooltipData with EquatableMixin {
  /// if [LineTouchData.handleBuiltInTouches] is true,
  /// [LineChart] shows a tooltip popup on top of spots automatically when touch happens,
  /// otherwise you can show it manually using [LineChartData.showingTooltipIndicators].
  /// Tooltip shows on top of rods, with [getTooltipColor] as a background color.
  /// You can set the corner radius using [tooltipBorderRadius],
  /// If you want to have a padding inside the tooltip, fill [tooltipPadding],
  /// or If you want to have a bottom margin, set [tooltipMargin].
  /// Content of the tooltip will provide using [getTooltipItems] callback, you can override it
  /// and pass your custom data to show in the tooltip.
  /// You can restrict the tooltip's width using [maxContentWidth].
  /// Sometimes, [LineChart] shows the tooltip outside of the chart,
  /// you can set [fitInsideHorizontally] true to force it to shift inside the chart horizontally,
  /// also you can set [fitInsideVertically] true to force it to shift inside the chart vertically.
  const LineTouchTooltipData({
    BorderRadius? tooltipBorderRadius,
    this.tooltipPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.tooltipMargin = 16,
    this.tooltipHorizontalAlignment = FLHorizontalAlignment.center,
    this.tooltipHorizontalOffset = 0,
    this.maxContentWidth = 120,
    this.getTooltipItems = defaultLineTooltipItem,
    this.getTooltipColor = defaultLineTooltipColor,
    this.fitInsideHorizontally = false,
    this.fitInsideVertically = false,
    this.showOnTopOfTheChartBoxArea = false,
    this.rotateAngle = 0.0,
    this.tooltipBorder = BorderSide.none,
  }) : _tooltipBorderRadius = tooltipBorderRadius;

  /// Sets a rounded radius for the tooltip.
  final BorderRadius? _tooltipBorderRadius;

  /// Sets a rounded radius for the tooltip.
  BorderRadius get tooltipBorderRadius =>
      _tooltipBorderRadius ?? BorderRadius.circular(4);

  /// Applies a padding for showing contents inside the tooltip.
  final EdgeInsets tooltipPadding;

  /// Applies a bottom margin for showing tooltip on top of rods.
  final double tooltipMargin;

  /// Controls showing tooltip on left side, right side or center aligned with spot, default is center
  final FLHorizontalAlignment tooltipHorizontalAlignment;

  /// Applies horizontal offset for showing tooltip, default is zero.
  final double tooltipHorizontalOffset;

  /// Restricts the tooltip's width.
  final double maxContentWidth;

  /// Retrieves data for showing content inside the tooltip.
  final GetLineTooltipItems getTooltipItems;

  /// Forces the tooltip to shift horizontally inside the chart, if overflow happens.
  final bool fitInsideHorizontally;

  /// Forces the tooltip to shift vertically inside the chart, if overflow happens.
  final bool fitInsideVertically;

  /// Forces the tooltip container to top of the line, default 'false'
  final bool showOnTopOfTheChartBoxArea;

  /// Controls the rotation of the tooltip.
  final double rotateAngle;

  /// The tooltip border color.
  final BorderSide tooltipBorder;

  // /// Retrieves data for setting background color of the tooltip.
  final GetLineTooltipColor getTooltipColor;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        _tooltipBorderRadius,
        tooltipPadding,
        tooltipMargin,
        tooltipHorizontalAlignment,
        tooltipHorizontalOffset,
        maxContentWidth,
        getTooltipItems,
        fitInsideHorizontally,
        fitInsideVertically,
        showOnTopOfTheChartBoxArea,
        rotateAngle,
        tooltipBorder,
        getTooltipColor,
      ];
}

/// Provides a [LineTooltipItem] for showing content inside the [LineTouchTooltipData].
///
/// You can override [LineTouchTooltipData.getTooltipItems], it gives you
/// [touchedSpots] list that touch happened on,
/// then you should and pass your custom [LineTooltipItem] list
/// (length should be equal to the [touchedSpots.length]),
/// to show inside the tooltip popup.
typedef GetLineTooltipItems = List<LineTooltipItem?> Function(
  List<LineBarSpot> touchedSpots,
);

/// Default implementation for [LineTouchTooltipData.getTooltipItems].
List<LineTooltipItem> defaultLineTooltipItem(List<LineBarSpot> touchedSpots) =>
    touchedSpots.map((LineBarSpot touchedSpot) {
      final textStyle = TextStyle(
        color: touchedSpot.bar.gradient?.colors.first ??
            touchedSpot.bar.color ??
            Colors.blueGrey,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      );
      return LineTooltipItem(touchedSpot.y.toString(), textStyle);
    }).toList();

//// Provides a [Color] to show different background color for each touched spot
///
/// You can override [LineTouchTooltipData.getTooltipColor], it gives you
/// [touchedSpot] object that touch happened on, then you should and pass your custom [Color] list
/// (length should be equal to the [touchedSpots.length]), to set background color
/// of tooltip popup.
typedef GetLineTooltipColor = Color Function(
  LineBarSpot touchedSpot,
);

/// Default implementation for [LineTouchTooltipData.getTooltipColor].
Color defaultLineTooltipColor(LineBarSpot touchedSpot) =>
    Colors.blueGrey.darken(15);

/// Represent a targeted spot inside a line bar.
class LineBarSpot extends FlSpot with EquatableMixin {
  /// [bar] is the [LineChartBarData] that this spot is inside of,
  /// [barIndex] is the index of our [bar], in the [LineChartData.lineBarsData] list,
  /// [spot] is the targeted spot.
  /// [spotIndex] is the index this [FlSpot], in the [LineChartBarData.spots] list.
  LineBarSpot(
    this.bar,
    this.barIndex,
    FlSpot spot,
  )   : spotIndex = bar.spots.indexOf(spot),
        super(spot.x, spot.y);

  /// Is the [LineChartBarData] that this spot is inside of.
  final LineChartBarData bar;

  /// Is the index of our [bar], in the [LineChartData.lineBarsData] list,
  final int barIndex;

  /// Is the index of our [super.spot], in the [LineChartBarData.spots] list.
  final int spotIndex;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        bar,
        barIndex,
        spotIndex,
        x,
        y,
      ];
}

/// A [LineBarSpot] that holds information about the event that selected it
class TouchLineBarSpot extends LineBarSpot {
  TouchLineBarSpot(
    super.bar,
    super.barIndex,
    super.spot,
    this.distance,
  );

  /// Distance in pixels from where the user taped
  final double distance;
}

/// Holds data of showing each row item in the tooltip popup.
class LineTooltipItem with EquatableMixin {
  /// Shows a [text] with [textStyle], [textDirection],
  /// and optional [children] as a row in the tooltip popup.
  const LineTooltipItem(
    this.text,
    this.textStyle, {
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.ltr,
    this.children,
  });

  /// Showing text.
  final String text;

  /// Style of showing text.
  final TextStyle textStyle;

  /// Align of showing text.
  final TextAlign textAlign;

  /// Direction of showing text.
  final TextDirection textDirection;

  /// Add further style and format to the text of the tooltip
  final List<TextSpan>? children;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        text,
        textStyle,
        textAlign,
        textDirection,
        children,
      ];
}

/// details of showing indicator when touch happened on [LineChart]
/// [indicatorBelowLine] we draw a vertical line below of the touched spot
/// [touchedSpotDotData] we draw a larger dot on the touched spot to bold it
class TouchedSpotIndicatorData with EquatableMixin {
  /// if [LineTouchData.handleBuiltInTouches] is true,
  /// [LineChart] shows a thicker line and larger spot as indicator automatically when touch happens,
  /// otherwise you can show it manually using [LineChartBarData.showingIndicators].
  /// [indicatorBelowLine] determines line's style, and
  /// [touchedSpotDotData] determines dot's style.
  const TouchedSpotIndicatorData(
    this.indicatorBelowLine,
    this.touchedSpotDotData,
  );

  /// Determines line's style.
  final FlLine indicatorBelowLine;

  /// Determines dot's style.
  final FlDotData touchedSpotDotData;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [
        indicatorBelowLine,
        touchedSpotDotData,
      ];
}

/// Holds data for showing tooltips over a line
class ShowingTooltipIndicators with EquatableMixin {
  /// [LineChart] shows some tooltips over each [LineChartBarData],
  /// and [showingSpots] determines in which spots this tooltip should be shown.
  const ShowingTooltipIndicators(this.showingSpots);

  /// Determines the spots that each tooltip should be shown.
  final List<LineBarSpot> showingSpots;

  /// Used for equality check, see [EquatableMixin].
  @override
  List<Object?> get props => [showingSpots];
}

/// Holds information about touch response in the [LineChart].
///
/// You can override [LineTouchData.touchCallback] to handle touch events,
/// it gives you a [LineTouchResponse] and you can do whatever you want.
class LineTouchResponse extends AxisBaseTouchResponse {
  /// If touch happens, [LineChart] processes it internally and
  /// passes out a list of [lineBarSpots] it gives you information about the touched spot.
  /// They are sorted based on their distance to the touch event
  LineTouchResponse({
    required super.touchLocation,
    required super.touchChartCoordinate,
    this.lineBarSpots,
    this.touchedBackgroundBlock,
  });

  /// touch happened on these spots
  /// (if a single line provided on the chart, [lineBarSpots]'s length will be 1 always)
  final List<TouchLineBarSpot>? lineBarSpots;

  /// 被觸碰的背景區塊
  final TouchedBackgroundBlock? touchedBackgroundBlock;

  /// Copies current [LineTouchResponse] to a new [LineTouchResponse],
  /// and replaces provided values.
  LineTouchResponse copyWith({
    Offset? touchLocation,
    Offset? touchChartCoordinate,
    List<TouchLineBarSpot>? lineBarSpots,
    TouchedBackgroundBlock? touchedBackgroundBlock,
  }) =>
      LineTouchResponse(
        touchLocation: touchLocation ?? this.touchLocation,
        touchChartCoordinate: touchChartCoordinate ?? this.touchChartCoordinate,
        lineBarSpots: lineBarSpots ?? this.lineBarSpots,
        touchedBackgroundBlock: touchedBackgroundBlock ?? this.touchedBackgroundBlock,
      );
}

/// It is the input of the [GetSpotRangeErrorPainter] callback in
/// the [LineChartData.errorIndicatorData]
///
/// So it contains the information about the spot, and the bar that the spot
/// is in. The callback should return a [FlSpotErrorRangePainter] that will draw
/// the error bars
class LineChartSpotErrorRangeCallbackInput
    extends FlSpotErrorRangeCallbackInput {
  LineChartSpotErrorRangeCallbackInput({
    required this.spot,
    required this.bar,
    required this.spotIndex,
  });

  final FlSpot spot;
  final LineChartBarData bar;
  final int spotIndex;

  @override
  List<Object?> get props => [
        spot,
        bar,
        spotIndex,
      ];
}

/// It lerps a [LineChartData] to another [LineChartData] (handles animation for updating values)
class LineChartDataTween extends Tween<LineChartData> {
  LineChartDataTween({required super.begin, required super.end});

  /// Lerps a [LineChartData] based on [t] value, check [Tween.lerp].
  @override
  LineChartData lerp(double t) => begin!.lerp(begin!, end!, t);
}

// 簡化 BackgroundBlockData 類別

/// 定義背景區塊資料
class BackgroundBlockData with EquatableMixin {
  /// 建立背景區塊
  /// [startX] 是區塊的起始 X 座標
  /// [endX] 是區塊的結束 X 座標
  /// [color] 是區塊的顏色，如果同時提供 [gradient] 則會拋出例外
  /// [gradient] 是區塊的漸層色彩，如果同時提供 [color] 則會拋出例外
  /// [show] 決定是否顯示此區塊
  /// [label] 是區塊的標籤，會顯示在 tooltip 中
  /// [data] 可以存放任意自定義資料，用於 tooltip 回調函式
  /// [iconWidget] 是要在區塊中心顯示的 Widget 圖示
  /// [iconSize] 是圖示的尺寸
  /// [showIconMinWidth] 是顯示圖示所需的最小區塊像素寬度
  BackgroundBlockData({
    required this.startX,
    required this.endX,
    Color? color,
    this.gradient,
    this.show = true,
    this.label,
    this.data,
    this.iconWidget,
    this.iconSize = const Size(24, 24),
    this.showIconMinWidth = 60.0,
  }) : color = color ??
            ((color == null && gradient == null)
                ? Colors.grey.withValues(alpha: 0.2)
                : null) {
    if (color != null && gradient != null) {
      throw ArgumentError('不能同時提供 color 和 gradient');
    }
  }

  /// 區塊的起始 X 座標
  final double startX;

  /// 區塊的結束 X 座標
  final double endX;

  /// 區塊的顏色
  final Color? color;

  /// 區塊的漸層色彩
  final Gradient? gradient;

  /// 是否顯示區塊
  final bool show;

  /// 區塊的標籤（可選）
  final String? label;

  /// 自定義資料（可選），可用於 tooltip 顯示
  final Map<String, dynamic>? data;

  /// 要在區塊中心顯示的 Widget 圖示（可選）
  final Widget? iconWidget;

  /// 圖示的尺寸約束
  final Size iconSize;

  /// 顯示圖示所需的最小區塊像素寬度
  /// 當區塊的像素寬度小於此值時，將不會顯示圖示
  final double showIconMinWidth;

  /// 複製當前 [BackgroundBlockData] 並替換提供的值
  BackgroundBlockData copyWith({
    double? startX,
    double? endX,
    Color? color,
    Gradient? gradient,
    bool? show,
    String? label,
    Map<String, dynamic>? data,
    Widget? iconWidget,
    Size? iconSize,
    double? showIconMinWidth,
  }) =>
      BackgroundBlockData(
        startX: startX ?? this.startX,
        endX: endX ?? this.endX,
        color: color ?? this.color,
        gradient: gradient ?? this.gradient,
        show: show ?? this.show,
        label: label ?? this.label,
        data: data ?? this.data,
        iconWidget: iconWidget ?? this.iconWidget,
        iconSize: iconSize ?? this.iconSize,
        showIconMinWidth: showIconMinWidth ?? this.showIconMinWidth,
      );

  /// 線性插值
  static BackgroundBlockData lerp(
    BackgroundBlockData a,
    BackgroundBlockData b,
    double t,
  ) =>
      BackgroundBlockData(
        startX: lerpDouble(a.startX, b.startX, t) ?? 0,
        endX: lerpDouble(a.endX, b.endX, t) ?? 0,
        color: Color.lerp(a.color, b.color, t),
        gradient: Gradient.lerp(a.gradient, b.gradient, t),
        show: b.show,
        label: b.label,
        data: b.data,
        iconWidget: b.iconWidget, // Widget 不進行插值
        iconSize: Size.lerp(a.iconSize, b.iconSize, t) ?? b.iconSize,
        showIconMinWidth: lerpDouble(a.showIconMinWidth, b.showIconMinWidth, t) ?? b.showIconMinWidth,
      );

  @override
  List<Object?> get props => [
        startX,
        endX,
        color,
        gradient,
        show,
        label,
        data,
        iconWidget,
        iconSize,
        showIconMinWidth,
      ];
}

/// 提供動態 tooltip 對齊方式的回調函式類型
typedef GetTooltipAlignment = FLHorizontalAlignment Function(
  TouchedBackgroundBlock touchedBlock,
  Size chartSize,
);

/// 提供動態 tooltip 水平偏移的回調函式類型
typedef GetTooltipHorizontalOffset = double Function(
  TouchedBackgroundBlock touchedBlock,
  Size chartSize,
);

/// 背景區塊的 tooltip 資料
class BackgroundBlockTooltipData with EquatableMixin {
  /// 建立背景區塊的 tooltip 資料
  const BackgroundBlockTooltipData({
    this.getTooltipItems = defaultBackgroundBlockTooltipItem,
    this.getTooltipColor = defaultBackgroundBlockTooltipColor,
    this.getTooltipAlignment,
    this.getTooltipHorizontalOffset,
    BorderRadius? tooltipBorderRadius,
    this.tooltipPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.tooltipMargin = 16,
    this.tooltipHorizontalAlignment = FLHorizontalAlignment.center,
    this.tooltipHorizontalOffset = 0,
    this.maxContentWidth = 200,
    this.fitInsideHorizontally = true,
    this.fitInsideVertically = true,
    this.showOnTopOfTheChartBoxArea = true,
    this.rotateAngle = 0.0,
    this.tooltipBorder = BorderSide.none,
  }) : _tooltipBorderRadius = tooltipBorderRadius;

  /// 取得 tooltip 項目的回調函式
  final GetBackgroundBlockTooltipItems getTooltipItems;

  /// 取得 tooltip 背景顏色的回調函式
  final GetBackgroundBlockTooltipColor getTooltipColor;

  /// 動態取得 tooltip 水平對齊方式的回調函式（優先於 tooltipHorizontalAlignment）
  final GetTooltipAlignment? getTooltipAlignment;

  /// 動態取得 tooltip 水平偏移的回調函式（優先於 tooltipHorizontalOffset）
  final GetTooltipHorizontalOffset? getTooltipHorizontalOffset;

  /// 設定 tooltip 的圓角半徑
  final BorderRadius? _tooltipBorderRadius;

  /// 取得 tooltip 的圓角半徑
  BorderRadius get tooltipBorderRadius =>
      _tooltipBorderRadius ?? BorderRadius.circular(4);

  /// tooltip 內部的邊距
  final EdgeInsets tooltipPadding;

  /// tooltip 與觸碰點的距離
  final double tooltipMargin;

  /// tooltip 水平對齊方式
  final FLHorizontalAlignment tooltipHorizontalAlignment;

  /// tooltip 水平偏移量
  final double tooltipHorizontalOffset;

  /// tooltip 最大寬度
  final double maxContentWidth;

  /// 是否強制 tooltip 保持在水平邊界內
  final bool fitInsideHorizontally;

  /// 是否強制 tooltip 保持在垂直邊界內
  final bool fitInsideVertically;

  /// 是否將 tooltip 顯示在圖表區域頂部
  final bool showOnTopOfTheChartBoxArea;

  /// tooltip 旋轉角度
  final double rotateAngle;

  /// tooltip 邊框樣式
  final BorderSide tooltipBorder;

  /// 複製並替換指定值
  BackgroundBlockTooltipData copyWith({
    GetBackgroundBlockTooltipItems? getTooltipItems,
    GetBackgroundBlockTooltipColor? getTooltipColor,
    GetTooltipAlignment? getTooltipAlignment,
    GetTooltipHorizontalOffset? getTooltipHorizontalOffset,
    BorderRadius? tooltipBorderRadius,
    EdgeInsets? tooltipPadding,
    double? tooltipMargin,
    FLHorizontalAlignment? tooltipHorizontalAlignment,
    double? tooltipHorizontalOffset,
    double? maxContentWidth,
    bool? fitInsideHorizontally,
    bool? fitInsideVertically,
    bool? showOnTopOfTheChartBoxArea,
    double? rotateAngle,
    BorderSide? tooltipBorder,
  }) =>
      BackgroundBlockTooltipData(
        getTooltipItems: getTooltipItems ?? this.getTooltipItems,
        getTooltipColor: getTooltipColor ?? this.getTooltipColor,
        getTooltipAlignment: getTooltipAlignment ?? this.getTooltipAlignment,
        getTooltipHorizontalOffset: getTooltipHorizontalOffset ?? this.getTooltipHorizontalOffset,
        tooltipBorderRadius: tooltipBorderRadius ?? _tooltipBorderRadius,
        tooltipPadding: tooltipPadding ?? this.tooltipPadding,
        tooltipMargin: tooltipMargin ?? this.tooltipMargin,
        tooltipHorizontalAlignment: tooltipHorizontalAlignment ?? this.tooltipHorizontalAlignment,
        tooltipHorizontalOffset: tooltipHorizontalOffset ?? this.tooltipHorizontalOffset,
        maxContentWidth: maxContentWidth ?? this.maxContentWidth,
        fitInsideHorizontally: fitInsideHorizontally ?? this.fitInsideHorizontally,
        fitInsideVertically: fitInsideVertically ?? this.fitInsideVertically,
        showOnTopOfTheChartBoxArea: showOnTopOfTheChartBoxArea ?? this.showOnTopOfTheChartBoxArea,
        rotateAngle: rotateAngle ?? this.rotateAngle,
        tooltipBorder: tooltipBorder ?? this.tooltipBorder,
      );

  /// 線性插值
  static BackgroundBlockTooltipData? lerp(
    BackgroundBlockTooltipData? a,
    BackgroundBlockTooltipData? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;

    return BackgroundBlockTooltipData(
      getTooltipItems: b.getTooltipItems,
      getTooltipColor: b.getTooltipColor,
      getTooltipAlignment: b.getTooltipAlignment,
      getTooltipHorizontalOffset: b.getTooltipHorizontalOffset,
      tooltipBorderRadius: BorderRadius.lerp(a._tooltipBorderRadius, b._tooltipBorderRadius, t),
      tooltipPadding: EdgeInsets.lerp(a.tooltipPadding, b.tooltipPadding, t) ?? b.tooltipPadding,
      tooltipMargin: lerpDouble(a.tooltipMargin, b.tooltipMargin, t) ?? b.tooltipMargin,
      tooltipHorizontalAlignment: b.tooltipHorizontalAlignment,
      tooltipHorizontalOffset: lerpDouble(a.tooltipHorizontalOffset, b.tooltipHorizontalOffset, t) ?? b.tooltipHorizontalOffset,
      maxContentWidth: lerpDouble(a.maxContentWidth, b.maxContentWidth, t) ?? b.maxContentWidth,
      fitInsideHorizontally: b.fitInsideHorizontally,
      fitInsideVertically: b.fitInsideVertically,
      showOnTopOfTheChartBoxArea: b.showOnTopOfTheChartBoxArea,
      rotateAngle: lerpDouble(a.rotateAngle, b.rotateAngle, t) ?? b.rotateAngle,
      tooltipBorder: BorderSide.lerp(a.tooltipBorder, b.tooltipBorder, t),
    );
  }

  @override
  List<Object?> get props => [
        getTooltipItems,
        getTooltipColor,
        getTooltipAlignment,
        getTooltipHorizontalOffset,
        _tooltipBorderRadius,
        tooltipPadding,
        tooltipMargin,
        tooltipHorizontalAlignment,
        tooltipHorizontalOffset,
        maxContentWidth,
        fitInsideHorizontally,
        fitInsideVertically,
        showOnTopOfTheChartBoxArea,
        rotateAngle,
        tooltipBorder,
      ];
}

/// 提供背景區塊 tooltip 項目的回調函式類型
typedef GetBackgroundBlockTooltipItems = List<BackgroundBlockTooltipItem?> Function(
  TouchedBackgroundBlock touchedBlock,
);

/// 提供背景區塊 tooltip 背景顏色的回調函式類型
typedef GetBackgroundBlockTooltipColor = Color Function(
  TouchedBackgroundBlock touchedBlock,
);

/// 預設的背景區塊 tooltip 項目實作
List<BackgroundBlockTooltipItem> defaultBackgroundBlockTooltipItem(
  TouchedBackgroundBlock touchedBlock,
) {
  final blockData = touchedBlock.blockData;

  // 優先使用標籤，如果沒有標籤則使用座標範圍
  String text;
  if (blockData.label != null && blockData.label!.isNotEmpty) {
    text = blockData.label!;
  } else {
    text =
        '${blockData.startX.toStringAsFixed(1)} - ${blockData.endX.toStringAsFixed(1)}';
  }

  return [
    BackgroundBlockTooltipItem(
      text,
      const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
  ];
}

/// 預設的背景區塊 tooltip 背景顏色實作
Color defaultBackgroundBlockTooltipColor(TouchedBackgroundBlock touchedBlock) {
  final blockData = touchedBlock.blockData;
  
  // 根據區塊顏色自動決定 tooltip 背景色
  if (blockData.color != null) {
    // 使用區塊顏色的深色版本
    return blockData.color!.withValues(alpha: 0.9);
  } else if (blockData.gradient != null && blockData.gradient!.colors.isNotEmpty) {
    // 使用漸層第一個顏色的深色版本
    return blockData.gradient!.colors.first.withValues(alpha: 0.9);
  }
  
  return Colors.black87;
}

/// 背景區塊 tooltip 項目資料
class BackgroundBlockTooltipItem with EquatableMixin {
  /// 建立背景區塊 tooltip 項目
  const BackgroundBlockTooltipItem(
    this.text,
    this.textStyle, {
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.ltr,
    this.children,
  });

  /// 顯示的文字
  final String text;

  /// 文字樣式
  final TextStyle textStyle;

  /// 文字對齊方式
  final TextAlign textAlign;

  /// 文字方向
  final TextDirection textDirection;

  /// 額外的文字樣式和格式
  final List<TextSpan>? children;

  @override
  List<Object?> get props => [
        text,
        textStyle,
        textAlign,
        textDirection,
        children,
      ];
}

/// 被觸碰的背景區塊資訊
class TouchedBackgroundBlock with EquatableMixin {
  /// 建立被觸碰的背景區塊資訊
  const TouchedBackgroundBlock({
    required this.blockData,
    required this.blockIndex,
    required this.touchX,
    this.chartMinX,
    this.chartMaxX,
    this.chartMinY,
    this.chartMaxY,
  });

  /// 被觸碰的背景區塊資料
  final BackgroundBlockData blockData;

  /// 區塊在清單中的索引
  final int blockIndex;

  /// 觸碰的 X 座標
  final double touchX;

  /// 圖表的最小 X 值（可選，用於更精確的對齊計算）
  final double? chartMinX;

  /// 圖表的最大 X 值（可選，用於更精確的對齊計算）
  final double? chartMaxX;

  /// 圖表的最小 Y 值（可選）
  final double? chartMinY;

  /// 圖表的最大 Y 值（可選）
  final double? chartMaxY;

  /// 計算觸碰點在圖表中的相對位置（0.0 到 1.0）
  double? get relativePositionX {
    if (chartMinX == null || chartMaxX == null) return null;
    final range = chartMaxX! - chartMinX!;
    if (range == 0) return 0.5;
    return (touchX - chartMinX!) / range;
  }

  @override
  List<Object?> get props => [blockIndex]; // 只比較 blockIndex，忽略 touchX 的變化

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TouchedBackgroundBlock) return false;
    
    // 只比較區塊索引，避免因為 touchX 微小變化造成閃爍
    return blockIndex == other.blockIndex;
  }

  @override
  int get hashCode => blockIndex.hashCode;
}

// 新增便利的建構函式和預設值

/// 常用的圖示尺寸常數
class BackgroundBlockIconSize {
  /// 小尺寸圖示
  static const Size small = Size(16, 16);
  
  /// 中等尺寸圖示
  static const Size medium = Size(24, 24);
  
  /// 大尺寸圖示
  static const Size large = Size(32, 32);
  
  /// 超大尺寸圖示
  static const Size extraLarge = Size(48, 48);
}

/// 預設的最小寬度常數
class BackgroundBlockMinWidth {
  /// 顯示小圖示的最小寬度
  static const double forSmallIcon = 40;
  
  /// 顯示中等圖示的最小寬度
  static const double forMediumIcon = 60;
  
  /// 顯示大圖示的最小寬度
  static const double forLargeIcon = 80;
  
  /// 顯示超大圖示的最小寬度
  static const double forExtraLargeIcon = 100;
}

/// BackgroundBlockData 的便利建構函式擴展
extension BackgroundBlockDataExtension on BackgroundBlockData {
  /// 建立帶有小 Widget 圖示的背景區塊
  static BackgroundBlockData withSmallIcon({
    required double startX,
    required double endX,
    required Widget iconWidget,
    Color? color,
    Gradient? gradient,
    bool show = true,
    String? label,
    Map<String, dynamic>? data,
  }) =>
      BackgroundBlockData(
        startX: startX,
        endX: endX,
        color: color,
        gradient: gradient,
        show: show,
        label: label,
        data: data,
        iconWidget: iconWidget,
        iconSize: BackgroundBlockIconSize.small,
        showIconMinWidth: BackgroundBlockMinWidth.forSmallIcon,
      );

  /// 建立帶有中等 Widget 圖示的背景區塊
  static BackgroundBlockData withMediumIcon({
    required double startX,
    required double endX,
    required Widget iconWidget,
    Color? color,
    Gradient? gradient,
    bool show = true,
    String? label,
    Map<String, dynamic>? data,
  }) =>
      BackgroundBlockData(
        startX: startX,
        endX: endX,
        color: color,
        gradient: gradient,
        show: show,
        label: label,
        data: data,
        iconWidget: iconWidget,
      );

  /// 建立帶有大 Widget 圖示的背景區塊
  static BackgroundBlockData withLargeIcon({
    required double startX,
    required double endX,
    required Widget iconWidget,
    Color? color,
    Gradient? gradient,
    bool show = true,
    String? label,
    Map<String, dynamic>? data,
  }) =>
      BackgroundBlockData(
        startX: startX,
        endX: endX,
        color: color,
        gradient: gradient,
        show: show,
        label: label,
        data: data,
        iconWidget: iconWidget,
        iconSize: BackgroundBlockIconSize.large,
        showIconMinWidth: BackgroundBlockMinWidth.forLargeIcon,
      );
}
