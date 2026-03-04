import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  SHARED DESIGN TOKENS  (import this everywhere)
// ─────────────────────────────────────────────
class AppColors {
  static const bg              = Color(0xFF0A0A0F);
  static const surface         = Color(0xFF13131A);
  static const surfaceElevated = Color(0xFF1C1C27);
  static const accent          = Color(0xFFE63946);
  static const accentSoft      = Color(0x33E63946);
  static const gold            = Color(0xFFFFB703);
  static const goldSoft        = Color(0x33FFB703);
  static const purple          = Color(0xFF6C3DD8);
  static const purpleSoft      = Color(0x336C3DD8);
  static const green           = Color(0xFF06D6A0);
  static const greenSoft       = Color(0x2206D6A0);
  static const textPrimary     = Color(0xFFF1F1F5);
  static const textSecondary   = Color(0xFF8A8A9A);
  static const divider         = Color(0xFF2A2A38);
}

class AppText {
  static const headline = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const caption = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const chip = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}