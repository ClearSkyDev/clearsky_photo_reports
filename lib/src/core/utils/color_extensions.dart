import 'package:flutter/material.dart';

extension ColorToArgb on Color {
  /// Returns this color as a 32-bit ARGB integer.
  int toArgb() => (alpha << 24) | (red << 16) | (green << 8) | blue;
}
