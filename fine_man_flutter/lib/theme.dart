import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/ledger.dart';

/// Spreadsheet palette: a white sheet with light gray gridlines on a
/// pale gray page, and one accent per column.
abstract final class Palette {
  /// The page behind the sheet.
  static const paper = Color(0xFFF8F9FA);

  /// The sheet itself.
  static const sheet = Color(0xFFFFFFFF);

  /// Header row and sub-entry cells.
  static const headerFill = Color(0xFFF1F3F4);
  static const ink = Color(0xFF202124);
  static const muted = Color(0xFF5F6368);

  /// Gridlines between cells.
  static const rule = Color(0xFFE1E3E6);

  /// Heavier lines: column dividers and the sheet's edge.
  static const grid = Color(0xFFC4C7C5);

  /// Destructive actions and errors.
  static const redRule = Color(0xFFC5221F);

  static const columns = {
    LedgerColumn.need: Color(0xFF2E6A4C),
    LedgerColumn.work: Color(0xFF2C5A88),
    LedgerColumn.want: Color(0xFF8E6214),
    LedgerColumn.luxury: Color(0xFF773B74),
    LedgerColumn.tithe: Color(0xFF8A2E2A),
  };

  static Color of(LedgerColumn column) => columns[column]!;
}

abstract final class Fonts {
  /// Table names and page titles.
  static TextStyle display(double size, {Color color = Palette.ink}) =>
      GoogleFonts.ibmPlexSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.2,
        color: color,
      );

  /// Every figure in the app: tabular, adding-machine numerals.
  static TextStyle figure(
    double size, {
    Color color = Palette.ink,
    FontWeight weight = FontWeight.w500,
  }) => GoogleFonts.ibmPlexMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Small uppercase labels for column heads and metadata.
  static TextStyle label({Color color = Palette.muted, double size = 12}) =>
      GoogleFonts.ibmPlexSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: color,
      );
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Palette.columns[LedgerColumn.need]!,
        surface: Palette.sheet,
      ).copyWith(
        primary: Palette.ink,
        onPrimary: Palette.sheet,
        onSurface: Palette.ink,
        onSurfaceVariant: Palette.muted,
        outline: Palette.rule,
        outlineVariant: Palette.rule,
        error: Palette.redRule,
      );
  final body = GoogleFonts.ibmPlexSansTextTheme().apply(
    bodyColor: Palette.ink,
    displayColor: Palette.ink,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.paper,
    textTheme: body,
    dividerColor: Palette.rule,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.ink,
        foregroundColor: Palette.sheet,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: body.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.ink,
        minimumSize: const Size(48, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Palette.rule),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Palette.rule),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Palette.ink, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.sheet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      titleTextStyle: Fonts.display(24),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Palette.sheet,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Palette.rule),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.ink,
      actionTextColor: Color(0xFFF2C9A0),
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 500),
    ),
  );
}
