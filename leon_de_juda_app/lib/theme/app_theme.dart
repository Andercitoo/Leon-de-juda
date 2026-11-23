import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color primaryAmber = Color(0xFFF4AE32);
  static const Color amberLight = Color(0xFFFFD88A);
  static const Color alertRed = Color(0xFFB52A3A);
  static const Color brandRed = Color(0xFF7E1D2D);
  static const Color confirmGreen = Color(0xFF247A53);
  static const Color backgroundSand = Color(0xFFFFF8EE);
  static const Color darkText = Color(0xFF2D1C20);
  static const Color mutedText = Color(0xFF79676A);
  static const Color surface = Color(0xFFFFFDF9);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF651726), Color(0xFF9E2638), Color(0xFFC64A3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFFFD77B), Color(0xFFF0A329)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static void tap() {
    unawaited(SystemSound.play(SystemSoundType.click));
    unawaited(HapticFeedback.selectionClick());
  }

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandRed,
      primary: brandRed,
      secondary: primaryAmber,
      error: alertRed,
      surface: surface,
    );
    final textTheme = Typography.material2021().black.apply(
      bodyColor: darkText,
      displayColor: darkText,
      fontFamily: 'Manrope',
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      textTheme: textTheme,
      scaffoldBackgroundColor: backgroundSand,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF1E5D9)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFEADBD0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFEADBD0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryAmber, width: 2),
        ),
        labelStyle: const TextStyle(color: mutedText),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: const BorderSide(color: Color(0xFFEADBD0)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEFE1D6)),
    );
  }
}

class AppPageBackground extends StatelessWidget {
  final Widget child;

  const AppPageBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundSand, Color(0xFFFFF3E2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

class AppGradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? height;
  final EdgeInsetsGeometry padding;
  final bool useGradient;

  const AppGradientButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = !useGradient || onPressed == null
        ? null
        : AppTheme.brandGradient;
    final color = gradient == null
        ? (onPressed == null ? const Color(0xFFC9BCB7) : AppTheme.brandRed)
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: onPressed == null || !useGradient
            ? const []
            : [
                BoxShadow(
                  color: AppTheme.brandRed.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed == null
              ? null
              : () {
                  AppTheme.tap();
                  onPressed!();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            shadowColor: Colors.transparent,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
