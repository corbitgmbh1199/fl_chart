import 'package:fl_chart/src/chart/line_chart/line_chart_data.dart';
import 'package:flutter/material.dart';

class BackgroundBlockIconWidget extends StatelessWidget {
  const BackgroundBlockIconWidget({
    super.key,
    required this.blockData,
    required this.chartData,
    this.chartVirtualRect,
  });

  final BackgroundBlockData blockData;
  final LineChartData chartData;
  final Rect? chartVirtualRect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 計算區塊在螢幕上的位置
        final blockStartPixel = _getPixelX(blockData.startX, constraints.biggest);
        final blockEndPixel = _getPixelX(blockData.endX, constraints.biggest);
        final blockWidth = blockEndPixel - blockStartPixel;
        
        // 檢查是否應該顯示圖示
        if (blockWidth < blockData.showIconMinWidth) {
          return const SizedBox.shrink();
        }
        
        // 計算圖示的中心位置
        final blockCenterX = (blockStartPixel + blockEndPixel) / 2;
        final blockCenterY = constraints.biggest.height / 2;
        
        final iconLeft = blockCenterX - (blockData.iconSize.width / 2);
        final iconTop = blockCenterY - (blockData.iconSize.height / 2);
        
        // 確保圖示在可見範圍內
        if (iconLeft < 0 || 
            iconTop < 0 || 
            iconLeft + blockData.iconSize.width > constraints.biggest.width ||
            iconTop + blockData.iconSize.height > constraints.biggest.height) {
          return const SizedBox.shrink();
        }
        
        
        return Stack(
          children: [
            Positioned(
              left: iconLeft,
              top: iconTop,
              width: blockData.iconSize.width,
              height: blockData.iconSize.height,
              child: blockData.iconWidget!,
            ),
          ],
        );
      },
    );
  }

  /// 計算圖表座標對應的像素 X 位置
  double _getPixelX(double chartX, Size size) {
    final deltaX = chartData.maxX - chartData.minX;
    if (deltaX == 0) return 0;

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
}
