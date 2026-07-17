import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppFormat {
  AppFormat._();

  static String indianNumber(double amount) {
    final double absAmount = amount.abs();
    final formatter = absAmount % 1 == 0
        ? NumberFormat('#,##,##0', 'en_IN')
        : NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(absAmount);
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(brightness: Brightness.light, useMaterial3: false);
}

extension CustomThemeExtension on ThemeData {
  TextStyle get poppinsBold => TextStyle(fontFamily: Fonts.poppinsSemiBold, color: Colors.black);

  TextStyle get poppinsMedium => TextStyle(fontFamily: Fonts.poppinsMedium, color: Colors.black);

  TextStyle get poppinsRegular => TextStyle(fontFamily: Fonts.poppinsRegular, color: Colors.black);
}

class Fonts {
  Fonts._();

  static const String poppinsSemiBold = 'poppins_semi_bold';
  static const String poppinsMedium = 'poppins_medium';
  static const String poppinsRegular = 'poppins_regular';
}

class MyColors {
  static Color grey = Colors.grey;
  static Color white = Colors.white;
  static Color black = Colors.black;
  static Color primaryColor = const Color(0xFF2E384E);
  static Color secondaryColor = const Color(0xFF92BFCD);
}
