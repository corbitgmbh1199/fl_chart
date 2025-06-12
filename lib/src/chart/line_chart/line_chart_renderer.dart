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

  // 修正 getResponseAtLocation 方法，讓 spots 優先於背景區塊
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

    // 優先檢查線條觸碰（spots 的 tooltip 優先）
    final touchedSpots =
        painter.handleTouch(localPosition, size, paintHolder);

    // 只有在沒有觸碰到線條時才檢查背景區塊
    TouchedBackgroundBlock? touchedBackgroundBlock;
    if (touchedSpots == null || touchedSpots.isEmpty) {

      touchedBackgroundBlock = _getTouchedBackgroundBlockWithTransform(
        localPosition,
        size,
        paintHolder,
      );
    } else {

    }

    return LineTouchResponse(
      touchLocation: localPosition,
      touchChartCoordinate: localPosition,
      lineBarSpots: touchedSpots,
      touchedBackgroundBlock: touchedBackgroundBlock,
    );
  }

  /// 考慮變換的背景區塊觸碰檢測
  TouchedBackgroundBlock? _getTouchedBackgroundBlockWithTransform(
    Offset localPosition,
    Size size,
    PaintHolder<LineChartData> holder,
  ) {
    final data = holder.data;

    // 檢查觸碰位置是否在有效範圍內
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy > size.height) {
      return null;
    }

    // 計算圖表座標
    double touchX;
    if (holder.chartVirtualRect != null) {
      // 縮放模式下的座標轉換
      final virtualRect = holder.chartVirtualRect!;
      final normalizedX =
          (localPosition.dx - virtualRect.left) / virtualRect.width;
      touchX = data.minX + (normalizedX * (data.maxX - data.minX));
    } else {
      // 正常模式下的座標轉換
      final chartViewSize = holder.getChartUsableSize(size);
      final deltaX = data.maxX - data.minX;
      if (deltaX == 0) {
        return null;
      }
      final pixelPerX = chartViewSize.width / deltaX;
      touchX = (localPosition.dx / pixelPerX) + data.minX;
    }


    // 檢查背景區塊
    for (var i = 0; i < data.backgroundBlocks.length; i++) {
      final block = data.backgroundBlocks[i];

      // 只檢查是否顯示，不再檢查個別的 tooltipData
      if (!block.show) continue;

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
}
