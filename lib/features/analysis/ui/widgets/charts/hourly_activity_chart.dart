import 'package:flutter/material.dart';

class HourlyActivityChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const HourlyActivityChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert hourly data to list format
    final List<Map<String, dynamic>> hourlyList = [];

    for (int hour = 0; hour < 24; hour++) {
      final hourStr = hour.toString().padLeft(2, '0');
      final count = data[hourStr] as int? ?? data[hour.toString()] as int? ?? 0;
      hourlyList.add({
        'hour': hour,
        'hourLabel': '${hourStr}:00',
        'count': count,
      });
    }

    final maxCount = hourlyList.isEmpty ? 1 :
        hourlyList.map((h) => h['count'] as int).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hourly Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Messages sent throughout the day',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Horizontal bars for each hour
            ...hourlyList.map((hourData) {
              final hour = hourData['hour'] as int;
              final hourLabel = hourData['hourLabel'] as String;
              final count = hourData['count'] as int;
              final percentage = maxCount > 0 ? count / maxCount : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    // Hour label
                    SizedBox(
                      width: 50,
                      child: Text(
                        hourLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Horizontal bar
                    Expanded(
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            if (percentage > 0)
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getHourColor(hour),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            if (count > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    count.toString(),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: percentage > 0.3 ? Colors.white :
                                             Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getHourColor(int hour) {
    // Color coding based on time of day
    if (hour >= 6 && hour < 12) return Colors.orange; // Morning
    if (hour >= 12 && hour < 18) return Colors.blue;  // Afternoon
    if (hour >= 18 && hour < 22) return Colors.green; // Evening
    return Colors.purple; // Night
  }
}
