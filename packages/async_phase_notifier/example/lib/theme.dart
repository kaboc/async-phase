import 'package:flutter/material.dart';

// ignore: avoid_classes_with_only_static_members
abstract final class AppTheme {
  static ThemeData get data {
    return ThemeData.from(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
    );
  }
}
