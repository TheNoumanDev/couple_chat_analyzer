import 'package:flutter/material.dart';
import '../../widgets/chart_constants.dart';
import 'missing_data_card.dart';

/// Monthly activity chart section widget.
class MonthlyActivitySection extends StatelessWidget {
  final dynamic monthlyData;

  const MonthlyActivitySection({
    Key? key,
    required this.monthlyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> monthList = _processMonthlyData();

    if (monthList.isEmpty) {
      return const MissingDataCard(
        title: 'Monthly Communication Trends',
        message: 'No monthly data available yet.',
        icon: Icons.calendar_month,
        color: Colors.indigo,
      );
    }

    // Sort by month (newest first) and take last 6 months for display
    monthList.sort((a, b) {
      final aMonth = a['month'] as String? ?? '';
      final bMonth = b['month'] as String? ?? '';
      return bMonth.compareTo(aMonth);
    });

    final displayMonths = monthList.take(ChartConstants.maxTopUsers).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Monthly Communication Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Last ${displayMonths.length} months of activity',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            _buildMonthlyBars(context, displayMonths),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _processMonthlyData() {
    List<Map<String, dynamic>> monthList = [];

    if (monthlyData is List) {
      for (final monthEntry in monthlyData) {
        if (monthEntry is Map<String, dynamic>) {
          monthList.add(monthEntry);
        }
      }
    } else if (monthlyData is Map) {
      final convertedData = _convertToStringMap(monthlyData);
      if (convertedData != null) {
        convertedData.forEach((key, value) {
          if (value is int) {
            monthList.add({
              'month': key,
              'count': value,
              'messages': value,
            });
          }
        });
      }
    }

    return monthList;
  }

  Widget _buildMonthlyBars(BuildContext context, List<Map<String, dynamic>> monthlyData) {
    if (monthlyData.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No monthly data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final maxCount = monthlyData
        .map((m) => m['count'] as int? ?? m['messages'] as int? ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: monthlyData.map((monthData) {
        final month = monthData['month'] as String? ?? 'Unknown';
        final count = monthData['count'] as int? ?? monthData['messages'] as int? ?? 0;
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        final displayMonth = _formatMonthDisplay(month);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  displayMonth,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(10),
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
                    color: Colors.indigo,
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

  String _formatMonthDisplay(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length >= 2) {
        final year = parts[0];
        final monthNum = int.parse(parts[1]);
        const monthNames = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];

        if (monthNum >= 1 && monthNum <= 12) {
          return '${monthNames[monthNum]} $year';
        }
      }
    } catch (e) {
      // Return original on error
    }
    return monthKey;
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
