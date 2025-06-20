import 'package:flutter/material.dart';
import '../widgets/analysis_charts.dart';
import '../widgets/analysis_cards.dart';

class TimeTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const TimeTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeAnalysis = results['timeAnalysis'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Peak Activity Card
          if (timeAnalysis.containsKey('peakHour') && timeAnalysis.containsKey('peakDay'))
            PeakActivityCard(
              peakHour: timeAnalysis['peakHour'] as Map<String, dynamic>,
              peakDay: timeAnalysis['peakDay'] as Map<String, dynamic>,
            ),
          
          const SizedBox(height: 24),
          
          // Hourly Activity Chart
          if (timeAnalysis.containsKey('hourlyActivity'))
            HourlyActivityChart(
              data: timeAnalysis['hourlyActivity'] as List<dynamic>,
            ),
          
          const SizedBox(height: 24),
          
          // Weekly Activity Chart
          if (timeAnalysis.containsKey('weeklyActivity'))
            WeeklyActivityChart(
              data: timeAnalysis['weeklyActivity'] as List<dynamic>,
            ),
          
          const SizedBox(height: 24),
          
          // Monthly Activity Chart
          if (timeAnalysis.containsKey('monthlyActivity'))
            MonthlyActivityChart(
              data: timeAnalysis['monthlyActivity'] as List<dynamic>,
            ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}