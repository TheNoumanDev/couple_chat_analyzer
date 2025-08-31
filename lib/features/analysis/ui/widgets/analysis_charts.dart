import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TopUsersChart extends StatelessWidget {
  final List<dynamic> data;

  const TopUsersChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final validUsers = data.take(6).where((user) {
      final userData = user as Map<String, dynamic>;
      final percentage = userData['percentage'] as double? ?? 0.0;
      return percentage > 0;
    }).toList();

    if (validUsers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Top Contributors',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('No data available'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Contributors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(context, validUsers),
                        centerSpaceRadius: 35,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend
                Expanded(
                  flex: 1,
                  child: _buildLegend(context, validUsers),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(BuildContext context, List validUsers) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return validUsers.map((user) {
      final index = validUsers.indexOf(user);
      final userData = user as Map<String, dynamic>;
      final percentage = userData['percentage'] as double? ?? 0.0;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 45,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(BuildContext context, List validUsers) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: validUsers.map((user) {
        final index = validUsers.indexOf(user);
        final userData = user as Map<String, dynamic>;
        final name = userData['name'] as String? ?? 'Unknown';
        final messageCount = userData['messageCount'] as int? ?? 0;
        final percentage = userData['percentage'] as double? ?? 0.0;
        final color = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$messageCount msgs (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class HourlyActivityChart extends StatelessWidget {
  final List<dynamic> data;

  const HourlyActivityChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hourly Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildHourlySpots(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildHourlySpots() {
    return data.map((item) {
      final itemData = item as Map<String, dynamic>;
      final hour = (itemData['hour'] as int).toDouble();
      final messages = (itemData['messages'] as int).toDouble();
      return FlSpot(hour, messages);
    }).toList();
  }
}

class WeeklyActivityChart extends StatelessWidget {
  final List<dynamic> data;

  const WeeklyActivityChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final index = value.toInt() - 1;
                          if (index >= 0 && index < days.length) {
                            return Text(days[index]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: _buildWeeklyBars(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildWeeklyBars(BuildContext context) {
    return data.map((item) {
      final itemData = item as Map<String, dynamic>;
      final day = itemData['day'] as int;
      final messages = (itemData['messages'] as int).toDouble();
      
      return BarChartGroupData(
        x: day,
        barRods: [
          BarChartRodData(
            toY: messages,
            color: Theme.of(context).colorScheme.secondary,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }
}

class MonthlyActivityChart extends StatelessWidget {
  final List<dynamic> data;

  const MonthlyActivityChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            final month = data[index]['month'] as String;
                            return Text(month.substring(5)); // Show MM part of YYYY-MM
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildMonthlySpots(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.tertiary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildMonthlySpots() {
    return data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final itemData = entry.value as Map<String, dynamic>;
      final messages = (itemData['messages'] as int).toDouble();
      return FlSpot(index, messages);
    }).toList();
  }
}

class TopEmojisChart extends StatelessWidget {
  final List<dynamic> data;

  const TopEmojisChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Emojis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...data.take(10).map((emoji) {
              final emojiData = emoji as Map<String, dynamic>;
              final maxCount = data.isNotEmpty ? (data.first as Map<String, dynamic>)['count'] as int : 1;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      emojiData['emoji'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (emojiData['count'] as int) / maxCount,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${emojiData['count']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class TopDomainsChart extends StatelessWidget {
  final List<dynamic> data;

  const TopDomainsChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Shared Domains',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...data.take(5).map((domain) {
              final domainData = domain as Map<String, dynamic>;
              return ListTile(
                leading: Icon(
                  Icons.link,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(domainData['domain'] as String),
                trailing: Text(
                  '${domainData['count']}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class MessageLengthChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const MessageLengthChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message Length Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLengthCard(
                    context,
                    'Short',
                    data['short'] as int? ?? 0,
                    Icons.short_text,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLengthCard(
                    context,
                    'Medium',
                    data['medium'] as int? ?? 0,
                    Icons.text_fields,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLengthCard(
                    context,
                    'Long',
                    data['long'] as int? ?? 0,
                    Icons.notes,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLengthCard(
    BuildContext context,
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class TimeActivityOverview extends StatelessWidget {
  final Map<String, dynamic> timeData;

  const TimeActivityOverview({
    Key? key,
    required this.timeData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final peakHour = timeData['peakHour'] as Map<String, dynamic>? ?? {};
    final peakDay = timeData['peakDay'] as Map<String, dynamic>? ?? {};
    final peakDate = timeData['peakDate'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                // First row - Peak Hour and Peak Day
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeCard(
                        context,
                        'Peak Hour',
                        _formatPeakHour(peakHour),
                        '${peakHour['messages'] ?? 0} messages',
                        Icons.access_time,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeCard(
                        context,
                        'Peak Day',
                        _formatPeakDay(peakDay),
                        _formatPeakDayDetails(peakDay),
                        Icons.calendar_today,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Second row - Peak Date (most messages on specific date)
                Row(
                  children: [
                    Expanded(
                      child: peakDate != null
                          ? _buildTimeCard(
                              context,
                              'Most Active Date',
                              _formatPeakDate(peakDate),
                              _formatPeakDateDetails(peakDate),
                              Icons.event,
                              Colors.purple,
                            )
                          : _buildEmptyCard(context, 'Peak Date', 'No data available'),
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

  String _formatPeakHour(Map<String, dynamic> peakHour) {
    final timeRange = peakHour['timeRange'] as String? ?? '';
    final hour = peakHour['hour'] as int?;
    
    if (timeRange.isNotEmpty && hour != null) {
      // Convert 24-hour format to 12-hour format with AM/PM
      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final nextHour = hour + 1;
      final nextPeriod = nextHour < 12 ? 'AM' : 'PM';
      final nextDisplayHour = nextHour == 0 ? 12 : (nextHour > 12 ? nextHour - 12 : nextHour);
      
      return '$timeRange\n($displayHour-$nextDisplayHour $period)';
    }
    
    if (timeRange.isNotEmpty) return timeRange;
    if (hour != null) {
      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour $period';
    }
    
    return 'Unknown';
  }

  String _formatPeakDay(Map<String, dynamic> peakDay) {
    final dayName = peakDay['dayName'] as String?;
    if (dayName != null) return dayName;
    
    final day = peakDay['day'] as int?;
    if (day != null) {
      const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      if (day >= 1 && day <= 7) {
        return days[day - 1];
      }
    }
    
    return 'Unknown';
  }

  String _formatPeakDayDetails(Map<String, dynamic> peakDay) {
    final messages = peakDay['messages'] as int? ?? 0;
    return '$messages messages';
  }

  String _formatPeakDate(Map<String, dynamic> peakDate) {
    final formattedDate = peakDate['formattedDate'] as String?;
    if (formattedDate != null && formattedDate.isNotEmpty) {
      return formattedDate;
    }

    final date = peakDate['date'] as String?;
    if (date != null && date.isNotEmpty) {
      try {
        // Try to format YYYY-MM-DD to DD/MM/YYYY
        final parts = date.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
        return date;
      } catch (e) {
        return date;
      }
    }
    
    return 'N/A';
  }

  String _formatPeakDateDetails(Map<String, dynamic> peakDate) {
    final messages = peakDate['messages'] as int? ?? 0;
    final dayName = peakDate['dayName'] as String?;
    
    if (dayName != null && dayName.isNotEmpty) {
      return '$messages messages\n$dayName';
    }
    
    return '$messages messages';
  }

  Widget _buildTimeCard(
    BuildContext context,
    String title,
    String mainValue,
    String subValue,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (subtitle.isNotEmpty) ...[
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
          if (title.isEmpty && subtitle.isEmpty)
            const SizedBox(height: 60), // Match height of other cards
        ],
      ),
    );
  }
}