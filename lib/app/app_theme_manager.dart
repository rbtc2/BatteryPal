import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// 앱 테마 관리 클래스
/// Phase 9에서 실제 구현
class AppThemeManager {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppColors.primaryColorValue),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      // Noto Sans KR 폰트 적용 (한국어 최적화)
      textTheme: GoogleFonts.notoSansTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.primaryColorValue),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppColors.primaryColorValue),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      // Noto Sans KR 폰트 적용 (한국어 최적화)
      textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );
  }

  /// 현재 테마 반환 (기본값: 다크 테마)
  static ThemeData getCurrentTheme({bool isDarkMode = true}) {
    return isDarkMode ? darkTheme : lightTheme;
  }
}
