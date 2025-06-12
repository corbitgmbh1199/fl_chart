// 更新測試應用程式來驗證新的優先級邏輯
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
}