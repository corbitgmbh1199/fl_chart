import 'dart:math';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_extensions.dart';
import 'package:fl_chart/src/chart/base/axis_chart/axis_chart_painter.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/chart/line_chart/widget_image_cache.dart';
import 'package:fl_chart/src/extensions/paint_extension.dart';
import 'package:fl_chart/src/extensions/path_extension.dart';
import 'package:fl_chart/src/extensions/text_align_extension.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:fl_chart/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Paints [LineChartData] in the canvas, it can be used in a [CustomPainter]
class LineChartPainter extends AxisChartPainter<LineChartData> {

  LineChartPainter() : super() {
    _barPaint = Paint()..style = PaintingStyle.stroke;

    _barAreaPaint = Paint()..style = PaintingStyle.fill;

    _barAreaLinesPaint = Paint()..style = PaintingStyle.stroke;

    _clearBarAreaPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x00000000)
      ..blendMode = BlendMode.dstIn;

    _touchLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black;

    _bgTouchTooltipPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    _borderTouchTooltipPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.transparent
      ..strokeWidth = 1.0;

    _clipPaint = Paint();
    _backgroundBlockPaint = Paint()..style = PaintingStyle.fill;
  }
  /// Paints [dataList] into canvas, it is the animating [LineChartData],
  /// [targetData] is the animation's target and remains the same
  /// during animation, then we should use it  when we need to show
  /// tooltips or something like that, because [dataList] is changing constantly.
  ///
  /// [textScale] used for scaling texts inside the chart,
  /// parent can use [MediaQuery.textScaleFactor] to respect
  /// the system's font size.
  ///

  late Paint _backgroundBlockPaint;

  late Paint _barPaint;
  late Paint _barAreaPaint;
  late Paint _barAreaLinesPaint;
  late Paint _clearBarAreaPaint;
  late Paint _touchLinePaint;
  late Paint _bgTouchTooltipPaint;
  late Paint _borderTouchTooltipPaint;
  late Paint _clipPaint;

  /// Paints [LineChartData] into the provided canvas.
  @override
  void paint(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<LineChartData> holder,
  ) {
    final data = holder.data;
    if (holder.chartVirtualRect != null) {
      canvasWrapper
        ..saveLayer(
          Offset.zero & canvasWrapper.size,
          _clipPaint,
        )
        ..clipRect(Offset.zero & canvasWrapper.size);
    }

    // 第一層：繪製背景區塊的顏色/漸層（最底層）
    for (final backgroundBlock in data.backgroundBlocks) {
      drawBackgroundBlock(canvasWrapper, backgroundBlock, holder);
    }

    // 第二層：繪製軸線、網格線、邊框
    super.paint(context, canvasWrapper, holder);
    if (data.lineBarsData.isEmpty) {
      return;
    }

    if (data.clipData.any && holder.chartVirtualRect == null) {
      canvasWrapper.saveLayer(
        Rect.fromLTWH(
          0,
          -40,
          canvasWrapper.size.width + 40,
          canvasWrapper.size.height + 40,
        ),
        _clipPaint,
      );

      clipToBorder(canvasWrapper, holder);
    }

    // ✅ 第三層：在這裡加入背景區塊圖示繪製
    drawBackgroundBlockIcons(context, canvasWrapper, holder);

    // 繼續原有的繪製順序...
    for (final betweenBarsData in data.betweenBarsData) {
      drawBetweenBarsArea(canvasWrapper, data, betweenBarsData, holder);
    }

    if (!data.extraLinesData.extraLinesOnTop) {
      super.drawExtraLines(context, canvasWrapper, holder);
    }

    final lineIndexDrawingInfo = <LineIndexDrawingInfo>[];

    /// draw each line independently on the chart
    // 第四層：繪製線條和資料點
    for (var i = 0; i < data.lineBarsData.length; i++) {
      final barData = data.lineBarsData[i];

      if (!barData.show) {
        continue;
      }

      drawBarLine(canvasWrapper, barData, holder);
      drawDots(canvasWrapper, barData, holder);

      if (data.extraLinesData.extraLinesOnTop) {
        super.drawExtraLines(context, canvasWrapper, holder);
      }

      final indicatorsData = data.lineTouchData
          .getTouchedSpotIndicator(barData, barData.showingIndicators);

      if (indicatorsData.length != barData.showingIndicators.length) {
        throw Exception(
          'indicatorsData and touchedSpotOffsets size should be same',
        );
      }

      for (var j = 0; j < barData.showingIndicators.length; j++) {
        final indicatorData = indicatorsData[j];
        final index = barData.showingIndicators[j];
        if (index < 0 || index >= barData.spots.length) {
          continue;
        }
        final spot = barData.spots[index];

        if (indicatorData == null) {
          continue;
        }
        lineIndexDrawingInfo.add(
          LineIndexDrawingInfo(barData, i, spot, index, indicatorData),
        );
      }
    }

    drawTouchedSpotsIndicator(canvasWrapper, lineIndexDrawingInfo, holder);

    if (data.clipData.any || holder.chartVirtualRect != null) {
      canvasWrapper.restore();
    }

    // Draw error indicators
    for (var i = 0; i < data.lineBarsData.length; i++) {
      final barData = data.lineBarsData[i];

      if (!barData.show) {
        continue;
      }

      drawErrorIndicatorData(
        canvasWrapper,
        barData,
        holder,
      );
    }

    // Draw touch tooltip on most top spot
    for (var i = 0; i < data.showingTooltipIndicators.length; i++) {
      var tooltipSpots = data.showingTooltipIndicators[i];

      final showingBarSpots = tooltipSpots.showingSpots;
      if (showingBarSpots.isEmpty) {
        continue;
      }
      final barSpots = List<LineBarSpot>.of(showingBarSpots);
      FlSpot topSpot = barSpots[0];
      for (final barSpot in barSpots) {
        if (barSpot.y > topSpot.y) {
          topSpot = barSpot;
        }
      }
      tooltipSpots = ShowingTooltipIndicators(barSpots);

      // 最後繪製背景區塊的 tooltip（在所有其他元素之後）
      drawBackgroundBlockTooltips(canvasWrapper, data, holder);

      drawTouchTooltip(
        context,
        canvasWrapper,
        data.lineTouchData.touchTooltipData,
        topSpot,
        tooltipSpots,
        holder,
      );
    }
  }

  // 修正 drawBackgroundBlock 方法以支援變換
  /// 繪製背景區塊
  @visibleForTesting
  void drawBackgroundBlock(
    CanvasWrapper canvasWrapper,
    BackgroundBlockData blockData,
    PaintHolder<LineChartData> holder,
  ) {
    if (!blockData.show) {
      return;
    }

    final viewSize = canvasWrapper.size;

    // 考慮變換後的座標計算
    final leftX = getPixelX(blockData.startX, viewSize, holder);
    final rightX = getPixelX(blockData.endX, viewSize, holder);

    // 如果有虛擬矩形，需要調整 Y 座標範圍
    double topY;
    double bottomY;
    if (holder.chartVirtualRect != null) {
      // 在縮放模式下，背景區塊應該覆蓋整個可見區域
      topY = holder.chartVirtualRect!.top;
      bottomY = holder.chartVirtualRect!.bottom;
    } else {
      // 正常模式下覆蓋整個圖表高度
      topY = 0.0;
      bottomY = viewSize.height;
    }

    final rect = Rect.fromLTRB(leftX, topY, rightX, bottomY);

    // 只有當矩形在可見範圍內時才繪製
    final visibleRect = Offset.zero & viewSize;
    if (!rect.overlaps(visibleRect)) {
      return;
    }

    _backgroundBlockPaint.setColorOrGradient(
      blockData.color,
      blockData.gradient,
      rect,
    );

    canvasWrapper.drawRect(rect, _backgroundBlockPaint);
  }

  /// 繪製背景區塊的 tooltip
  @visibleForTesting
  void drawBackgroundBlockTooltips(
    CanvasWrapper canvasWrapper,
    LineChartData data,
    PaintHolder<LineChartData> holder,
  ) {
    if (!data.lineTouchData.enabled) {
      return;
    }

    // 檢查是否有被觸碰的背景區塊需要顯示 tooltip
    // 這個資訊會通過 LineChart 的狀態管理傳遞
    // 暫時先不實作繪製邏輯，讓 Widget 層處理
  }

  @visibleForTesting
  void clipToBorder(
    CanvasWrapper canvasWrapper,
    PaintHolder<LineChartData> holder,
  ) {
    final data = holder.data;
    final viewSize = canvasWrapper.size;
    final clip = data.clipData;
    final border = data.borderData.show ? data.borderData.border : null;

    var left = 0.0;
    var top = 0.0;
    var right = viewSize.width;
    var bottom = viewSize.height;

    if (clip.left) {
      final borderWidth = border?.left.width ?? 0;
      left = borderWidth / 2;
    }
    if (clip.top) {
      final borderWidth = border?.top.width ?? 0;
      top = borderWidth / 2;
    }
    if (clip.right) {
      final borderWidth = border?.right.width ?? 0;
      right = viewSize.width - (borderWidth / 2);
    }
    if (clip.bottom) {
      final borderWidth = border?.bottom.width ?? 0;
      bottom = viewSize.height - (borderWidth / 2);
    }

    canvasWrapper.clipRect(Rect.fromLTRB(left, top, right, bottom));
  }

  @visibleForTesting
  void drawBarLine(
    CanvasWrapper canvasWrapper,
    LineChartBarData barData,
    PaintHolder<LineChartData> holder,
  ) {
    final viewSize = holder.getChartUsableSize(canvasWrapper.size);

    final barList = barData.spots.splitByNullSpots();

    // paint each sublist that was built above
    // bar is passed in separately from barData
    // because barData is the whole line
    // and bar is a piece of that line
    for (final bar in barList) {
      final barPath = generateBarPath(viewSize, barData, bar, holder);

      final belowBarPath =
          generateBelowBarPath(viewSize, barData, barPath, bar, holder);
      final completelyFillBelowBarPath = generateBelowBarPath(
        viewSize,
        barData,
        barPath,
        bar,
        holder,
        fillCompletely: true,
      );
      final aboveBarPath =
          generateAboveBarPath(viewSize, barData, barPath, bar, holder);
      final completelyFillAboveBarPath = generateAboveBarPath(
        viewSize,
        barData,
        barPath,
        bar,
        holder,
        fillCompletely: true,
      );

      drawBelowBar(
        canvasWrapper,
        belowBarPath,
        completelyFillAboveBarPath,
        holder,
        barData,
      );
      drawAboveBar(
        canvasWrapper,
        aboveBarPath,
        completelyFillBelowBarPath,
        holder,
        barData,
      );
      drawBarShadow(canvasWrapper, barPath, barData);
      drawBar(canvasWrapper, barPath, barData, holder);
    }
  }

  /// 穩定的圖片快取（避免縮放時重新建立）
  static final Map<String, ui.Image> _globalStableCache = {};

  /// 簡化的背景區塊圖示繪製（避免複雜的 Widget 轉換）
  @visibleForTesting
  void drawBackgroundBlockIcons(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<LineChartData> holder,
  ) {
    final data = holder.data;
    final viewSize = canvasWrapper.size;

    for (var i = 0; i < data.backgroundBlocks.length; i++) {
      final blockData = data.backgroundBlocks[i];

      if (!blockData.show || blockData.iconWidget == null) {
        continue;
      }

      // 計算區塊在螢幕上的位置
      final blockStartPixel = getPixelX(blockData.startX, viewSize, holder);
      final blockEndPixel = getPixelX(blockData.endX, viewSize, holder);
      final blockWidth = blockEndPixel - blockStartPixel;

      // 檢查是否應該顯示圖示
      if (blockWidth < blockData.showIconMinWidth) {
        continue;
      }

      // 計算圖示的中心位置
      final blockCenterX = (blockStartPixel + blockEndPixel) / 2;
      final blockCenterY = viewSize.height / 2;

      final iconLeft = blockCenterX - (blockData.iconSize.width / 2);
      final iconTop = blockCenterY - (blockData.iconSize.height / 2);

      // 確保圖示在可見範圍內
      if (iconLeft < -blockData.iconSize.width ||
          iconTop < -blockData.iconSize.height ||
          iconLeft > viewSize.width ||
          iconTop > viewSize.height) {
        continue;
      }

      // 建立快取鍵值
      final cacheKey = _generateCacheKey(blockData, i);

      // 嘗試從快取取得圖片
      final cachedImage = WidgetImageCache().getCachedImage(cacheKey);

      if (cachedImage != null) {
        // 如果有快取，直接繪製原始 Widget 的圖片
        _drawImageStable(
          canvasWrapper,
          cachedImage,
          Offset(iconLeft, iconTop),
          blockData.iconSize,
        );
      } else {
        // 沒有快取時，先顯示載入中，然後異步建立圖片
        _drawLoadingPlaceholder(
          canvasWrapper,
          Offset(iconLeft, iconTop),
          blockData.iconSize,
        );

        // 異步建立真正的 Widget 圖片
        _createWidgetImageAsync(
          context,
          blockData.iconWidget!,
          blockData.iconSize,
          cacheKey,
        );
      }
    }
  }

  /// 產生快取鍵值
  String _generateCacheKey(BackgroundBlockData blockData, int index) {
    return 'bg_icon_${index}_${blockData.iconWidget.hashCode}_${blockData.iconSize.width.toInt()}x${blockData.iconSize.height.toInt()}';
  }

  /// 異步建立 Widget 圖片（修正版本 - 避免 frame 衝突）
  void _createWidgetImageAsync(
    BuildContext context,
    Widget widget,
    Size size,
    String cacheKey,
  ) {
    // ✅ 避免在繪製過程中直接呼叫異步方法
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      
      try {
        final image = await WidgetImageCache().convertAndCacheWidget(
          cacheKey,
          widget,
          size,
          context,
        );

        if (image != null && context.mounted) {
          // ✅ 延遲觸發重繪，避免 frame 衝突
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              // 找到 LineChart Widget 並觸發重繪
              final renderObject = context.findRenderObject();
              if (renderObject != null) {
                renderObject.markNeedsPaint();
              }
            }
          });
        }
      } catch (e) {
        debugPrint('建立 Widget 圖片時發生錯誤: $e');
      }
    });
  }

  /// 穩定的圖片繪製方法
  void _drawImageStable(
    CanvasWrapper canvasWrapper,
    ui.Image image,
    Offset position,
    Size targetSize,
  ) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    final scaleX = targetSize.width / image.width;
    final scaleY = targetSize.height / image.height;

    canvasWrapper.canvas.save();
    canvasWrapper.canvas.translate(position.dx, position.dy);
    canvasWrapper.canvas.scale(scaleX, scaleY);
    canvasWrapper.canvas.drawImage(image, Offset.zero, paint);
    canvasWrapper.canvas.restore();
  }

  /// 繪製載入中佔位符（極簡版本）
  void _drawLoadingPlaceholder(
    CanvasWrapper canvasWrapper,
    Offset position,
    Size size,
  ) {
    // // 繪製一個極淡的圓點，表示載入中
    // final paint = Paint()
    //   ..color = Colors.grey.withValues(alpha: 0.3)
    //   ..style = PaintingStyle.fill;

    // final center = Offset(
    //   position.dx + size.width / 2,
    //   position.dy + size.height / 2,
    // );

    // canvasWrapper.canvas.drawCircle(center, 2.0, paint);
  }

  /// 清理全域快取（增強版本）
  static void clearGlobalCache() {
    debugPrint('🗑️ 開始清理全域快取，目前快取數量: ${_globalStableCache.length}');

    for (final image in _globalStableCache.values) {
      image.dispose();
    }
    _globalStableCache.clear();

    debugPrint('✅ 全域快取清理完成');
  }

  /// 穩定的圖片繪製方法，避免縮放時的閃爍
  @visibleForTesting
  void drawCachedImageStable(
    CanvasWrapper canvasWrapper,
    ui.Image image,
    Offset position,
    Size targetSize,
  ) {
    // 計算縮放比例，使用更穩定的方法
    final scaleX = targetSize.width / image.width;
    final scaleY = targetSize.height / image.height;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvasWrapper.canvas.save();

    // 移動到目標位置並縮放
    canvasWrapper.canvas.translate(position.dx, position.dy);
    canvasWrapper.canvas.scale(scaleX, scaleY);

    // 繪製圖片
    canvasWrapper.canvas.drawImage(image, Offset.zero, paint);

    canvasWrapper.canvas.restore();
  }

  /// 繪製快取的圖片到 Canvas
  @visibleForTesting
  void drawCachedImage(
    CanvasWrapper canvasWrapper,
    ui.Image image,
    Offset position,
    Size targetSize,
  ) {
    debugPrint('繪製圖片到位置: $position，目標尺寸: $targetSize');

    // 計算縮放比例
    final scaleX = targetSize.width / image.width;
    final scaleY = targetSize.height / image.height;

    debugPrint('縮放比例: scaleX=$scaleX, scaleY=$scaleY');

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvasWrapper.canvas.save();
    
    // 移動到目標位置並縮放
    canvasWrapper.canvas.translate(position.dx, position.dy);
    canvasWrapper.canvas.scale(scaleX, scaleY);
    
    // 繪製圖片
    canvasWrapper.canvas.drawImage(image, Offset.zero, paint);
    
    canvasWrapper.canvas.restore();
    debugPrint('圖片繪製完成');
  }

  @visibleForTesting
  void drawBetweenBarsArea(
    CanvasWrapper canvasWrapper,
    LineChartData data,
    BetweenBarsData betweenBarsData,
    PaintHolder<LineChartData> holder,
  ) {
    final viewSize = canvasWrapper.size;
    final fromBarData = data.lineBarsData[betweenBarsData.fromIndex];
    final toBarData = data.lineBarsData[betweenBarsData.toIndex];

    final fromBarSplitLines = fromBarData.spots.splitByNullSpots();
    final toBarSplitLines = toBarData.spots.splitByNullSpots();

    if (fromBarSplitLines.length != toBarSplitLines.length) {
      throw ArgumentError(
        'Cannot draw betWeenBarsArea when null spots are inconsistent.',
      );
    }

    for (var i = 0; i < fromBarSplitLines.length; i++) {
      final fromSpots = fromBarSplitLines[i];
      final toSpots = toBarSplitLines[i].reversed.toList();

      final fromBarPath = generateBarPath(
        viewSize,
        fromBarData,
        fromSpots,
        holder,
      );
      final barPath = generateBarPath(
        viewSize,
        toBarData.copyWith(spots: toSpots),
        toSpots,
        holder,
        appendToPath: fromBarPath,
      );
      final left = min(fromBarData.mostLeftSpot.x, toBarData.mostLeftSpot.x);
      final top = max(fromBarData.mostTopSpot.y, toBarData.mostTopSpot.y);
      final right = max(fromBarData.mostRightSpot.x, toBarData.mostRightSpot.x);
      final bottom = min(
        fromBarData.mostBottomSpot.y,
        toBarData.mostBottomSpot.y,
      );
      final aroundRect = Rect.fromLTRB(
        getPixelX(left, viewSize, holder),
        getPixelY(top, viewSize, holder),
        getPixelX(right, viewSize, holder),
        getPixelY(bottom, viewSize, holder),
      );

      drawBetweenBar(
        canvasWrapper,
        barPath,
        betweenBarsData,
        aroundRect,
        holder,
      );
    }
  }

  @visibleForTesting
  void drawDots(
    CanvasWrapper canvasWrapper,
    LineChartBarData barData,
    PaintHolder<LineChartData> holder,
  ) {
    if (!barData.dotData.show || barData.spots.isEmpty) {
      return;
    }
    final viewSize = canvasWrapper.size;

    final barXDelta = getBarLineXLength(barData, viewSize, holder);

    for (var i = 0; i < barData.spots.length; i++) {
      final spot = barData.spots[i];
      if (spot.isNotNull() && barData.dotData.checkToShowDot(spot, barData)) {
        final x = getPixelX(spot.x, viewSize, holder);
        final y = getPixelY(spot.y, viewSize, holder);
        final xPercentInLine = (x / barXDelta) * 100;
        final painter =
            barData.dotData.getDotPainter(spot, xPercentInLine, barData, i);

        canvasWrapper.drawDot(painter, spot, Offset(x, y));
      }
    }
  }

  @visibleForTesting
  void drawErrorIndicatorData(
    CanvasWrapper canvasWrapper,
    LineChartBarData barData,
    PaintHolder<LineChartData> holder,
  ) {
    final errorIndicatorData = barData.errorIndicatorData;
    if (!errorIndicatorData.show) {
      return;
    }

    final viewSize = canvasWrapper.size;

    for (var i = 0; i < barData.spots.length; i++) {
      final spot = barData.spots[i];
      if (spot.isNotNull()) {
        final x = getPixelX(spot.x, viewSize, holder);
        final y = getPixelY(spot.y, viewSize, holder);
        if (spot.xError == null && spot.yError == null) {
          continue;
        }

        var left = 0.0;
        var right = 0.0;
        if (spot.xError != null) {
          left = getPixelX(spot.x - spot.xError!.lowerBy, viewSize, holder) - x;
          right =
              getPixelX(spot.x + spot.xError!.upperBy, viewSize, holder) - x;
        }

        var top = 0.0;
        var bottom = 0.0;
        if (spot.yError != null) {
          top = getPixelY(spot.y + spot.yError!.lowerBy, viewSize, holder) - y;
          bottom =
              getPixelY(spot.y - spot.yError!.upperBy, viewSize, holder) - y;
        }
        final relativeErrorPixelsRect = Rect.fromLTRB(
          left,
          top,
          right,
          bottom,
        );

        final painter = errorIndicatorData.painter(
          LineChartSpotErrorRangeCallbackInput(
            spot: spot,
            bar: barData,
            spotIndex: i,
          ),
        );
        canvasWrapper.drawErrorIndicator(
          painter,
          spot,
          Offset(x, y),
          relativeErrorPixelsRect,
          holder.data,
        );
      }
    }
  }

  @visibleForTesting
  void drawTouchedSpotsIndicator(
    CanvasWrapper canvasWrapper,
    List<LineIndexDrawingInfo> lineIndexDrawingInfo,
    PaintHolder<LineChartData> holder,
  ) {
    if (lineIndexDrawingInfo.isEmpty) {
      return;
    }
    final viewSize = canvasWrapper.size;

    lineIndexDrawingInfo.sort((a, b) => b.spot.y.compareTo(a.spot.y));

    for (final info in lineIndexDrawingInfo) {
      final barData = info.line;
      final barXDelta = getBarLineXLength(barData, viewSize, holder);

      final data = holder.data;

      final index = info.spotIndex;
      final spot = info.spot;
      final indicatorData = info.indicatorData;

      final touchedSpot = Offset(
        getPixelX(spot.x, viewSize, holder),
        getPixelY(spot.y, viewSize, holder),
      );

      /// For drawing the dot
      final showingDots = indicatorData.touchedSpotDotData.show;
      var dotHeight = 0.0;
      late FlDotPainter dotPainter;

      if (showingDots) {
        final xPercentInLine = (touchedSpot.dx / barXDelta) * 100;
        dotPainter = indicatorData.touchedSpotDotData
            .getDotPainter(spot, xPercentInLine, barData, index);
        dotHeight = dotPainter.getSize(spot).height;
      }

      /// For drawing the indicator line
      final lineStartY = min(
        data.maxY,
        max(data.minY, data.lineTouchData.getTouchLineStart(barData, index)),
      );
      final lineEndY = min(
        data.maxY,
        max(data.minY, data.lineTouchData.getTouchLineEnd(barData, index)),
      );
      final lineStart =
          Offset(touchedSpot.dx, getPixelY(lineStartY, viewSize, holder));
      var lineEnd =
          Offset(touchedSpot.dx, getPixelY(lineEndY, viewSize, holder));

      /// If line end is inside the dot, adjust it so that it doesn't overlap with the dot.
      final dotMinY = touchedSpot.dy - dotHeight / 2;
      final dotMaxY = touchedSpot.dy + dotHeight / 2;
      if (lineEnd.dy > dotMinY && lineEnd.dy < dotMaxY) {
        if (lineStart.dy < lineEnd.dy) {
          lineEnd -= Offset(0, lineEnd.dy - dotMinY);
        } else {
          lineEnd += Offset(0, dotMaxY - lineEnd.dy);
        }
      }

      final indicatorLine = indicatorData.indicatorBelowLine;
      _touchLinePaint
        ..setColorOrGradientForLine(
          indicatorLine.color,
          indicatorLine.gradient,
          from: lineStart,
          to: lineEnd,
        )
        ..strokeWidth = indicatorLine.strokeWidth
        ..transparentIfWidthIsZero();

      canvasWrapper.drawDashedLine(
        lineStart,
        lineEnd,
        _touchLinePaint,
        indicatorLine.dashArray,
      );

      /// Draw the indicator dot
      if (showingDots) {
        canvasWrapper.drawDot(dotPainter, spot, touchedSpot);
      }
    }
  }

  /// Generates a path, based on [LineChartBarData.isStepChart] for step style, and normal style.
  @visibleForTesting
  Path generateBarPath(
    Size viewSize,
    LineChartBarData barData,
    List<FlSpot> barSpots,
    PaintHolder<LineChartData> holder, {
    Path? appendToPath,
  }) {
    if (barData.isStepLineChart) {
      return generateStepBarPath(
        viewSize,
        barData,
        barSpots,
        holder,
        appendToPath: appendToPath,
      );
    } else {
      return generateNormalBarPath(
        viewSize,
        barData,
        barSpots,
        holder,
        appendToPath: appendToPath,
      );
    }
  }

  /// firstly we generate the bar line that we should draw,
  /// then we reuse it to fill below bar space.
  /// there is two type of barPath that generate here,
  /// first one is the sharp corners line on spot connections
  /// second one is curved corners line on spot connections,
  /// and we use isCurved to find out how we should generate it,
  /// If you want to concatenate paths together for creating an area between
  /// multiple bars for example, you can pass the appendToPath
  @visibleForTesting
  Path generateNormalBarPath(
    Size viewSize,
    LineChartBarData barData,
    List<FlSpot> barSpots,
    PaintHolder<LineChartData> holder, {
    Path? appendToPath,
  }) {
    final path = appendToPath ?? Path();
    final size = barSpots.length;

    var temp = Offset.zero;

    final x = getPixelX(barSpots[0].x, viewSize, holder);
    final y = getPixelY(barSpots[0].y, viewSize, holder);
    if (appendToPath == null) {
      path.moveTo(x, y);
      if (size == 1) {
        path.lineTo(x, y);
      }
    } else {
      path.lineTo(x, y);
    }
    for (var i = 1; i < size; i++) {
      /// CurrentSpot
      final current = Offset(
        getPixelX(barSpots[i].x, viewSize, holder),
        getPixelY(barSpots[i].y, viewSize, holder),
      );

      /// previous spot
      final previous = Offset(
        getPixelX(barSpots[i - 1].x, viewSize, holder),
        getPixelY(barSpots[i - 1].y, viewSize, holder),
      );

      /// next point
      final next = Offset(
        getPixelX(barSpots[i + 1 < size ? i + 1 : i].x, viewSize, holder),
        getPixelY(barSpots[i + 1 < size ? i + 1 : i].y, viewSize, holder),
      );

      final controlPoint1 = previous + temp;

      /// if the isCurved is false, we set 0 for smoothness,
      /// it means we should not have any smoothness then we face with
      /// the sharped corners line
      final smoothness = barData.isCurved ? barData.curveSmoothness : 0.0;
      temp = ((next - previous) / 2) * smoothness;

      if (barData.preventCurveOverShooting) {
        if ((next - current).dy <= barData.preventCurveOvershootingThreshold ||
            (current - previous).dy <=
                barData.preventCurveOvershootingThreshold) {
          temp = Offset(temp.dx, 0);
        }

        if ((next - current).dx <= barData.preventCurveOvershootingThreshold ||
            (current - previous).dx <=
                barData.preventCurveOvershootingThreshold) {
          temp = Offset(0, temp.dy);
        }
      }

      final controlPoint2 = current - temp;

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        current.dx,
        current.dy,
      );
    }

    return path;
  }

  /// generates a `Step Line Chart` bar style path.
  @visibleForTesting
  Path generateStepBarPath(
    Size viewSize,
    LineChartBarData barData,
    List<FlSpot> barSpots,
    PaintHolder<LineChartData> holder, {
    Path? appendToPath,
  }) {
    final path = appendToPath ?? Path();
    final size = barSpots.length;

    final x = getPixelX(barSpots[0].x, viewSize, holder);
    final y = getPixelY(barSpots[0].y, viewSize, holder);
    if (appendToPath == null) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
    for (var i = 0; i < size; i++) {
      /// CurrentSpot
      final current = Offset(
        getPixelX(barSpots[i].x, viewSize, holder),
        getPixelY(barSpots[i].y, viewSize, holder),
      );

      /// next point
      final next = Offset(
        getPixelX(barSpots[i + 1 < size ? i + 1 : i].x, viewSize, holder),
        getPixelY(barSpots[i + 1 < size ? i + 1 : i].y, viewSize, holder),
      );

      final stepDirection = barData.lineChartStepData.stepDirection;

      // middle
      if (current.dy == next.dy) {
        path.lineTo(next.dx, next.dy);
      } else {
        final deltaX = next.dx - current.dx;

        path
          ..lineTo(current.dx + deltaX - (deltaX * stepDirection), current.dy)
          ..lineTo(current.dx + deltaX - (deltaX * stepDirection), next.dy)
          ..lineTo(next.dx, next.dy);
      }
    }

    return path;
  }

  /// it generates below area path using a copy of [barPath],
  /// if cutOffY is provided by the [BarAreaData], it cut the area to the provided cutOffY value,
  /// if [fillCompletely] is true, the cutOffY will be ignored,
  /// and a completely filled path will return,
  @visibleForTesting
  Path generateBelowBarPath(
    Size viewSize,
    LineChartBarData barData,
    Path barPath,
    List<FlSpot> barSpots,
    PaintHolder<LineChartData> holder, {
    bool fillCompletely = false,
  }) {
    final belowBarPath = Path.from(barPath);

    /// Line To Bottom Right
    var x = getPixelX(barSpots[barSpots.length - 1].x, viewSize, holder);
    double y;
    if (!fillCompletely && barData.belowBarData.applyCutOffY) {
      y = getPixelY(barData.belowBarData.cutOffY, viewSize, holder);
    } else {
      y = viewSize.height;
    }
    belowBarPath.lineTo(x, y);

    /// Line To Bottom Left
    x = getPixelX(barSpots[0].x, viewSize, holder);
    if (!fillCompletely && barData.belowBarData.applyCutOffY) {
      y = getPixelY(barData.belowBarData.cutOffY, viewSize, holder);
    } else {
      y = viewSize.height;
    }
    belowBarPath.lineTo(x, y);

    /// Line To Top Left
    x = getPixelX(barSpots[0].x, viewSize, holder);
    y = getPixelY(barSpots[0].y, viewSize, holder);
    belowBarPath
      ..lineTo(x, y)
      ..close();

    return belowBarPath;
  }

  /// it generates above area path using a copy of [barPath],
  /// if cutOffY is provided by the [BarAreaData], it cut the area to the provided cutOffY value,
  /// if [fillCompletely] is true, the cutOffY will be ignored,
  /// and a completely filled path will return,
  @visibleForTesting
  Path generateAboveBarPath(
    Size viewSize,
    LineChartBarData barData,
    Path barPath,
    List<FlSpot> barSpots,
    PaintHolder<LineChartData> holder, {
    bool fillCompletely = false,
  }) {
    final aboveBarPath = Path.from(barPath);

    /// Line To Top Right
    var x = getPixelX(barSpots[barSpots.length - 1].x, viewSize, holder);
    double y;
    if (!fillCompletely && barData.aboveBarData.applyCutOffY) {
      y = getPixelY(barData.aboveBarData.cutOffY, viewSize, holder);
    } else {
      y = 0.0;
    }
    aboveBarPath.lineTo(x, y);

    /// Line To Top Left
    x = getPixelX(barSpots[0].x, viewSize, holder);
    if (!fillCompletely && barData.aboveBarData.applyCutOffY) {
      y = getPixelY(barData.aboveBarData.cutOffY, viewSize, holder);
    } else {
      y = 0.0;
    }
    aboveBarPath.lineTo(x, y);

    /// Line To Bottom Left
    x = getPixelX(barSpots[0].x, viewSize, holder);
    y = getPixelY(barSpots[0].y, viewSize, holder);
    aboveBarPath
      ..lineTo(x, y)
      ..close();

    return aboveBarPath;
  }

  /// firstly we draw [belowBarPath], then if cutOffY value is provided in [BarAreaData],
  /// [belowBarPath] maybe draw over the main bar line,
  /// then to fix the problem we use [filledAboveBarPath] to clear the above section from this draw.
  @visibleForTesting
  void drawBelowBar(
    CanvasWrapper canvasWrapper,
    Path belowBarPath,
    Path filledAboveBarPath,
    PaintHolder<LineChartData> holder,
    LineChartBarData barData,
  ) {
    if (!barData.belowBarData.show) {
      return;
    }

    final viewSize = canvasWrapper.size;

    final belowBarLargestRect = Rect.fromLTRB(
      getPixelX(barData.mostLeftSpot.x, viewSize, holder),
      getPixelY(barData.mostTopSpot.y, viewSize, holder),
      getPixelX(barData.mostRightSpot.x, viewSize, holder),
      viewSize.height,
    );

    final belowBar = barData.belowBarData;
    _barAreaPaint.setColorOrGradient(
      belowBar.color,
      belowBar.gradient,
      belowBarLargestRect,
    );

    if (barData.belowBarData.applyCutOffY) {
      canvasWrapper.saveLayer(
        Rect.fromLTWH(0, 0, viewSize.width, viewSize.height),
        _clipPaint,
      );
    }

    canvasWrapper.drawPath(belowBarPath, _barAreaPaint);

    // clear the above area that get out of the bar line
    if (barData.belowBarData.applyCutOffY) {
      canvasWrapper
        ..drawPath(filledAboveBarPath, _clearBarAreaPaint)
        ..restore();
    }

    /// draw below spots line
    if (barData.belowBarData.spotsLine.show) {
      for (final spot in barData.spots) {
        if (barData.belowBarData.spotsLine.checkToShowSpotLine(spot)) {
          final from = Offset(
            getPixelX(spot.x, viewSize, holder),
            getPixelY(spot.y, viewSize, holder),
          );

          Offset to;

          // Check applyCutOffY
          if (barData.belowBarData.spotsLine.applyCutOffY &&
              barData.belowBarData.applyCutOffY) {
            to = Offset(
              getPixelX(spot.x, viewSize, holder),
              getPixelY(barData.belowBarData.cutOffY, viewSize, holder),
            );
          } else {
            to = Offset(
              getPixelX(spot.x, viewSize, holder),
              viewSize.height,
            );
          }

          final lineStyle = barData.belowBarData.spotsLine.flLineStyle;
          _barAreaLinesPaint
            ..setColorOrGradientForLine(
              lineStyle.color,
              lineStyle.gradient,
              from: from,
              to: to,
            )
            ..strokeWidth = lineStyle.strokeWidth
            ..transparentIfWidthIsZero();

          canvasWrapper.drawDashedLine(
            from,
            to,
            _barAreaLinesPaint,
            lineStyle.dashArray,
          );
        }
      }
    }
  }

  /// firstly we draw [aboveBarPath], then if cutOffY value is provided in [BarAreaData],
  /// [aboveBarPath] maybe draw over the main bar line,
  /// then to fix the problem we use [filledBelowBarPath] to clear the above section from this draw.
  @visibleForTesting
  void drawAboveBar(
    CanvasWrapper canvasWrapper,
    Path aboveBarPath,
    Path filledBelowBarPath,
    PaintHolder<LineChartData> holder,
    LineChartBarData barData,
  ) {
    if (!barData.aboveBarData.show) {
      return;
    }

    final viewSize = canvasWrapper.size;

    final aboveBarLargestRect = Rect.fromLTRB(
      getPixelX(barData.mostLeftSpot.x, viewSize, holder),
      0,
      getPixelX(barData.mostRightSpot.x, viewSize, holder),
      getPixelY(barData.mostBottomSpot.y, viewSize, holder),
    );

    final aboveBar = barData.aboveBarData;
    _barAreaPaint.setColorOrGradient(
      aboveBar.color,
      aboveBar.gradient,
      aboveBarLargestRect,
    );

    if (barData.aboveBarData.applyCutOffY) {
      canvasWrapper.saveLayer(
        Rect.fromLTWH(0, 0, viewSize.width, viewSize.height),
        _clipPaint,
      );
    }

    canvasWrapper.drawPath(aboveBarPath, _barAreaPaint);

    // clear the above area that get out of the bar line
    if (barData.aboveBarData.applyCutOffY) {
      canvasWrapper
        ..drawPath(filledBelowBarPath, _clearBarAreaPaint)
        ..restore();
    }

    /// draw above spots line
    if (barData.aboveBarData.spotsLine.show) {
      for (final spot in barData.spots) {
        if (barData.aboveBarData.spotsLine.checkToShowSpotLine(spot)) {
          final from = Offset(
            getPixelX(spot.x, viewSize, holder),
            getPixelY(spot.y, viewSize, holder),
          );

          Offset to;

          // Check applyCutOffY
          if (barData.aboveBarData.spotsLine.applyCutOffY &&
              barData.aboveBarData.applyCutOffY) {
            to = Offset(
              getPixelX(spot.x, viewSize, holder),
              getPixelY(barData.aboveBarData.cutOffY, viewSize, holder),
            );
          } else {
            to = Offset(
              getPixelX(spot.x, viewSize, holder),
              0,
            );
          }

          final lineStyle = barData.aboveBarData.spotsLine.flLineStyle;
          _barAreaLinesPaint
            ..setColorOrGradientForLine(
              lineStyle.color,
              lineStyle.gradient,
              from: from,
              to: to,
            )
            ..strokeWidth = lineStyle.strokeWidth
            ..transparentIfWidthIsZero();

          canvasWrapper.drawDashedLine(
            from,
            to,
            _barAreaLinesPaint,
            lineStyle.dashArray,
          );
        }
      }
    }
  }

  @visibleForTesting
  void drawBetweenBar(
    CanvasWrapper canvasWrapper,
    Path barPath,
    BetweenBarsData betweenBarsData,
    Rect aroundRect,
    PaintHolder<LineChartData> holder,
  ) {
    final viewSize = canvasWrapper.size;

    _barAreaPaint.setColorOrGradient(
      betweenBarsData.color,
      betweenBarsData.gradient,
      aroundRect,
    );

    canvasWrapper
      ..saveLayer(
        Rect.fromLTWH(0, 0, viewSize.width, viewSize.height),
        _clipPaint,
      )
      ..drawPath(barPath, _barAreaPaint)
      ..restore(); // clear the above area that get out of the bar line
  }

  /// draw the main bar line's shadow by the [barPath]
  @visibleForTesting
  void drawBarShadow(
    CanvasWrapper canvasWrapper,
    Path barPath,
    LineChartBarData barData,
  ) {
    if (!barData.show || barData.shadow.color.a == 0.0) {
      return;
    }
    if (barPath.computeMetrics().isEmpty) {
      return;
    }

    _barPaint
      ..strokeCap = barData.isStrokeCapRound ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin =
          barData.isStrokeJoinRound ? StrokeJoin.round : StrokeJoin.miter
      ..color = barData.shadow.color
      ..shader = null
      ..strokeWidth = barData.barWidth
      ..color = barData.shadow.color
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        Utils().convertRadiusToSigma(barData.shadow.blurRadius),
      );

    barPath = barPath.toDashedPath(barData.dashArray);

    barPath = barPath.shift(barData.shadow.offset);

    canvasWrapper.drawPath(
      barPath,
      _barPaint,
    );
  }

  /// draw the main bar line by the [barPath]
  @visibleForTesting
  void drawBar(
    CanvasWrapper canvasWrapper,
    Path barPath,
    LineChartBarData barData,
    PaintHolder<LineChartData> holder,
  ) {
    if (!barData.show) {
      return;
    }
    final viewSize = canvasWrapper.size;

    _barPaint
      ..strokeCap = barData.isStrokeCapRound ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin =
          barData.isStrokeJoinRound ? StrokeJoin.round : StrokeJoin.miter;

    final rectAroundTheLine = Rect.fromLTRB(
      getPixelX(barData.mostLeftSpot.x, viewSize, holder),
      getPixelY(barData.mostTopSpot.y, viewSize, holder),
      getPixelX(barData.mostRightSpot.x, viewSize, holder),
      getPixelY(barData.mostBottomSpot.y, viewSize, holder),
    );
    _barPaint
      ..setColorOrGradient(
        barData.color,
        barData.gradient,
        rectAroundTheLine,
      )
      ..maskFilter = null
      ..strokeWidth = barData.barWidth
      ..transparentIfWidthIsZero();

    barPath = barPath.toDashedPath(barData.dashArray);
    canvasWrapper.drawPath(barPath, _barPaint);
  }

  @visibleForTesting
  void drawTouchTooltip(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    LineTouchTooltipData tooltipData,
    FlSpot showOnSpot,
    ShowingTooltipIndicators showingTooltipSpots,
    PaintHolder<LineChartData> holder,
  ) {
    final viewSize = canvasWrapper.size;

    const textsBelowMargin = 4;

    // Get the dot height if available
    final dotHeight = _getDotHeight(
      viewSize: viewSize,
      holder: holder,
      showingTooltipSpots: showingTooltipSpots.showingSpots,
    );

    /// creating TextPainters to calculate the width and height of the tooltip
    final drawingTextPainters = <TextPainter>[];

    final tooltipItems =
        tooltipData.getTooltipItems(showingTooltipSpots.showingSpots);
    if (tooltipItems.length != showingTooltipSpots.showingSpots.length) {
      throw Exception('tooltipItems and touchedSpots size should be same');
    }

    for (var i = 0; i < showingTooltipSpots.showingSpots.length; i++) {
      var tooltipItem = tooltipItems[i];
      if (holder.data.rotationQuarterTurns % 4 == 2) {
        tooltipItem = tooltipItems[tooltipItems.length - 1 - i];
      }
      if (tooltipItem == null) {
        continue;
      }

      final span = TextSpan(
        style: Utils().getThemeAwareTextStyle(context, tooltipItem.textStyle),
        text: tooltipItem.text,
        children: tooltipItem.children,
      );

      final tp = TextPainter(
        text: span,
        textAlign: tooltipItem.textAlign,
        textDirection: tooltipItem.textDirection,
        textScaler: holder.textScaler,
      )..layout(maxWidth: tooltipData.maxContentWidth);
      drawingTextPainters.add(tp);
    }
    if (drawingTextPainters.isEmpty) {
      return;
    }

    /// biggerWidth
    /// some texts maybe larger, then we should
    /// draw the tooltip' width as wide as biggerWidth
    ///
    /// sumTextsHeight
    /// sum up all Texts height, then we should
    /// draw the tooltip's height as tall as sumTextsHeight
    var biggerWidth = 0.0;
    var sumTextsHeight = 0.0;
    for (final tp in drawingTextPainters) {
      if (tp.width > biggerWidth) {
        biggerWidth = tp.width;
      }
      sumTextsHeight += tp.height;
    }
    sumTextsHeight += (drawingTextPainters.length - 1) * textsBelowMargin;

    /// if we have multiple bar lines,
    /// there are more than one FlCandidate on touch area,
    /// we should get the most top FlSpot Offset to draw the tooltip on top of it
    final mostTopOffset = Offset(
      getPixelX(showOnSpot.x, viewSize, holder),
      getPixelY(showOnSpot.y, viewSize, holder),
    );

    // Create an extended boundary that includes the center of the dot
    final extendedBoundary = (Offset.zero & viewSize).inflate(dotHeight / 2);

    final isZoomed = holder.chartVirtualRect != null;
    if (isZoomed && !extendedBoundary.contains(mostTopOffset)) {
      return;
    }

    final tooltipWidth = biggerWidth + tooltipData.tooltipPadding.horizontal;
    final tooltipHeight = sumTextsHeight + tooltipData.tooltipPadding.vertical;

    double tooltipTopPosition;
    if (tooltipData.showOnTopOfTheChartBoxArea) {
      tooltipTopPosition = 0 - tooltipHeight - tooltipData.tooltipMargin;
    } else {
      tooltipTopPosition =
          mostTopOffset.dy - tooltipHeight - tooltipData.tooltipMargin;
    }

    final tooltipLeftPosition = getTooltipLeft(
      mostTopOffset.dx,
      tooltipWidth,
      tooltipData.tooltipHorizontalAlignment,
      tooltipData.tooltipHorizontalOffset,
    );

    /// draw the background rect with rounded radius
    var rect = Rect.fromLTWH(
      tooltipLeftPosition,
      tooltipTopPosition,
      tooltipWidth,
      tooltipHeight,
    );

    if (tooltipData.fitInsideHorizontally) {
      if (rect.left < 0) {
        final shiftAmount = 0 - rect.left;
        rect = Rect.fromLTRB(
          rect.left + shiftAmount,
          rect.top,
          rect.right + shiftAmount,
          rect.bottom,
        );
      }

      if (rect.right > viewSize.width) {
        final shiftAmount = rect.right - viewSize.width;
        rect = Rect.fromLTRB(
          rect.left - shiftAmount,
          rect.top,
          rect.right - shiftAmount,
          rect.bottom,
        );
      }
    }

    if (tooltipData.fitInsideVertically) {
      if (rect.top < 0) {
        final shiftAmount = 0 - rect.top;
        rect = Rect.fromLTRB(
          rect.left,
          rect.top + shiftAmount,
          rect.right,
          rect.bottom + shiftAmount,
        );
      }

      if (rect.bottom > viewSize.height) {
        final shiftAmount = rect.bottom - viewSize.height;
        rect = Rect.fromLTRB(
          rect.left,
          rect.top - shiftAmount,
          rect.right,
          rect.bottom - shiftAmount,
        );
      }
    }

    final roundedRect = RRect.fromRectAndCorners(
      rect,
      topLeft: tooltipData.tooltipBorderRadius.topLeft,
      topRight: tooltipData.tooltipBorderRadius.topRight,
      bottomLeft: tooltipData.tooltipBorderRadius.bottomLeft,
      bottomRight: tooltipData.tooltipBorderRadius.bottomRight,
    );

    var topSpot = showingTooltipSpots.showingSpots[0];
    for (final barSpot in showingTooltipSpots.showingSpots) {
      if (barSpot.y > topSpot.y) {
        topSpot = barSpot;
      }
    }

    _bgTouchTooltipPaint.color = tooltipData.getTooltipColor(topSpot);

    final rotateAngle = tooltipData.rotateAngle;
    final rectRotationOffset =
        Offset(0, Utils().calculateRotationOffset(rect.size, rotateAngle).dy);
    final rectDrawOffset = Offset(roundedRect.left, roundedRect.top);

    final textRotationOffset =
        Utils().calculateRotationOffset(rect.size, rotateAngle);

    if (tooltipData.tooltipBorder != BorderSide.none) {
      _borderTouchTooltipPaint
        ..color = tooltipData.tooltipBorder.color
        ..strokeWidth = tooltipData.tooltipBorder.width;
    }
    final reverseQuarterTurnsAngle = -holder.data.rotationQuarterTurns * 90;
    canvasWrapper.drawRotated(
      size: rect.size,
      rotationOffset: rectRotationOffset,
      drawOffset: rectDrawOffset,
      angle: reverseQuarterTurnsAngle + rotateAngle,
      drawCallback: () {
        canvasWrapper
          ..drawRRect(roundedRect, _bgTouchTooltipPaint)
          ..drawRRect(roundedRect, _borderTouchTooltipPaint);
      },
    );

    /// draw the texts one by one in below of each other
    var topPosSeek = tooltipData.tooltipPadding.top;
    for (final tp in drawingTextPainters) {
      final yOffset = rect.topCenter.dy +
          topPosSeek -
          textRotationOffset.dy +
          rectRotationOffset.dy;

      final align = tp.textAlign.getFinalHorizontalAlignment(tp.textDirection);
      final xOffset = switch (align) {
        HorizontalAlignment.left => rect.left + tooltipData.tooltipPadding.left,
        HorizontalAlignment.right =>
          rect.right - tooltipData.tooltipPadding.right - tp.width,
        _ => rect.center.dx - (tp.width / 2),
      };

      final drawOffset = Offset(
        xOffset,
        yOffset,
      );

      final reverseQuarterTurnsAngle = -holder.data.rotationQuarterTurns * 90;
      canvasWrapper.drawRotated(
        size: rect.size,
        rotationOffset: rectRotationOffset,
        drawOffset: rectDrawOffset,
        angle: reverseQuarterTurnsAngle + rotateAngle,
        drawCallback: () {
          canvasWrapper.drawText(tp, drawOffset);
        },
      );
      topPosSeek += tp.height;
      topPosSeek += textsBelowMargin;
    }
  }

  @visibleForTesting
  double getBarLineXLength(
    LineChartBarData barData,
    Size chartUsableSize,
    PaintHolder<LineChartData> holder,
  ) {
    if (barData.spots.isEmpty) {
      return 0;
    }

    final firstSpot = barData.spots[0];
    final firstSpotX = getPixelX(firstSpot.x, chartUsableSize, holder);

    final lastSpot = barData.spots[barData.spots.length - 1];
    final lastSpotX = getPixelX(lastSpot.x, chartUsableSize, holder);

    return lastSpotX - firstSpotX;
  }

  /// Makes a [LineTouchResponse] based on the provided [localPosition]
  ///
  /// Processes [localPosition] and checks
  /// the elements of the chart that are near the offset,
  /// then makes a [LineTouchResponse] from the elements that has been touched.
  List<TouchLineBarSpot>? handleTouch(
    Offset localPosition,
    Size size,
    PaintHolder<LineChartData> holder,
  ) {
    final data = holder.data;
    final viewSize = holder.getChartUsableSize(size);

    final isZoomed = holder.chartVirtualRect != null;
    if (isZoomed && !size.contains(localPosition)) {
      return null;
    }

    // 檢查是否觸碰到背景區塊
    final touchedBackgroundBlock = _getTouchedBackgroundBlock(
      localPosition,
      viewSize,
      holder,
    );

    if (touchedBackgroundBlock != null) {
      // 如果觸碰到背景區塊且有 tooltip，顯示背景區塊的 tooltip
      // 這裡需要在 LineTouchResponse 中處理
    }

    /// it holds list of nearest touched spots of each line
    /// and we use it to draw touch stuff on them
    final touchedSpots = <TouchLineBarSpot>[];

    /// draw each line independently on the chart
    for (var i = 0; i < data.lineBarsData.length; i++) {
      final barData = data.lineBarsData[i];

      // find the nearest spot on touch area in this bar line
      final foundTouchedSpot = getNearestTouchedSpot(
        viewSize,
        localPosition,
        barData,
        i,
        holder,
      );

      if (foundTouchedSpot != null) {
        touchedSpots.add(foundTouchedSpot);
      }
    }

    touchedSpots.sort((a, b) => a.distance.compareTo(b.distance));

    return touchedSpots.isEmpty ? null : touchedSpots;
  }

  /// 取得被觸碰的背景區塊
  TouchedBackgroundBlock? _getTouchedBackgroundBlock(
    Offset localPosition,
    Size viewSize,
    PaintHolder<LineChartData> holder,
  ) {
    final data = holder.data;
    final touchX = getChartCoordinateX(localPosition.dx, viewSize, holder);

    for (var i = 0; i < data.backgroundBlocks.length; i++) {
      final block = data.backgroundBlocks[i];
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

  /// 獲取圖表座標系統中的 X 值
  double getChartCoordinateX(
      double pixelX, Size viewSize, PaintHolder<LineChartData> holder,) {
    final data = holder.data;
    final chartUsableSize = holder.getChartUsableSize(viewSize);

    final deltaX = data.maxX - data.minX;
    final pixelPerX = chartUsableSize.width / deltaX;

    return (pixelX / pixelPerX) + data.minX;
  }

  /// find the nearest spot base on the touched offset
  // 修正 getNearestTouchedSpot 方法
  /// 根據觸碰偏移量尋找最近的點
  @visibleForTesting
  TouchLineBarSpot? getNearestTouchedSpot(
    Size viewSize,
    Offset touchedPoint,
    LineChartBarData barData,
    int barDataPosition,
    PaintHolder<LineChartData> holder,
  ) {
    final data = holder.data;
    if (!barData.show) {
      return null;
    }

    /// 根據 distanceCalculator 尋找最近的點
    TouchLineBarSpot? nearestTouchedSpot;
    double? nearestDistance;

    for (var i = 0; i < barData.spots.length; i++) {
      final spot = barData.spots[i];
      if (spot.isNull()) continue;

      final distance = data.lineTouchData.distanceCalculator(
        touchedPoint,
        Offset(
          getPixelX(spot.x, viewSize, holder),
          getPixelY(spot.y, viewSize, holder),
        ),
      );

      if (distance <= data.lineTouchData.touchSpotThreshold) {
        if (nearestDistance == null || distance < nearestDistance) {
          nearestDistance = distance;

          // TouchLineBarSpot 建構函式需要 4 個參數：bar, barIndex, spot, distance
          nearestTouchedSpot = TouchLineBarSpot(
            barData, // LineChartBarData: super.bar
            barDataPosition, // int: super.barIndex
            spot, // FlSpot: super.spot
            distance, // double: this.distance
          );
        }
      }
    }

    return nearestTouchedSpot;
  }

  // Get the height of the dot for the given showingTooltipSpots
  double _getDotHeight({
    required Size viewSize,
    required PaintHolder<LineChartData> holder,
    required List<LineBarSpot> showingTooltipSpots,
  }) {
    double? dotHeight;
    for (final info in showingTooltipSpots) {
      // Find the corresponding indicator data for this spot
      final lineData = holder.data.lineBarsData.elementAtOrNull(info.barIndex);
      if (lineData == null) continue;

      final indicators = holder.data.lineTouchData
          .getTouchedSpotIndicator(lineData, [info.spotIndex]);

      final indicatorData = indicators.elementAtOrNull(0);
      if (indicatorData != null && indicatorData.touchedSpotDotData.show) {
        final xPercentInLine = (getPixelX(info.x, viewSize, holder) /
                getBarLineXLength(lineData, viewSize, holder)) *
            100;
        final dotPainter = indicatorData.touchedSpotDotData
            .getDotPainter(info, xPercentInLine, lineData, info.spotIndex);
        final currentDotHeight = dotPainter.getSize(info).height;

        // Keep the largest dot height
        if (dotHeight == null || currentDotHeight > dotHeight) {
          dotHeight = currentDotHeight;
        }
      }
    }
    return dotHeight ?? 0;
  }
}

@visibleForTesting
class LineIndexDrawingInfo {
  LineIndexDrawingInfo(
    this.line,
    this.lineIndex,
    this.spot,
    this.spotIndex,
    this.indicatorData,
  );

  final LineChartBarData line;
  final int lineIndex;
  final FlSpot spot;
  final int spotIndex;
  final TouchedSpotIndicatorData indicatorData;
}
