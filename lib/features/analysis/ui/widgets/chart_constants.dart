// ============================================================================
// FILE: lib/features/analysis/ui/widgets/chart_constants.dart
// Chart display constants - centralized magic numbers for chart visualizations
// ============================================================================

/// Constants for chart display limits and configurations.
///
/// These values control how many items are shown in various charts
/// and visualizations throughout the app.
class ChartConstants {
  ChartConstants._();

  // ===========================================================================
  // ITEM DISPLAY LIMITS
  // ===========================================================================

  /// Maximum number of top users to show in pie charts and lists
  static const int maxTopUsers = 6;

  /// Maximum number of months to show in monthly activity charts
  static const int maxMonthsDisplayed = 12;

  /// Maximum number of top items (days, emojis, words) to display
  static const int maxTopItems = 10;

  /// Maximum number of recent days to show in activity charts
  static const int maxRecentDays = 14;

  /// Maximum number of top domains to show in shared links section
  static const int maxTopDomains = 5;

  /// Maximum number of milestones/initiators to show in insights
  static const int maxInsightItems = 3;

  // ===========================================================================
  // CHART SIZING
  // ===========================================================================

  /// Default pie chart center space radius
  static const double pieChartCenterRadius = 35.0;

  /// Default spacing between pie chart sections
  static const double pieChartSectionSpacing = 2.0;

  /// Default pie chart section radius
  static const double pieChartSectionRadius = 50.0;

  /// Small pie chart section radius (for touched state)
  static const double pieChartSectionRadiusTouched = 55.0;

  /// Default bar chart bar width
  static const double barChartBarWidth = 12.0;

  /// Default line chart line width
  static const double lineChartLineWidth = 3.0;

  // ===========================================================================
  // ANIMATION DURATIONS
  // ===========================================================================

  /// Duration for chart animations in milliseconds
  static const int chartAnimationDuration = 300;

  // ===========================================================================
  // PADDING & SPACING
  // ===========================================================================

  /// Standard card padding
  static const double cardPadding = 16.0;

  /// Standard spacing between chart elements
  static const double elementSpacing = 8.0;

  /// Large spacing between sections
  static const double sectionSpacing = 24.0;
}
