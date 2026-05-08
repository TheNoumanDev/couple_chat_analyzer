import 'package:flutter/material.dart';

class WeeklyActivityChart extends StatelessWidget {
  final List<dynamic> data;

  const WeeklyActivityChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Convert data to proper format
    final List<Map<String, dynamic>> weeklyData = [];

    if (data.isEmpty) {
      // If no data, create empty structure
      for (int i = 0; i < 7; i++) {
        weeklyData.add({
          'dayName': dayNames[i],
          'dayShort': dayShort[i],
          'count': 0,
        });
      }
    } else {
      // Process existing data
      for (int i = 0; i < 7; i++) {
        final dayData = i < data.length ? data[i] as Map<String, dynamic>? : null;
        weeklyData.add({
          'dayName': dayNames[i],
          'dayShort': dayShort[i],
          'count': dayData?['messages'] as int? ?? dayData?['count'] as int? ?? 0,
        });
      }
    }

    final maxCount = weeklyData.isEmpty ? 1 :
        weeklyData.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b);

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
              'Weekly Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Messages per day of the week',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Horizontal bars for each day
            ...weeklyData.asMap().entries.map((entry) {
              final index = entry.key;
              final dayData = entry.value;
              final count = dayData['count'] as int;
              final dayShort = dayData['dayShort'] as String;
              final percentage = maxCount > 0 ? count / maxCount : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Day label
                    SizedBox(
                      width: 50,
                      child: Text(
                        dayShort,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Horizontal bar
                    Expanded(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            if (percentage > 0)
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getDayColor(index),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  count.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Color _getDayColor(int dayIndex) {
    const colors = [
      Colors.red,     // Monday
      Colors.orange,  // Tuesday
      Colors.yellow,  // Wednesday
      Colors.green,   // Thursday
      Colors.blue,    // Friday
      Colors.indigo,  // Saturday
      Colors.purple,  // Sunday
    ];
    return colors[dayIndex % colors.length];
  }
}
