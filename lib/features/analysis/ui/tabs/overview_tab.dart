import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';
import '../widgets/analysis_charts.dart';

class OverviewTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const OverviewTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final summary = results['summary'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          SummaryCards(summary: summary),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          if (results.containsKey('messagesByUser'))
            QuickStatsCard(
              title: 'Quick Overview',
              stats: _buildQuickStats(results),
            ),
          
          const SizedBox(height: 24),
          
          // Top Users Chart
          if (results.containsKey('messagesByUser'))
            TopUsersChart(
              data: results['messagesByUser'] as List<dynamic>,
            ),
          
          const SizedBox(height: 24),
          
          // Time Activity Overview
          if (results.containsKey('timeAnalysis'))
            TimeActivityOverview(
              timeData: results['timeAnalysis'] as Map<String, dynamic>,
            ),
          
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildQuickStats(Map<String, dynamic> results) {
    final List<Map<String, dynamic>> stats = [];
    
    // Messages per day
    final summary = results['summary'] as Map<String, dynamic>? ?? {};
    if (summary.containsKey('avgMessagesPerDay')) {
      stats.add({
        'icon': Icons.message,
        'label': 'Messages/Day',
        'value': summary['avgMessagesPerDay'].toString(),
      });
    }
    
    // Total media
    if (summary.containsKey('totalMedia')) {
      stats.add({
        'icon': Icons.image,
        'label': 'Media Files',
        'value': summary['totalMedia'].toString(),
      });
    }
    
    // Duration
    if (summary.containsKey('durationDays')) {
      stats.add({
        'icon': Icons.calendar_today,
        'label': 'Duration',
        'value': '${summary['durationDays']} days',
      });
    }
    
    // Total words
    final contentAnalysis = results['contentAnalysis'] as Map<String, dynamic>? ?? {};
    if (contentAnalysis.containsKey('totalWords')) {
      stats.add({
        'icon': Icons.text_fields,
        'label': 'Total Words',
        'value': contentAnalysis['totalWords'].toString(),
      });
    }
    
    return stats;
  }
}