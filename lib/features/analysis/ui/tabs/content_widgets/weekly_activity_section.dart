import 'package:flutter/material.dart';
import 'missing_data_card.dart';

/// Weekly activity chart section widget.
class WeeklyActivitySection extends StatelessWidget {
  final dynamic weeklyData;

  const WeeklyActivitySection({
    Key? key,
    required this.weeklyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, int> dayData = _processDayData();

    if (dayData.isEmpty) {
      return const MissingDataCard(
        title: 'Daily Activity Pattern',
        message: 'Daily communication patterns will be shown here when more time analysis data is available.',
        icon: Icons.calendar_view_week,
        color: Colors.green,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_view_week, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Weekly Activity Pattern',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWeekdayBars(context, dayData),
          ],
        ),
      ),
    );
  }

  Map<String, int> _processDayData() {
    Map<String, int> dayData = {};

    if (weeklyData is List) {
      for (final dayEntry in weeklyData) {
        if (dayEntry is Map) {
          final dayName = dayEntry['dayName'] as String?;
          final count = dayEntry['count'] as int? ?? dayEntry['messages'] as int? ?? 0;
          if (dayName != null) {
            dayData[dayName] = count;
          }
        }
      }
    } else if (weeklyData is Map) {
      final convertedData = _convertToStringMap(weeklyData);
      if (convertedData != null) {
        convertedData.forEach((key, value) {
          if (value is int) {
            dayData[key] = value;
          }
        });
      }
    }

    return dayData;
  }

  Widget _buildWeekdayBars(BuildContext context, Map<String, int> dayData) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final maxCount = dayData.values.isNotEmpty
        ? dayData.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return Column(
      children: weekdays.map((day) {
        final count = dayData[day] ?? 0;
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  day.substring(0, 3),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 35,
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic>? _convertToStringMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
}
