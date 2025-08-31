// ============================================================================
// ENHANCED TIME ANALYZER - Generates all the new analytics data
// File: lib/domain/analysis/analyzers/time_analyzer.dart
// ============================================================================

import 'package:flutter/foundation.dart';
import '../../../shared/domain.dart';
import 'base_analyzer.dart';

class TimeAnalyzer implements BasicAnalyzer {
  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat) async {
    debugPrint("TimeAnalyzer: Starting enhanced time analysis");

    // Filter out system messages
    final realMessages = chat.messages
        .where((msg) =>
            msg.senderId != "System" &&
            !msg.content.toLowerCase().contains('created group') &&
            !msg.content.toLowerCase().contains('added') &&
            !msg.content.toLowerCase().contains('left'))
        .toList();

    if (realMessages.isEmpty) {
      debugPrint("TimeAnalyzer: No real messages found");
      return {'timeAnalysis': {}};
    }

    debugPrint("TimeAnalyzer: Analyzing ${realMessages.length} messages");

    try {
      // Generate all analytics
      final hourlyActivity = _analyzeHourlyActivity(realMessages);
      final weeklyActivity = _analyzeWeeklyActivity(realMessages);
      final monthlyActivity = _analyzeMonthlyActivity(realMessages);
      final topConversationDays = _analyzeTopConversationDays(realMessages);
      final recentActivity = _analyzeRecentActivity(realMessages);
      final peakTimes = _analyzePeakTimes(realMessages);

      debugPrint("TimeAnalyzer: Analysis complete");

      return {
        'timeAnalysis': {
          'hourlyActivity': hourlyActivity,
          'weeklyActivity': weeklyActivity,
          'monthlyActivity': monthlyActivity,
          'topConversationDays': topConversationDays,
          'recentActivity': recentActivity,
          'peakHour': peakTimes['peakHour'],
          'peakDay': peakTimes['peakDay'],
          'totalMessages': realMessages.length,
          'dateRange': {
            'start': realMessages.first.timestamp.toIso8601String(),
            'end': realMessages.last.timestamp.toIso8601String(),
          },
        }
      };
    } catch (e, stackTrace) {
      debugPrint("TimeAnalyzer: Error - $e");
      debugPrint("Stack trace: $stackTrace");
      return {'timeAnalysis': {}};
    }
  }

  // ⏰ HOURLY ACTIVITY ANALYSIS - 24-hour breakdown
  Map<String, int> _analyzeHourlyActivity(List<MessageEntity> messages) {
    final Map<String, int> hourlyActivity = {};
    
    // Initialize all hours
    for (int hour = 0; hour < 24; hour++) {
      hourlyActivity[hour.toString().padLeft(2, '0')] = 0;
    }
    
    // Count messages per hour
    for (final message in messages) {
      final hour = message.timestamp.hour.toString().padLeft(2, '0');
      hourlyActivity[hour] = (hourlyActivity[hour] ?? 0) + 1;
    }
    
    debugPrint("TimeAnalyzer: Hourly activity calculated for 24 hours");
    return hourlyActivity;
  }

  // 📅 WEEKLY ACTIVITY ANALYSIS - Days of week
  List<Map<String, dynamic>> _analyzeWeeklyActivity(List<MessageEntity> messages) {
    final Map<int, int> weeklyActivity = {};
    
    // Initialize all days (1=Monday, 7=Sunday)
    for (int day = 1; day <= 7; day++) {
      weeklyActivity[day] = 0;
    }
    
    // Count messages per day of week
    for (final message in messages) {
      final dayOfWeek = message.timestamp.weekday; // 1=Monday, 7=Sunday
      weeklyActivity[dayOfWeek] = (weeklyActivity[dayOfWeek] ?? 0) + 1;
    }
    
    // Convert to list format
    final List<Map<String, dynamic>> result = [];
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    for (int day = 1; day <= 7; day++) {
      result.add({
        'day': day,
        'dayName': dayNames[day - 1],
        'messages': weeklyActivity[day] ?? 0,
        'count': weeklyActivity[day] ?? 0,
      });
    }
    
    debugPrint("TimeAnalyzer: Weekly activity calculated for 7 days");
    return result;
  }

  // 📆 MONTHLY ACTIVITY ANALYSIS - Last 12 months
  List<Map<String, dynamic>> _analyzeMonthlyActivity(List<MessageEntity> messages) {
    final Map<String, int> monthlyActivity = {};
    
    // Count messages per month
    for (final message in messages) {
      final monthKey = '${message.timestamp.year}-${message.timestamp.month.toString().padLeft(2, '0')}';
      monthlyActivity[monthKey] = (monthlyActivity[monthKey] ?? 0) + 1;
    }
    
    // Convert to list and sort by month
    final List<Map<String, dynamic>> result = [];
    final sortedMonths = monthlyActivity.keys.toList()..sort();
    
    // Take last 12 months
    final last12Months = sortedMonths.take(12).toList();
    
    for (final month in last12Months) {
      result.add({
        'month': month,
        'messages': monthlyActivity[month] ?? 0,
        'count': monthlyActivity[month] ?? 0,
      });
    }
    
    debugPrint("TimeAnalyzer: Monthly activity calculated for ${result.length} months");
    return result;
  }

  // 🗓️ TOP CONVERSATION DAYS ANALYSIS - Most active days
  List<Map<String, dynamic>> _analyzeTopConversationDays(List<MessageEntity> messages) {
    final Map<String, int> dailyActivity = {};
    
    // Count messages per day
    for (final message in messages) {
      final dayKey = '${message.timestamp.day.toString().padLeft(2, '0')}/${message.timestamp.month.toString().padLeft(2, '0')}/${message.timestamp.year}';
      dailyActivity[dayKey] = (dailyActivity[dayKey] ?? 0) + 1;
    }
    
    // Convert to list and sort by count (descending)
    final List<Map<String, dynamic>> result = [];
    
    for (final entry in dailyActivity.entries) {
      result.add({
        'date': entry.key,
        'count': entry.value,
      });
    }
    
    // Sort by count (highest first)
    result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    // Take top 10
    final top10 = result.take(10).toList();
    
    debugPrint("TimeAnalyzer: Top conversation days calculated - ${top10.length} days");
    return top10;
  }

  // 📈 RECENT ACTIVITY ANALYSIS - Last 14 days
  List<Map<String, dynamic>> _analyzeRecentActivity(List<MessageEntity> messages) {
    final Map<String, int> recentActivity = {};
    
    // Get last 14 days of messages
    final now = DateTime.now();
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));
    
    final recentMessages = messages.where((msg) => 
        msg.timestamp.isAfter(fourteenDaysAgo)).toList();
    
    // Count messages per day in last 14 days
    for (final message in recentMessages) {
      final dayKey = '${message.timestamp.day.toString().padLeft(2, '0')}/${message.timestamp.month.toString().padLeft(2, '0')}/${message.timestamp.year}';
      recentActivity[dayKey] = (recentActivity[dayKey] ?? 0) + 1;
    }
    
    // Convert to list and sort by date (newest first)
    final List<Map<String, dynamic>> result = [];
    
    for (final entry in recentActivity.entries) {
      result.add({
        'date': entry.key,
        'count': entry.value,
      });
    }
    
    // Sort by date (newest first)
    result.sort((a, b) {
      try {
        final aDate = _parseDate(a['date'] as String);
        final bDate = _parseDate(b['date'] as String);
        return bDate.compareTo(aDate);
      } catch (e) {
        return 0;
      }
    });
    
    debugPrint("TimeAnalyzer: Recent activity calculated for ${result.length} days");
    return result;
  }

  // 🎯 PEAK TIMES ANALYSIS
  Map<String, dynamic> _analyzePeakTimes(List<MessageEntity> messages) {
    final Map<int, int> hourlyCount = {};
    final Map<int, int> weeklyCount = {};
    
    // Count messages per hour and day
    for (final message in messages) {
      final hour = message.timestamp.hour;
      final dayOfWeek = message.timestamp.weekday;
      
      hourlyCount[hour] = (hourlyCount[hour] ?? 0) + 1;
      weeklyCount[dayOfWeek] = (weeklyCount[dayOfWeek] ?? 0) + 1;
    }
    
    // Find peak hour
    final peakHourEntry = hourlyCount.entries.reduce((a, b) => 
        a.value > b.value ? a : b);
    
    // Find peak day
    final peakDayEntry = weeklyCount.entries.reduce((a, b) => 
        a.value > b.value ? a : b);
    
    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return {
      'peakHour': {
        'hour': peakHourEntry.key,
        'timeRange': '${peakHourEntry.key.toString().padLeft(2, '0')}:00-${(peakHourEntry.key + 1).toString().padLeft(2, '0')}:00',
        'count': peakHourEntry.value,
      },
      'peakDay': {
        'day': peakDayEntry.key,
        'dayName': dayNames[peakDayEntry.key],
        'count': peakDayEntry.value,
      },
    };
  }

  // Helper method to parse date string
  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateStr - $e');
    }
    return DateTime.now();
  }
}