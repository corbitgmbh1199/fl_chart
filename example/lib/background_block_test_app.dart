// 更新測試應用程式來驗證新的優先級邏輯
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BackgroundBlockTestApp extends StatelessWidget {
  const BackgroundBlockTestApp({super.key});

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
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          const FlSpot(0, 1),
                          const FlSpot(1, 3),
                          const FlSpot(2, 2), // 在測試區塊 1 中
                          const FlSpot(3, 4),
                          const FlSpot(4, 2), // 在測試區塊 2 中
                          const FlSpot(5, 5),
                        ],
                        color: Colors.blue,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                    backgroundBlocks: [
                      BackgroundBlockData(
                        startX: 1,
                        endX: 2.5,
                        color: Colors.red.withValues(alpha: 0.2),
                        tooltipData: const BackgroundBlockTooltipData(
                          text: '測試區塊 1\n包含 FlSpot(2, 2)',
                        ),
                      ),
                      BackgroundBlockData(
                        startX: 3.5,
                        endX: 4.5,
                        color: Colors.green.withValues(alpha: 0.2),
                        tooltipData: const BackgroundBlockTooltipData(
                          text: '測試區塊 2\n包含 FlSpot(4, 2)',
                        ),
                      ),
                    ],
                    lineTouchData: const LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        // getTooltipColor: (touchedSpot) => Colors.blueAccent,
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