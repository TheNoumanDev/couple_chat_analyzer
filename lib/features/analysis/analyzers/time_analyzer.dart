import 'package:flutter/foundation.dart';
import '../../../shared/domain.dart';
import 'base_analyzer.dart';

class TimeAnalyzer implements BaseAnalyzer {
  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("TimeAnalyzer: Analyzing time patterns");

    final realMessages = chat.messages
        .where((msg) =>
            msg.senderId != "System" &&
            !msg.content.toLowerCase().contains('created group') &&
            !msg.content.toLowerCase().contains('added') &&
            !msg.content.toLowerCase().contains('left'))
        .toList();

    // Hour distribution (0-23)
    final Map<int, int> hourlyActivity = {};
    for (int i = 0; i < 24; i++) {
      hourlyActivity[i] = 0;
    }

    // Day of week distribution (1-7, Monday-Sunday)
    final Map<int, int> weeklyActivity = {};
    for (int i = 1; i <= 7; i++) {
      weeklyActivity[i] = 0;
    }

    // Monthly activity
    final Map<String, int> monthlyActivity = {};

    for (final message in realMessages) {
      final hour = message.timestamp.hour;
      final weekday = message.timestamp.weekday;
      final monthKey = '${message.timestamp.year}-${message.timestamp.month.toString().padLeft(2, '0')}';

      hourlyActivity[hour] = (hourlyActivity[hour] ?? 0) + 1;
      weeklyActivity[weekday] = (weeklyActivity[weekday] ?? 0) + 1;
      monthlyActivity[monthKey] = (monthlyActivity[monthKey] ?? 0) + 1;
    }

    // Find peak activity periods
    final peakHour = hourlyActivity.entries.reduce((a, b) => a.value > b.value ? a : b);
    final peakDay = weeklyActivity.entries.reduce((a, b) => a.value > b.value ? a : b);

    // Convert to chart-friendly format
    final hourlyData = hourlyActivity.entries.map((e) => {
      'hour': e.key,
      'messages': e.value,
    }).toList();

    final weeklyData = weeklyActivity.entries.map((e) => {
      'day': e.key,
      'messages': e.value,
      'dayName': _getDayName(e.key),
    }).toList();

    final monthlyData = monthlyActivity.entries.map((e) => {
      'month': e.key,
      'messages': e.value,
    }).toList()
      ..sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));

    debugPrint("TimeAnalyzer: Peak hour: ${peakHour.key}, Peak day: ${_getDayName(peakDay.key)}");

    return {
      'timeAnalysis': {
        'hourlyActivity': hourlyData,
        'weeklyActivity': weeklyData,
        'monthlyActivity': monthlyData,
        'peakHour': {
          'hour': peakHour.key,
          'messages': peakHour.value,
          'timeRange': '${peakHour.key}:00-${peakHour.key + 1}:00',
        },
        'peakDay': {
          'day': peakDay.key,
          'messages': peakDay.value,
          'dayName': _getDayName(peakDay.key),
        },
      }
    };
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}