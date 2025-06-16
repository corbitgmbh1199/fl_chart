import 'package:fl_chart/src/chart/base/base_chart/base_chart_data.dart';
import 'package:fl_chart/src/chart/line_chart/line_chart_data.dart';
import 'package:flutter/material.dart';

class BackgroundBlockTooltipPainter extends CustomPainter {
  BackgroundBlockTooltipPainter({
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
      case FLHorizontalAlignment.right:
        tooltipLeft = touchPoint.dx - tooltipWidth + horizontalOffset;
      case FLHorizontalAlignment.center:
        tooltipLeft = touchPoint.dx - tooltipWidth / 2 + horizontalOffset;
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
  bool shouldRepaint(BackgroundBlockTooltipPainter oldDelegate) {
    return touchedBlock.blockIndex != oldDelegate.touchedBlock.blockIndex ||
        !identical(
            touchedBlock.blockData, oldDelegate.touchedBlock.blockData) ||
        chartData != oldDelegate.chartData ||
        chartVirtualRect != oldDelegate.chartVirtualRect;
  }
}
