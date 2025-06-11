import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/chart/base/base_chart/render_base_chart.dart';
import 'package:fl_chart/src/chart/line_chart/line_chart_painter.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// coverage:ignore-start

/// Low level LineChart Widget.
class LineChartLeaf extends LeafRenderObjectWidget {
  const LineChartLeaf({
    super.key,
    required this.data,
    required this.targetData,
    required this.canBeScaled,
    required this.chartVirtualRect,
  });

  final LineChartData data;
  final LineChartData targetData;
  final Rect? chartVirtualRect;
  final bool canBeScaled;

  @override
  RenderLineChart createRenderObject(BuildContext context) => RenderLineChart(
        context,
        data,
        targetData,
        MediaQuery.of(context).textScaler,
        chartVirtualRect,
        canBeScaled: canBeScaled,
      );

  @override
  void updateRenderObject(BuildContext context, RenderLineChart renderObject) {
    renderObject
      ..data = data
      ..targetData = targetData
      ..textScaler = MediaQuery.of(context).textScaler
      ..buildContext = context
      ..chartVirtualRect = chartVirtualRect
      ..canBeScaled = canBeScaled;
  }
}
// coverage:ignore-end

/// Renders our LineChart, also handles hitTest.
class RenderLineChart extends RenderBaseChart<LineTouchResponse> {
  RenderLineChart(
    BuildContext context,
    LineChartData data,
    LineChartData targetData,
    TextScaler textScaler,
    Rect? chartVirtualRect, {
    required bool canBeScaled,
  })  : _data = data,
        _targetData = targetData,
        _textScaler = textScaler,
        _chartVirtualRect = chartVirtualRect,
        super(
          targetData.lineTouchData,
          context,
          canBeScaled: canBeScaled,
        );

  LineChartData get data => _data;
  LineChartData _data;
  set data(LineChartData value) {
    if (_data == value) return;
    _data = value;
    markNeedsPaint();
  }

  LineChartData get targetData => _targetData;
  LineChartData _targetData;
  set targetData(LineChartData value) {
    if (_targetData == value) return;
    _targetData = value;
    super.updateBaseTouchData(_targetData.lineTouchData);
    markNeedsPaint();
  }

  TextScaler get textScaler => _textScaler;
  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (_textScaler == value) return;
    _textScaler = value;
    markNeedsPaint();
  }

  Rect? get chartVirtualRect => _chartVirtualRect;
  Rect? _chartVirtualRect;
  set chartVirtualRect(Rect? value) {
    if (_chartVirtualRect == value) return;
    _chartVirtualRect = value;
    markNeedsPaint();
  }

  // We couldn't mock [size] property of this class, that's why we have this
  @visibleForTesting
  Size? mockTestSize;

  @visibleForTesting
  LineChartPainter painter = LineChartPainter();

  PaintHolder<LineChartData> get paintHolder =>
      PaintHolder(data, targetData, textScaler, chartVirtualRect);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    painter.paint(
      buildContext,
      CanvasWrapper(canvas, mockTestSize ?? size),
      paintHolder,
    );
    canvas.restore();
  }

  // @override
  // LineTouchResponse getResponseAtLocation(Offset localPosition) {
  //   final chartSize = mockTestSize ?? size;
  //   return LineTouchResponse(
  //     touchLocation: localPosition,
  //     touchChartCoordinate: painter.getChartCoordinateFromPixel(
  //       localPosition,
  //       chartSize,
  //       paintHolder,
  //     ),
  //     lineBarSpots: painter.handleTouch(
  //       localPosition,
  //       chartSize,
  //       paintHolder,
  //     ),
  //   );
  // }

  @override
  LineTouchResponse getResponseAtLocation(Offset localPosition) {
    final data = targetData;
    if (!data.lineTouchData.enabled) {
      return LineTouchResponse(
        touchLocation: localPosition,
        touchChartCoordinate: localPosition,
      );
    }

    final size = mockTestSize ?? this.size;
    final chartViewSize = paintHolder.getChartUsableSize(size);

    // 首先檢查背景區塊
    final touchedBackgroundBlock = _getTouchedBackgroundBlock(
      localPosition,
      chartViewSize,
      paintHolder,
    );

    // 檢查線條觸碰
    final touchedSpots = painter.handleTouch(
      localPosition,
      size,
      paintHolder,
    );

    return LineTouchResponse(
      touchLocation: localPosition,
      touchChartCoordinate: localPosition,
      lineBarSpots: touchedSpots,
      touchedBackgroundBlock: touchedBackgroundBlock,
    );
  }

  /// 取得被觸碰的背景區塊
  TouchedBackgroundBlock? _getTouchedBackgroundBlock(
    Offset localPosition,
    Size viewSize,
    PaintHolder<LineChartData> holder,
  ) {
    final data = holder.data;
    final touchX = _getChartCoordinateX(localPosition.dx, viewSize, holder);

    // 檢查所有背景區塊，找出被觸碰的區塊
    for (var i = 0; i < data.backgroundBlocks.length; i++) {
      final block = data.backgroundBlocks[i];

      // 確保區塊是顯示的且有 tooltip 資料
      if (!block.show || block.tooltipData == null) continue;

      // 檢查觸碰點是否在背景區塊的 X 範圍內（整個區塊都可觸碰）
      if (touchX >= block.startX && touchX <= block.endX) {
        return TouchedBackgroundBlock(
          blockData: block,
          blockIndex: i,
          touchX: touchX,
        );
      }
    }

    return null;
  }

  /// 獲取圖表座標系統中的 X 值
  double _getChartCoordinateX(
      double pixelX, Size viewSize, PaintHolder<LineChartData> holder) {
    final data = holder.data;
    final chartUsableSize = holder.getChartUsableSize(viewSize);

    final deltaX = data.maxX - data.minX;
    final pixelPerX = chartUsableSize.width / deltaX;

    return (pixelX / pixelPerX) + data.minX;
  }
}
