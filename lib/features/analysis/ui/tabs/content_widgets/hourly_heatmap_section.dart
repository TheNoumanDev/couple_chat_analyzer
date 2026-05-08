import 'package:flutter/material.dart';
import 'missing_data_card.dart';

/// Hourly activity heatmap section widget.
class HourlyHeatmapSection extends StatelessWidget {
  final dynamic hourlyData;

  const HourlyHeatmapSection({
    Key? key,
    required this.hourlyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, int> hourMap = _processHourlyData();

    if (hourMap.isEmpty) {
      return const MissingDataCard(
        title: 'Hourly Activity Heatmap',
        message: '24-hour activity patterns will be visualized here when hourly data becomes available.',
        icon: Icons.grid_view,
        color: Colors.red,
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
                const Icon(Icons.grid_view, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  '24-Hour Activity Heatmap',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHourlyGrid(context, hourMap),
          ],
        ),
      ),
    );
  }

  Map<String, int> _processHourlyData() {
    Map<String, int> hourMap = {};

    if (hourlyData is Map) {
      final convertedData = _convertToStringMap(hourlyData);
      if (convertedData != null) {
        convertedData.forEach((key, value) {
          if (value is int) {
            hourMap[key] = value;
          }
        });
      }
    }

    return hourMap;
  }

  Widget _buildHourlyGrid(BuildContext context, Map<String, int> hourMap) {
    final maxCount = hourMap.values.isNotEmpty
        ? hourMap.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return SizedBox(
      height: 160,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 1.2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 24,
        itemBuilder: (context, index) {
          final hour = index;
          final hourKey = hour.toString().padLeft(2, '0');
          final count = hourMap[hourKey] ?? 0;
          final intensity = maxCount > 0 ? count / maxCount : 0.0;

          return Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: intensity * 0.8 + 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hourKey,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: intensity > 0.5 ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                if (count > 0)
                  Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: intensity > 0.5 ? Colors.white : Colors.red[700],
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
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
