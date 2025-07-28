import 'package:flutter/material.dart';

extension ColorToArgb on Color {
  /// Returns this color as a 32-bit ARGB integer.
  int toArgb() => (alpha << 24) | (red << 16) | (green << 8) | blue;
}

extension ColorWithValues on Color {
  Color withValues({int? alpha, int? red, int? green, int? blue}) {
    return Color.fromARGB(
      alpha ?? this.alpha,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}
