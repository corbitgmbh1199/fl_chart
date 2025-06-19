import 'package:fl_chart/src/chart/line_chart/custom_axis_line/custom_axis_lines_data.dart';
import 'package:fl_chart/src/chart/line_chart/line_chart_data.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:flutter/material.dart';

/// 客製化軸線繪製器
class CustomAxisLinesPainter extends CustomPainter {
  CustomAxisLinesPainter({
    required this.customAxisLinesData,
    required this.chartData,
    this.chartVirtualRect,
  });

  final CustomAxisLinesData customAxisLinesData;
  final LineChartData chartData;
  final Rect? chartVirtualRect;

  late final Paint _linePaint = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (!customAxisLinesData.show) {
      return;
    }

    final canvasWrapper = CanvasWrapper(canvas, size);

    // 繪製水平軸線
    for (final line in customAxisLinesData.horizontalLines) {
      _drawHorizontalLine(canvasWrapper, line, size);
    }

    // 繪製垂直軸線
    for (final line in customAxisLinesData.verticalLines) {
      _drawVerticalLine(canvasWrapper, line, size);
    }
  }

  /// 繪製水平軸線
  void _drawHorizontalLine(
    CanvasWrapper canvasWrapper,
    CustomHorizontalLine line,
    Size size,
  ) {
    // 計算 Y 座標像素位置
    final pixelY = _getPixelY(line.y, size);

    // 檢查是否在圖表範圍內（嚴格遵守不畫超過圖表）
    if (pixelY < 0 || pixelY > size.height) {
      return;
    }

    // 計算起始和結束點
    final startPoint = Offset(0, pixelY);
    final endPoint = Offset(size.width, pixelY);

    // 設定畫筆
    _linePaint
      ..color = line.color
      ..strokeWidth = line.strokeWidth
      ..strokeCap = line.strokeCap;

    // 繪製線條（支援虛線）
    canvasWrapper.drawDashedLine(
      startPoint,
      endPoint,
      _linePaint,
      line.dashArray,
    );
  }

  /// 繪製垂直軸線
  void _drawVerticalLine(
    CanvasWrapper canvasWrapper,
    CustomVerticalLine line,
    Size size,
  ) {
    // 計算 X 座標像素位置
    final pixelX = _getPixelX(line.x, size);

    // 檢查是否在圖表範圍內（嚴格遵守不畫超過圖表）
    if (pixelX < 0 || pixelX > size.width) {
      return;
    }

    // 計算起始和結束點
    final startPoint = Offset(pixelX, 0);
    final endPoint = Offset(pixelX, size.height);

    // 設定畫筆
    _linePaint
      ..color = line.color
      ..strokeWidth = line.strokeWidth
      ..strokeCap = line.strokeCap;

    // 繪製線條（支援虛線）
    canvasWrapper.drawDashedLine(
      startPoint,
      endPoint,
      _linePaint,
      line.dashArray,
    );
  }

  /// 將圖表 X 座標轉換為像素座標（支援縮放）
  double _getPixelX(double chartX, Size size) {
    final deltaX = chartData.maxX - chartData.minX;
    if (deltaX == 0) return 0;

    // 考慮縮放變換
    if (chartVirtualRect != null) {
      final virtualWidth = chartVirtualRect!.width;
      final virtualLeft = chartVirtualRect!.left;
      final normalizedX = (chartX - chartData.minX) / deltaX;
      return virtualLeft + (normalizedX * virtualWidth);
    } else {
      // 正常模式下的座標轉換
      return ((chartX - chartData.minX) / deltaX) * size.width;
    }
  }

  /// 將圖表 Y 座標轉換為像素座標（支援縮放）
  double _getPixelY(double chartY, Size size) {
    final deltaY = chartData.maxY - chartData.minY;
    if (deltaY == 0) return size.height;

    // 考慮縮放變換
    if (chartVirtualRect != null) {
      final virtualHeight = chartVirtualRect!.height;
      final virtualTop = chartVirtualRect!.top;
      final normalizedY = (chartY - chartData.minY) / deltaY;
      return virtualTop + ((1.0 - normalizedY) * virtualHeight);
    } else {
      // 正常模式下的座標轉換（Y軸翻轉）
      return size.height - (((chartY - chartData.minY) / deltaY) * size.height);
    }
  }

  @override
  bool shouldRepaint(CustomAxisLinesPainter oldDelegate) {
    return customAxisLinesData != oldDelegate.customAxisLinesData ||
        chartData != oldDelegate.chartData ||
        chartVirtualRect != oldDelegate.chartVirtualRect;
  }
}
