import 'package:flutter/material.dart';

/// Activity overview cards section for overview tab.
class ActivityOverviewSection extends StatelessWidget {
  final Map<String, dynamic> timeAnalysis;

  const ActivityOverviewSection({
    Key? key,
    required this.timeAnalysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint("Activity section building with keys: ${timeAnalysis.keys.join(', ')}");

    if (timeAnalysis.isEmpty) {
      return _buildNoTimeDataCard(context);
    }

    final peakHour = _convertToStringMap(timeAnalysis['peakHour']) ?? {};
    final peakDay = _convertToStringMap(timeAnalysis['peakDay']) ?? {};
    final peakDate = _convertToStringMap(timeAnalysis['peakDate']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Activity Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                // First row - Peak Hour and Peak Day
                Row(
                  children: [
                    Expanded(
                      child: _buildActivityCard(
                        context,
                        'Peak Hour',
                        _formatPeakHour(peakHour),
                        '${peakHour['count'] ?? 0} messages',
                        Icons.access_time,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActivityCard(
                        context,
                        'Peak Day',
                        _formatPeakDay(peakDay),
                        '${peakDay['count'] ?? 0} messages',
                        Icons.calendar_today,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Second row
                Row(
                  children: [
                    Expanded(
                      child: peakDate != null
                          ? _buildActivityCard(
                              context,
                              'Most Active Date',
                              _formatPeakDate(peakDate),
                              '${peakDate['count'] ?? 0} messages',
                              Icons.event,
                              Colors.purple,
                            )
                          : _buildActivityCard(
                              context,
                              'Activity Span',
                              _getActivitySpan(timeAnalysis),
                              'Total analyzed',
                              Icons.timeline,
                              Colors.orange,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActivityCard(
                        context,
                        'Total Messages',
                        (timeAnalysis['totalMessages'] ?? 0).toString(),
                        'Analyzed',
                        Icons.message,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTimeDataCard(BuildContext context) {
    return Card(
      color: Colors.grey.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.schedule,
              size: 48,
              color: Colors.blue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Activity Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time analysis data will appear here after processing more chat messages.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String title,
    String mainValue,
    String subValue,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mainValue,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatPeakHour(Map<String, dynamic> peakHour) {
    if (peakHour.isEmpty) return 'Not Available';

    final timeRange = peakHour['timeRange'] as String?;
    final hour = peakHour['hour'] as int?;

    if (timeRange != null && timeRange.isNotEmpty) {
      return timeRange;
    }

    if (hour != null) {
      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final nextHour = hour + 1;
      final nextDisplayHour = nextHour == 24 ? 0 : nextHour;
      final nextPeriod = nextDisplayHour < 12 ? 'AM' : 'PM';
      final nextDisplay = nextDisplayHour == 0 ? 12 : (nextDisplayHour > 12 ? nextDisplayHour - 12 : nextDisplayHour);

      return '$displayHour $period - $nextDisplay $nextPeriod';
    }

    return 'Not Available';
  }

  String _formatPeakDay(Map<String, dynamic> peakDay) {
    if (peakDay.isEmpty) return 'Not Available';

    final dayName = peakDay['dayName'] as String?;
    if (dayName != null && dayName.isNotEmpty) {
      return dayName;
    }

    final day = peakDay['day'] as int?;
    if (day != null) {
      const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      if (day >= 1 && day <= 7) {
        return dayNames[(day - 1) % 7];
      } else if (day >= 0 && day <= 6) {
        return dayNames[day];
      }
    }

    return 'Not Available';
  }

  String _formatPeakDate(Map<String, dynamic> peakDate) {
    if (peakDate.isEmpty) return 'Not Available';

    final date = peakDate['date'] as String?;
    if (date != null && date.isNotEmpty) {
      return date;
    }

    return 'Not Available';
  }

  String _getActivitySpan(Map<String, dynamic> timeAnalysis) {
    if (timeAnalysis.containsKey('dateRange')) {
      final dateRange = timeAnalysis['dateRange'];
      if (dateRange is Map) {
        final start = dateRange['start'] as String?;
        final end = dateRange['end'] as String?;

        if (start != null && end != null) {
          try {
            final startDate = DateTime.parse(start);
            final endDate = DateTime.parse(end);
            final difference = endDate.difference(startDate).inDays;

            if (difference > 365) {
              return '${(difference / 365).toStringAsFixed(1)} years';
            } else if (difference > 30) {
              return '${(difference / 30).toStringAsFixed(1)} months';
            } else {
              return '$difference days';
            }
          } catch (e) {
            debugPrint('Error parsing date range: $e');
          }
        }
      }
    }

    return '1+ Month';
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
