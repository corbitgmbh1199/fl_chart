import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 客製化軸線資料
class CustomAxisLinesData with EquatableMixin {
  /// 建立客製化軸線資料
  const CustomAxisLinesData({
    this.horizontalLines = const [],
    this.verticalLines = const [],
    this.show = true,
  });

  /// 水平軸線清單
  final List<CustomHorizontalLine> horizontalLines;

  /// 垂直軸線清單
  final List<CustomVerticalLine> verticalLines;

  /// 是否顯示軸線
  final bool show;

  /// 複製並替換指定值
  CustomAxisLinesData copyWith({
    List<CustomHorizontalLine>? horizontalLines,
    List<CustomVerticalLine>? verticalLines,
    bool? show,
  }) =>
      CustomAxisLinesData(
        horizontalLines: horizontalLines ?? this.horizontalLines,
        verticalLines: verticalLines ?? this.verticalLines,
        show: show ?? this.show,
      );

  /// 線性插值
  static CustomAxisLinesData lerp(
    CustomAxisLinesData a,
    CustomAxisLinesData b,
    double t,
  ) =>
      CustomAxisLinesData(
        horizontalLines: _lerpHorizontalLines(a.horizontalLines, b.horizontalLines, t),
        verticalLines: _lerpVerticalLines(a.verticalLines, b.verticalLines, t),
        show: b.show,
      );

  static List<CustomHorizontalLine> _lerpHorizontalLines(
    List<CustomHorizontalLine> a,
    List<CustomHorizontalLine> b,
    double t,
  ) {
    if (a.length != b.length) return b;
    return List.generate(
      a.length,
      (index) => CustomHorizontalLine.lerp(a[index], b[index], t),
    );
  }

  static List<CustomVerticalLine> _lerpVerticalLines(
    List<CustomVerticalLine> a,
    List<CustomVerticalLine> b,
    double t,
  ) {
    if (a.length != b.length) return b;
    return List.generate(
      a.length,
      (index) => CustomVerticalLine.lerp(a[index], b[index], t),
    );
  }

  @override
  List<Object?> get props => [horizontalLines, verticalLines, show];
}

/// 客製化水平軸線
class CustomHorizontalLine with EquatableMixin {
  /// 建立水平軸線
  const CustomHorizontalLine({
    required this.y,
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.dashArray,
    this.strokeCap = StrokeCap.butt,
  });

  /// Y 軸座標值
  final double y;

  /// 線條顏色
  final Color color;

  /// 線條寬度
  final double strokeWidth;

  /// 虛線樣式
  final List<int>? dashArray;

  /// 線條端點樣式
  final StrokeCap strokeCap;

  /// 複製並替換指定值
  CustomHorizontalLine copyWith({
    double? y,
    Color? color,
    double? strokeWidth,
    List<int>? dashArray,
    StrokeCap? strokeCap,
  }) =>
      CustomHorizontalLine(
        y: y ?? this.y,
        color: color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        dashArray: dashArray ?? this.dashArray,
        strokeCap: strokeCap ?? this.strokeCap,
      );

  /// 線性插值
  static CustomHorizontalLine lerp(
    CustomHorizontalLine a,
    CustomHorizontalLine b,
    double t,
  ) =>
      CustomHorizontalLine(
        y: lerpDouble(a.y, b.y, t) ?? b.y,
        color: Color.lerp(a.color, b.color, t) ?? b.color,
        strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t) ?? b.strokeWidth,
        dashArray: b.dashArray,
        strokeCap: b.strokeCap,
      );

  @override
  List<Object?> get props => [y, color, strokeWidth, dashArray, strokeCap];
}

/// 客製化垂直軸線
class CustomVerticalLine with EquatableMixin {
  /// 建立垂直軸線
  const CustomVerticalLine({
    required this.x,
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.dashArray,
    this.strokeCap = StrokeCap.butt,
  });

  /// X 軸座標值
  final double x;

  /// 線條顏色
  final Color color;

  /// 線條寬度
  final double strokeWidth;

  /// 虛線樣式
  final List<int>? dashArray;

  /// 線條端點樣式
  final StrokeCap strokeCap;

  /// 複製並替換指定值
  CustomVerticalLine copyWith({
    double? x,
    Color? color,
    double? strokeWidth,
    List<int>? dashArray,
    StrokeCap? strokeCap,
  }) =>
      CustomVerticalLine(
        x: x ?? this.x,
        color: color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        dashArray: dashArray ?? this.dashArray,
        strokeCap: strokeCap ?? this.strokeCap,
      );

  /// 線性插值
  static CustomVerticalLine lerp(
    CustomVerticalLine a,
    CustomVerticalLine b,
    double t,
  ) =>
      CustomVerticalLine(
        x: lerpDouble(a.x, b.x, t) ?? b.x,
        color: Color.lerp(a.color, b.color, t) ?? b.color,
        strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t) ?? b.strokeWidth,
        dashArray: b.dashArray,
        strokeCap: b.strokeCap,
      );

  @override
  List<Object?> get props => [x, color, strokeWidth, dashArray, strokeCap];
}
