/// Re-export insight widgets from their new split location.
///
/// This file is kept for backward compatibility. New code should import
/// directly from 'insights/insights.dart'.
///
/// Split into separate files for maintainability:
/// - safe_type_converter.dart - Type conversion utilities
/// - conversation_dynamics_widget.dart - Conversation dynamics display
/// - relationship_analysis_widget.dart - Relationship analysis display
/// - behavior_patterns_widget.dart - Behavior patterns display
/// - temporal_insights_widget.dart - Temporal insights display
export 'insights/insights.dart';
