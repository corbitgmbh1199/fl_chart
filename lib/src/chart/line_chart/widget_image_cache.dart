import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Widget 圖片快取管理器（真正支援任何 Widget）
class WidgetImageCache {
  factory WidgetImageCache() => _instance;
  WidgetImageCache._internal();

  static final WidgetImageCache _instance = WidgetImageCache._internal();

  /// 圖片快取
  final Map<String, ui.Image> _cache = {};

  /// 正在處理中的請求
  final Map<String, Future<ui.Image?>> _processing = {};

  /// 取得快取的圖片
  ui.Image? getCachedImage(String cacheKey) {
    return _cache[cacheKey];
  }

  /// 檢查是否有快取的圖片
  bool hasCachedImage(String cacheKey) {
    return _cache.containsKey(cacheKey);
  }

  /// 將**任何** Widget 轉換為圖片並快取
  Future<ui.Image?> convertAndCacheWidget(
    String cacheKey,
    Widget widget,
    Size size,
    BuildContext context,
  ) async {
    // 如果已經有快取，直接回傳
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // 如果正在處理中，等待結果
    if (_processing.containsKey(cacheKey)) {
      return await _processing[cacheKey];
    }

    // 建立新的處理程序
    final future = _createUniversalWidgetImage(widget, size, context);
    _processing[cacheKey] = future;

    try {
      final image = await future;
      if (image != null) {
        _cache[cacheKey] = image;
        debugPrint('✅ Widget 圖片快取成功: $cacheKey (${image.width}x${image.height}) - ${widget.runtimeType}');
      } else {
        debugPrint('❌ Widget 圖片建立失敗: $cacheKey - ${widget.runtimeType}');
      }
      return image;
    } finally {
      unawaited(_processing.remove(cacheKey));
    }
  }

  /// 通用 Widget 轉圖片方法（不分類型，統一處理）
  Future<ui.Image?> _createUniversalWidgetImage(
    Widget widget,
    Size size,
    BuildContext context,
  ) async {
    try {
      debugPrint('🎯 開始轉換任何 Widget: ${widget.runtimeType}，尺寸: $size');

      // 直接使用 Overlay 方法，不再區分 Widget 類型
      return await _captureWidgetViaOverlay(widget, size, context);
    } catch (e) {
      debugPrint('❌ Widget 轉圖片失敗: $e - ${widget.runtimeType}');
      return null;
    }
  }

  /// 使用 Overlay 方法捕獲任何 Widget
  Future<ui.Image?> _captureWidgetViaOverlay(
    Widget widget,
    Size size,
    BuildContext context,
  ) async {
    try {
      debugPrint('🎯 開始 Overlay 捕獲任何 Widget: ${widget.runtimeType}，尺寸: $size');

      final completer = Completer<ui.Image?>();
      final globalKey = GlobalKey();

      // 將 overlayEntry 宣告在外層作用域
      OverlayEntry? overlayEntry;

      // 在下一個 frame 執行
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        try {
          // 建立要捕獲的 Widget，完全包裝原始 Widget
          final captureWidget = RepaintBoundary(
            key: globalKey,
            child: Container(
              width: size.width,
              height: size.height,
              color: Colors.transparent,
              child: Center(
                child: widget, // 不管什麼 Widget 都直接放這裡
              ),
            ),
          );

          // 建立 OverlayEntry
          overlayEntry = OverlayEntry(
            builder: (overlayContext) => Positioned(
              left: -10000, // 移到螢幕外
              top: -10000,
              child: Material(
                type: MaterialType.transparency,
                child: captureWidget,
              ),
            ),
          );

          // 插入到 Overlay
          Overlay.of(context).insert(overlayEntry!);

          // 等待更長時間確保任何類型的 Widget 都能完全渲染
          await Future<void>.delayed(const Duration(milliseconds: 500));

          // 捕獲圖片
          final renderObject = globalKey.currentContext?.findRenderObject() 
              as RenderRepaintBoundary?;

          if (renderObject != null) {
            // 檢查並重試直到 Widget 準備好
            var retryCount = 0;
            const maxRetries = 5;
            
            while (renderObject.debugNeedsPaint && retryCount < maxRetries) {
              debugPrint('⏳ Widget 仍需要重繪，等待... (重試 ${retryCount + 1}/$maxRetries)');
              await Future<void>.delayed(const Duration(milliseconds: 200));
              retryCount++;
            }

            if (!renderObject.debugNeedsPaint) {
              // 使用高品質像素密度
              final image = await renderObject.toImage(pixelRatio: 2);
              debugPrint('✅ 任何 Widget 捕獲成功: ${widget.runtimeType} -> ${image.width}x${image.height}');
              completer.complete(image);
            } else {
              debugPrint('❌ Widget 經過重試仍無法捕獲: ${widget.runtimeType}');
              completer.complete(null);
            }
          } else {
            debugPrint('❌ 找不到 RenderRepaintBoundary: ${widget.runtimeType}');
            completer.complete(null);
          }

          // 清理 Overlay
          try {
            overlayEntry?.remove();
          } catch (e) {
            debugPrint('⚠️ 清理 Overlay 時發生錯誤: $e');
          }
        } catch (e) {
          debugPrint('❌ Widget 捕獲過程錯誤: $e');
          completer.complete(null);
          try {
            overlayEntry?.remove();
          } catch (cleanupError) {
            debugPrint('⚠️ 錯誤清理過程中發生問題: $cleanupError');
          }
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 15), // 給複雜 Widget 更多時間
        onTimeout: () {
          debugPrint('⏰ Widget 捕獲逾時: ${widget.runtimeType}');
          try {
            overlayEntry?.remove();
          } catch (e) {
            debugPrint('⚠️ 逾時清理 Overlay 時發生錯誤: $e');
          }
          return null;
        },
      );
    } catch (e) {
      debugPrint('❌ Overlay Widget 捕獲失敗: $e - ${widget.runtimeType}');
      return null;
    }
  }

  /// 清除快取
  void clearCache() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _processing.clear();
    debugPrint('🗑️ Widget 圖片快取已清除');
  }
}
