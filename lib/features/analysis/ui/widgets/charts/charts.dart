/// Barrel file for chart widgets.
///
/// This directory contains chart widgets split from the original analysis_charts.dart
/// for better maintainability. Import this file to access all chart widgets.
///
/// Widgets that have been split into separate files:
export 'top_users_chart.dart';
export 'hourly_activity_chart.dart';
export 'weekly_activity_chart.dart';

/// Widgets still in analysis_charts.dart (to be migrated incrementally):
/// - MonthlyActivityChart
/// - TopConversationDaysChart
/// - RecentActivityChart
/// - TopEmojisChart
/// - TopDomainsChart
/// - MessageLengthChart
/// - TimeActivityOverview
