import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BlockLineChartTestApp extends StatelessWidget {
  const BlockLineChartTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '線條圖展示',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BlockLineChartPage(),
    );
  }
}

class BlockLineChartPage extends StatefulWidget {
  const BlockLineChartPage({super.key});

  @override
  State<BlockLineChartPage> createState() => _BlockLineChartPageState();
}

class _BlockLineChartPageState extends State<BlockLineChartPage> {
  // 新增狀態變數來追蹤觸摸位置
  double? _touchedX;
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
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('24小時活動分佈圖 (線條版)'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日時間安排',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '點擊圖表查看詳細資訊',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            // 固定高度的圖表容器
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 24 * 3600, // 24小時轉換為秒
                  minY: 0,
                  maxY: 1,
                  // 新增 extraLinesData 來繪製 highlight 虛線
                  extraLinesData: ExtraLinesData(
                    verticalLines: _touchedX != null
                        ? [
                            VerticalLine(
                              x: _touchedX!, // 觸摸點的 X 座標
                              color: Colors.blue.withValues(alpha: 0.8), // 線條顏色
                              strokeWidth: 2, // 線條粗細
                              dashArray: [4, 4], // 虛線樣式 [實線長度, 間隔長度]
                            ),
                          ]
                        : [],
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    // 新增觸摸回調函式來更新 highlight 線條位置
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? response) {
                      // 擴展事件類型判斷，包含長壓後的移動事件
                      if (event is FlTapDownEvent ||
                          event is FlPanStartEvent ||
                          event is FlPanUpdateEvent ||
                          event is FlLongPressStart ||
                          event is FlLongPressMoveUpdate
                          ) {
                        
                        // 使用 response 中的精確資料
                        if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
                          final touchedSpot = response.lineBarSpots!.first;
                          setState(() {
                            _touchedX = touchedSpot.x;
                          });
                        }
                      } else if (event is FlPointerExitEvent ||
                          event is FlTapUpEvent ||
                          event is FlPanEndEvent ||
                          event is FlLongPressEnd) { // 也要處理長壓結束事件
                        setState(() {
                          _touchedX = null;
                        });
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.black87,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (touchedSpots) {
                        // 檢查是否應該顯示 tooltip
                        if (_touchedX == null || touchedSpots.isEmpty) {
                          return List.generate(
                              touchedSpots.length, (index) => null);
                        }

                        final segment = _getSegmentAtX(_touchedX!);

                        // 建立結果列表，預設都是 null
                        List<LineTooltipItem?> tooltipItems =
                            List.generate(touchedSpots.length, (index) => null);

                        // 只為第一個位置建立 tooltip，其他保持 null
                        if (segment != null) {
                          final startSeconds = segment['start'] as int;
                          final endSeconds = segment['end'] as int;

                          String formatTime(int seconds) {
                            final hours = seconds ~/ 3600;
                            final minutes = (seconds % 3600) ~/ 60;
                            final sec = seconds % 60;
                            return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
                          }

                          // 只在第一個位置設定 tooltip
                          tooltipItems[0] = LineTooltipItem(
                            '${segment['activity']}\n${formatTime(startSeconds)} - ${formatTime(endSeconds)}\n觸碰位置: ${formatTime(_touchedX!.round())}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          );
                        }

                        return tooltipItems;
                      },
                    ),
                    // 調整 highlight 線條樣式
                    getTouchedSpotIndicator:
                        (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((spotIndex) {
                        return const TouchedSpotIndicatorData(
                            // 垂直 highlight 線條設定
                            FlLine(color: Colors.transparent, strokeWidth: 0),
                            // 觸控點設定
                            FlDotData(show: false));
                      }).toList();
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // 每6小時顯示一次標籤 (6 * 3600 = 21600秒)
                          if (value % 21600 == 0) {
                            final hour = (value ~/ 3600).toInt();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        interval: 3600, // 每小時一個間隔 (3600秒)
                        reservedSize: 32,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    verticalInterval: 21600, // 每6小時一條網格線 (6 * 3600 = 21600秒)
                    drawHorizontalLine: false,
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 0.5,
                        dashArray: [3, 3],
                      );
                    },
                  ),
                  lineBarsData: createLineChartData(),
                ),
                // 加入縮放設定
                transformationConfig: FlTransformationConfig(
                  transformationController: _transformationController,
                  scaleAxis: FlScaleAxis.horizontal,
                  maxScale: 100,
                  minScale: 1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 活動圖例
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final segments = _getSegments();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: segments.map((segment) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (segment['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (segment['color'] as Color).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: segment['color'] as Color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                segment['activity'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getSegments() {
    return [
      {
        'start': 0,
        'end': 23400,
        'color': Colors.indigo[400],
        'activity': '睡眠'
      }, // 0:00 - 6:30 (23400秒)
      {
        'start': 23400,
        'end': 28800,
        'color': Colors.orange[400],
        'activity': '晨間活動'
      }, // 6:30 - 8:00 (28800秒)
      {
        'start': 28800,
        'end': 42300,
        'color': Colors.green[500],
        'activity': '工作'
      }, // 8:00 - 11:45 (42300秒)
      {
        'start': 42300,
        'end': 46800,
        'color': Colors.amber[400],
        'activity': '午餐'
      }, // 11:45 - 13:00 (46800秒)
      {
        'start': 46800,
        'end': 65400,
        'color': Colors.green[500],
        'activity': '工作'
      }, // 13:00 - 18:10 (65400秒)
      {
        'start': 65400,
        'end': 72900,
        'color': Colors.purple[400],
        'activity': '晚餐與休閒'
      }, // 18:10 - 20:15 (72900秒)
      {
        'start': 72900,
        'end': 79800,
        'color': Colors.pink[400],
        'activity': '娛樂'
      }, // 20:15 - 22:10 (79800秒)
      {
        'start': 79800,
        'end': 86400,
        'color': Colors.blue[400],
        'activity': '準備睡眠'
      }, // 22:10 - 24:00 (86400秒)
    ];
  }

  Map<String, dynamic>? _getSegmentAtX(double x) {
    final segments = _getSegments();
    for (final segment in segments) {
      if (x >= segment['start'] && x <= segment['end']) {
        return segment;
      }
    }
    return null;
  }

  List<LineChartBarData> createLineChartData() {
    final segments = _getSegments();
    List<LineChartBarData> lineBars = [];

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final startTime = segment['start'] as int;
      final endTime = segment['end'] as int;
      final color = segment['color'] as Color;

      // 建立水平線條資料點，在整個時間區間內建立多個點
      List<FlSpot> spots = [];

      // 在起點和終點之間建立多個資料點，讓整個線條區域都能觸發 tooltip
      for (double time = startTime.toDouble();
          time <= endTime.toDouble();
          time += 36) {
        spots.add(FlSpot(time, 0.5));
      }

      // 確保終點也被包含
      if (spots.last.x != endTime.toDouble()) {
        spots.add(FlSpot(endTime.toDouble(), 0.5));
      }

      // 判斷是否需要圓角：第一段的左端和最後一段的右端
      final isFirstSegment = i == 0;
      final isLastSegment = i == segments.length - 1;

      // 只有第一段或最後一段才需要啟用圓角遮罩
      final needsEndCapsMask = isFirstSegment || isLastSegment;

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: false, // 使用直線
          color: color,
          barWidth: 30, // 設定很粗的線條寬度
          isStrokeCapRound: false, // 不使用圓角端點
          dotData: const FlDotData(show: false), // 不顯示資料點
          belowBarData: BarAreaData(show: false), // 不顯示填充區域
          // 啟用圓角遮罩
          enableEndCapsMask: needsEndCapsMask,
          endCapsRadius: 15.0, // 設定圓角半徑，可以根據需要調整
          // 精確控制哪一端需要圓角
          enableLeftEndCap: isFirstSegment, // 只有第一段需要左端圓角
          enableRightEndCap: isLastSegment, // 只有最後一段需要右端圓角
        ),
      );
    }

    return lineBars;
  }
}
