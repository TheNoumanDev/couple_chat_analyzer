import 'package:flutter/material.dart';
import 'missing_data_card.dart';

/// Peak activity times section widget.
class PeakActivitySection extends StatelessWidget {
  final Map<String, dynamic> timeAnalysis;

  const PeakActivitySection({
    Key? key,
    required this.timeAnalysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (timeAnalysis.isEmpty) {
      return const MissingDataCard(
        title: 'Peak Activity Times',
        message: 'Activity patterns will appear here after analyzing more chat data.',
        icon: Icons.trending_up,
        color: Colors.blue,
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
                const Icon(Icons.trending_up, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Peak Activity Times',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPeakCard(
                    context,
                    'Peak Hour',
                    _extractPeakHourDisplay(),
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPeakCard(
                    context,
                    'Peak Day',
                    _extractPeakDayDisplay(),
                    Icons.calendar_today,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPeakCard(
                    context,
                    'Most Active Period',
                    _extractActivePeriod(),
                    Icons.schedule,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPeakCard(
                    context,
                    'Total Messages',
                    (timeAnalysis['totalMessages'] ?? 0).toString(),
                    Icons.message,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _extractPeakDayDisplay() {
    if (timeAnalysis.containsKey('peakDay')) {
      final peakDay = _convertToStringMap(timeAnalysis['peakDay']);
      if (peakDay != null) {
        final dayName = peakDay['dayName'] as String?;
        final count = peakDay['count'] as int? ?? 0;

        if (dayName != null && dayName.isNotEmpty) {
          return "$dayName\n($count msgs)";
        }
      }
    }
    return 'Not Available';
  }

  String _extractPeakHourDisplay() {
    if (timeAnalysis.containsKey('peakHour')) {
      final peakHour = _convertToStringMap(timeAnalysis['peakHour']);
      if (peakHour != null) {
        final timeRange = peakHour['timeRange'] as String?;
        final hour = peakHour['hour'] as int?;
        final count = peakHour['count'] as int? ?? 0;

        if (timeRange != null && timeRange.isNotEmpty) {
          return "$timeRange\n($count msgs)";
        }

        if (hour != null) {
          final period = hour < 12 ? 'AM' : 'PM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return "$displayHour $period\n($count msgs)";
        }
      }
    }
    return 'Not Available';
  }

  String _extractActivePeriod() {
    if (timeAnalysis.containsKey('peakHour')) {
      final peakHour = _convertToStringMap(timeAnalysis['peakHour']);
      if (peakHour != null) {
        final hour = peakHour['hour'] as int?;
        if (hour != null) {
          if (hour >= 6 && hour < 12) {
            return 'Morning\nActive';
          } else if (hour >= 12 && hour < 18) {
            return 'Afternoon\nActive';
          } else if (hour >= 18 && hour < 22) {
            return 'Evening\nActive';
          } else {
            return 'Night\nActive';
          }
        }
      }
    }
    return 'All Day\nActive';
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
