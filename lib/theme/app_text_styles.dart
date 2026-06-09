import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Single font family (Manrope) — clean, consistent, Hinge-adjacent
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get brand => GoogleFonts.manrope(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
        letterSpacing: -1.2,
        height: 1.1,
      );

  static TextStyle get largeHeading => GoogleFonts.manrope(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
        letterSpacing: -0.6,
        height: 1.2,
      );

  static TextStyle get sectionHeading => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
        letterSpacing: -0.3,
        height: 1.25,
      );

  static TextStyle get cardTitle => GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
        letterSpacing: -0.15,
        height: 1.3,
      );

  static TextStyle get body => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textBody,
        height: 1.55,
      );

  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textBody,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  static TextStyle get label => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.navyMid,
        letterSpacing: 0.1,
      );
}
