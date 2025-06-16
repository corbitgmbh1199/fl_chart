// 更新測試應用程式來驗證新的優先級邏輯
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/svg.dart';

class BackgroundBlockTestApp extends StatefulWidget {
  const BackgroundBlockTestApp({super.key});

  @override
  State<BackgroundBlockTestApp> createState() => _BackgroundBlockTestAppState();
}

class _BackgroundBlockTestAppState extends State<BackgroundBlockTestApp> {
  // 加入 TransformationController
  late TransformationController _transformationController;
  double _currentScale = 1.0; // 追蹤當前縮放比例

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    // 監聽縮放變化
    _transformationController.addListener(_onTransformationChanged);
  }
  
  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final newScale = _transformationController.value.getMaxScaleOnAxis();
    if ((newScale - _currentScale).abs() > 0.1) {
      // 避免過於頻繁的重新構建
      setState(() {
        _currentScale = newScale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('背景區塊測試 - Spots 優先')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                '測試說明：\n'
                '- FlSpot(2, 2) 在測試區塊 1 中\n'
                '- FlSpot(4, 2) 在測試區塊 2 中\n'
                '- 觸碰 spots 時應優先顯示 spots tooltip\n'
                '- 只有空白區域才顯示背景區塊 tooltip',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  transformationConfig: FlTransformationConfig(
                    transformationController: _transformationController,
                    scaleAxis: FlScaleAxis.horizontal,
                    maxScale: 100,
                    minScale: 1,
                  ),
                  LineChartData(
                    // 設定圖表範圍以便測試放大功能
                    minX: 0,
                    maxX: 20,
                    minY: 0,
                    maxY: 10,
                    clipData: const FlClipData.all(),
                    
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          // 新增更多資料點來測試縮放效果
                          const FlSpot(0, 2),
                          const FlSpot(0.5, 2.2),
                          const FlSpot(1, 3.5),
                          const FlSpot(1.5, 3.1),
                          const FlSpot(2, 2.8), // 在測試區塊 1 中
                          const FlSpot(2.5, 3.8),
                          const FlSpot(3, 4.2),
                          const FlSpot(3.5, 3.9),
                          const FlSpot(4, 1.8), // 在測試區塊 2 中
                          const FlSpot(4.5, 2.1),
                          const FlSpot(5, 5.5),
                          const FlSpot(5.5, 5.2),
                          const FlSpot(6, 3.2), // 在測試區塊 3 中
                          const FlSpot(6.5, 4.1),
                          const FlSpot(7, 6.8),
                          const FlSpot(7.5, 6.2),
                          const FlSpot(8, 4.5), // 在測試區塊 4 中
                          const FlSpot(8.5, 3.8),
                          const FlSpot(9, 2.3),
                          const FlSpot(9.5, 3.1),
                          const FlSpot(10, 7.2),
                          const FlSpot(10.5, 6.9),
                          const FlSpot(11, 5.8), // 在測試區塊 5 中
                          const FlSpot(11.5, 6.1),
                          const FlSpot(12, 3.9),
                          const FlSpot(12.5, 4.2),
                          const FlSpot(13, 8.1),
                          const FlSpot(13.5, 7.8),
                          const FlSpot(14, 4.7), // 在測試區塊 6 中
                          const FlSpot(14.5, 5.1),
                          const FlSpot(15, 6.3),
                          const FlSpot(15.5, 5.9),
                          const FlSpot(16, 2.9), // 在測試區塊 7 中
                          const FlSpot(16.5, 3.2),
                          const FlSpot(17, 7.6),
                          const FlSpot(17.5, 7.1),
                          const FlSpot(18, 5.1), // 在測試區塊 8 中
                          const FlSpot(18.5, 5.5),
                          const FlSpot(19, 8.9),
                          const FlSpot(19.5, 8.5),
                        ],
                        color: Colors.blue,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                    // 客製化軸線
                    customAxisLines: const CustomAxisLinesData(
                      horizontalLines: [
                        // 在 Y = 5 的位置繪製紅色實線
                        CustomHorizontalLine(
                          y: 5,
                          color: Colors.green,
                          strokeWidth: 2,
                        ),
                        // 在 Y = 10 的位置繪製藍色虛線
                        CustomHorizontalLine(
                          y: 10,
                          color: Colors.blue,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ],
                      verticalLines: [
                        // 在 X = 3 的位置繪製綠色實線
                        CustomVerticalLine(
                          x: 3,
                          color: Colors.green,
                          strokeWidth: 2,
                        ),
                      ],
                    ),
                    backgroundBlocks: [
                      // 測試區塊 1
                      BackgroundBlockData(
                        startX: 1.5,
                        endX: 3.5,
                        color: Colors.red.withValues(alpha: 0.2),
                        label: '警告區間',
                        data: {
                          'severity': 'high',
                          'type': 'warning'
                        }, // 可選的自定義資料
                        iconWidget: const Icon(
                          Icons.warning,
                          color: Colors.redAccent, // 保持原生顏色
                        ),
                        iconSize: const Size(24, 24),
                        showIconMinWidth: 30,
                      ),
                      // 測試區塊 2
                      BackgroundBlockData(
                        startX: 3.8,
                        endX: 5.2,
                        color: Colors.green.withValues(alpha: 0.2),
                        label: '重要時段', // 只需要設定標籤
                      ),
                      // 測試區塊 3
                      BackgroundBlockData(
                        startX: 5.8,
                        endX: 7.2,
                        color: Colors.orange.withValues(alpha: 0.2),
                        label: '重要時段', // 只需要設定標籤
                      ),
                      // 測試區塊 4
                      BackgroundBlockData(
                        startX: 7.8,
                        endX: 9.2,
                        color: Colors.purple.withValues(alpha: 0.2),
                        label: '重要時段', // 只需要設定標籤
                      ),
                      // 測試區塊 5
                      BackgroundBlockData(
                        startX: 10.5,
                        endX: 12.5,
                        color: Colors.cyan.withValues(alpha: 0.2),
                        label: '重要時段', // 只需要設定標籤
                      ),
                      // 測試區塊 6
                      BackgroundBlockData(
                        startX: 13.8,
                        endX: 15.2,
                        color: Colors.pink.withValues(alpha: 0.2),
                        label: '警告區間',
                        data: {
                          'severity': 'high',
                          'type': 'warning'
                        }, // 可選的自定義資料
                        iconWidget: SvgPicture.asset('assets/icons/ic_pie_chart.svg', color: Colors.red,),
                        iconSize: const Size(24, 24),
                        showIconMinWidth: 60,
                      ),
                      // 測試區塊 7
                      BackgroundBlockData(
                        startX: 15.8,
                        endX: 17.2,
                        color: Colors.amber.withValues(alpha: 0.2),
                        label: '重要時段', // 只需要設定標籤
                      ),
                      // 測試區塊 8
                      BackgroundBlockData(
                        startX: 17.8,
                        endX: 19.5,
                        color: Colors.teal.withValues(alpha: 0.2),
                        label: '重要時段', // 只需要設定標籤
                      ),
                    ],
                    // 啟用觸控和縮放功能
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      backgroundBlockTooltipData: BackgroundBlockTooltipData(
                        // 自定義 tooltip 項目（可選）
                        getTooltipItems: (touchedBlock) {
                          final blockData = touchedBlock.blockData;
                          final items = <BackgroundBlockTooltipItem>[];

                          // 主要標籤
                          if (blockData.label != null) {
                            items.add(BackgroundBlockTooltipItem(
                              blockData.label!,
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ));
                          }

                          // 座標資訊
                          items.add(BackgroundBlockTooltipItem(
                            '範圍: ${blockData.startX} - ${blockData.endX}',
                            const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ));

                          // 自定義資料（如果有的話）
                          if (blockData.data != null) {
                            final customData = blockData.data!;
                            if (customData.containsKey('severity')) {
                              items.add(BackgroundBlockTooltipItem(
                                '嚴重度: ${customData['severity']}',
                                const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ));
                            }
                          }

                          return items;
                        },
                        // 自定義背景顏色（可選）
                        getTooltipColor: (touchedBlock) {
                          return touchedBlock.blockData.color
                                  ?.withValues(alpha: 0.9) ??
                              Colors.black87;
                        },
                        getTooltipAlignment: (touchedBlock, chartSize) {
                          return preciseBackgroundBlockTooltipAlignment(
                            touchedBlock,
                            chartSize,
                          );
                        },
                        // 外觀設定
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: const EdgeInsets.all(12),
                        tooltipBorder:
                            const BorderSide(color: Colors.white30, width: 1),
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                      ),
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.blueAccent,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            return LineTooltipItem(
                              'X: ${barSpot.x.toStringAsFixed(1)}\nY: ${barSpot.y.toStringAsFixed(1)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    // 網格設定
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 2, // 較大的間隔避免效能問題
                      verticalInterval: 4, // 較大的間隔避免效能問題
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    // 標題設定
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 4, // 增加間隔避免過密
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 2, // 增加間隔避免過密
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    // 邊框設定
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 修正預設對齊函式，讓它們基於整個圖表範圍而不是背景區塊範圍

  /// 預設的動態對齊函式：根據觸碰點在整個圖表中的位置決定對齊方式
  ///
  /// 這個函式會分析觸碰點在整個圖表中的位置，並自動選擇最適合的 tooltip 對齊方式：
  /// - 如果觸碰點位於圖表右側，tooltip 會向左對齊
  /// - 如果觸碰點位於圖表左側，tooltip 會向右對齊
  /// - 其他情況則會置中對齊
  FLHorizontalAlignment defaultBackgroundBlockTooltipAlignment(
    TouchedBackgroundBlock touchedBlock,
    Size chartSize,
  ) {
    final blockCenterX =
        (touchedBlock.blockData.startX + touchedBlock.blockData.endX) / 2;

    // 計算觸碰點在圖表中的相對位置（0.0 = 左邊界，1.0 = 右邊界）
    // 這裡需要從 touchedBlock 中取得圖表的最小值和最大值範圍
    // 但由於我們沒有直接存取權限，可以使用一個通用的邏輯

    // 假設使用者會在設定中提供圖表的範圍資訊，或者使用預設的閾值
    // 這個邏輯可以根據實際的圖表資料範圍進行調整

    // 簡單的方式：根據 chartSize.width 和觸碰點計算相對位置
    // 但這需要知道圖表的實際資料範圍，所以使用基於位置的邏輯

    if (blockCenterX > 7) {
      // 可以根據實際圖表範圍調整
      // 區塊在右側，tooltip 向左對齊
      return FLHorizontalAlignment.right;
    } else if (blockCenterX < 3) {
      // 可以根據實際圖表範圍調整
      // 區塊在左側，tooltip 向右對齊
      return FLHorizontalAlignment.left;
    } else {
      // 區塊在中央，tooltip 置中對齊
      return FLHorizontalAlignment.center;
    }
  }

  /// 智慧型動態對齊函式：根據觸碰點在圖表中的位置決定對齊方式
  ///
  /// 這個函式使用更精確的計算方式，考慮整個圖表的尺寸
  FLHorizontalAlignment smartBackgroundBlockTooltipAlignment(
    TouchedBackgroundBlock touchedBlock,
    Size chartSize,
  ) {
    // 計算區塊中心點
    final blockCenterX =
        (touchedBlock.blockData.startX + touchedBlock.blockData.endX) / 2;

    // 這裡應該要能夠存取圖表的資料範圍 (minX, maxX)
    // 由於目前的設計限制，我們使用一個簡化的邏輯
    // 實際實作中，可能需要將圖表範圍資訊傳遞給這個函式

    // 假設圖表的 X 軸範圍，這可以透過 chartData 參數傳遞（需要修改函式簽名）
    // 或者使用固定的閾值

    // 使用相對位置判斷
    if (blockCenterX >= 8) {
      // 右側區域，tooltip 向左對齊避免超出邊界
      return FLHorizontalAlignment.right;
    } else if (blockCenterX <= 2) {
      // 左側區域，tooltip 向右對齊避免超出邊界
      return FLHorizontalAlignment.left;
    } else {
      // 中央區域，tooltip 置中對齊
      return FLHorizontalAlignment.center;
    }
  }

  // 使用增強版的對齊函式範例
  FLHorizontalAlignment preciseBackgroundBlockTooltipAlignment(
    TouchedBackgroundBlock touchedBlock,
    Size chartSize,
  ) {
    // 使用相對位置進行更精確的對齊
    final relativePosition = touchedBlock.relativePositionX;

    if (relativePosition != null) {
      if (relativePosition > 0.75) {
        // 觸碰點在圖表右側 25% 區域，tooltip 向左對齊
        return FLHorizontalAlignment.right;
      } else if (relativePosition < 0.25) {
        // 觸碰點在圖表左側 25% 區域，tooltip 向右對齊
        return FLHorizontalAlignment.left;
      } else {
        // 觸碰點在圖表中央 50% 區域，tooltip 置中對齊
        return FLHorizontalAlignment.center;
      }
    }

    // 備用邏輯
    return defaultBackgroundBlockTooltipAlignment(touchedBlock, chartSize);
  }
}