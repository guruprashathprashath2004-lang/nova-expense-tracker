import 'package:flutter/material.dart';

class AppCategory {
  final String name;
  final IconData icon;
  final Color color;
  const AppCategory(this.name, this.icon, this.color);
}

const List<AppCategory> kDefaultCategories = [
  AppCategory('Food', Icons.restaurant_rounded, Color(0xFFFF7A59)),
  AppCategory(
      'Transport', Icons.directions_car_filled_rounded, Color(0xFF4F8EF7)),
  AppCategory('Bills', Icons.receipt_long_rounded, Color(0xFFF7B84F)),
  AppCategory('Shopping', Icons.shopping_bag_rounded, Color(0xFFE85D9C)),
  AppCategory('Health', Icons.favorite_rounded, Color(0xFF4FD1A5)),
  AppCategory('Entertainment', Icons.movie_filter_rounded, Color(0xFF9B7BF7)),
  AppCategory('Education', Icons.school_rounded, Color(0xFF5DC8E8)),
  AppCategory('Other', Icons.category_rounded, Color(0xFF9AA3B2)),
];

AppCategory categoryByName(String name) => kDefaultCategories.firstWhere(
      (c) => c.name == name,
      orElse: () => kDefaultCategories.last,
    );

const Map<String, String> kCurrencies = {
  'LKR': 'Rs.',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'INR': '₹',
};

const Color kAppAccent = Color(0xFF4F8EF7);

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  static const card = 26.0;
  static const sheet = 32.0;
  static const pill = 999.0;
  static const small = 14.0;
}

class GlassTokens {
  static const double blurSigma = 20.0;
  static const double surfaceOpacityDark = 0.12;
  static const double surfaceOpacityLight = 0.55;
  static const double borderOpacity = 0.18;
  static const double shadowBlur = 30.0;
  static const double shadowSpread = -6.0;
  static const double shadowOpacity = 0.12;
}
