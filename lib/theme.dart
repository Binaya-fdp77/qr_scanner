import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Brand {
  static const ember = Color(0xFFC2410C);
  static const deep = Color(0xFF7C2D12);
  static const cream = Color(0xFFFFF7ED);
  static const ink = Color(0xFF1C1917);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFDC2626);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Brand.ember),
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
  );
  return base.copyWith(
    scaffoldBackgroundColor: Brand.cream,
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
        .apply(bodyColor: Brand.ink, displayColor: Brand.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFBF7),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Brand.ember, width: 1.6),
      ),
    ),
  );
}

class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEDD5), Color(0xFFFFF7ED), Color(0xFFFED7AA)],
        ),
      ),
      child: child,
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 88});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Brand.deep.withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.restaurant, size: size * 0.5, color: Brand.ember),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(26)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Brand.deep.withValues(alpha: .12),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}