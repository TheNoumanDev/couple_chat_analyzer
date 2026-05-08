import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'chart_constants.dart';

class TopUsersChart extends StatelessWidget {
  final List<dynamic> data;

  const TopUsersChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final validUsers = data.take(ChartConstants.maxTopUsers).where((user) {
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
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    // Use asMap().entries to avoid O(n²) indexOf calls
    return validUsers.asMap().entries.map((entry) {
      final index = entry.key;
      final userData = entry.value as Map<String, dynamic>;
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
    const colors = [
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
      // Use asMap().entries to avoid O(n²) indexOf calls
      children: validUsers.asMap().entries.map((entry) {
        final index = entry.key;
        final userData = entry.value as Map<String, dynamic>;
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
            }).toList(),
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
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getDayColor(int dayIndex) {
    final colors = [
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

class MonthlyActivityChart extends StatelessWidget {
  final List<dynamic> data;

  const MonthlyActivityChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get last 12 months of data
    final List<Map<String, dynamic>> monthlyData = [];
    
    if (data.isNotEmpty) {
      // Sort by month and take last 12
      final sortedData = List<dynamic>.from(data);
      sortedData.sort((a, b) {
        final aMonth = (a as Map<String, dynamic>)['month'] as String? ?? '';
        final bMonth = (b as Map<String, dynamic>)['month'] as String? ?? '';
        return aMonth.compareTo(bMonth);
      });
      
      final last12 = sortedData.take(ChartConstants.maxMonthsDisplayed).toList();
      
      for (final monthData in last12) {
        final month = (monthData as Map<String, dynamic>)['month'] as String? ?? '';
        final count = monthData['messages'] as int? ?? monthData['count'] as int? ?? 0;
        
        monthlyData.add({
          'month': month,
          'monthLabel': _formatMonth(month),
          'count': count,
        });
      }
    }
    
    final maxCount = monthlyData.isEmpty ? 1 : 
        monthlyData.map((m) => m['count'] as int).reduce((a, b) => a > b ? a : b);
    
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
              'Monthly Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Messages per month (last ${monthlyData.length} months)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            
            if (monthlyData.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No monthly data available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Horizontal bars for each month
              ...monthlyData.map((monthData) {
                final monthLabel = monthData['monthLabel'] as String;
                final count = monthData['count'] as int;
                final percentage = maxCount > 0 ? count / maxCount : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Month label
                      SizedBox(
                        width: 80,
                        child: Text(
                          monthLabel,
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
                                      color: Colors.teal,
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
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMonth(String monthStr) {
    try {
      if (monthStr.contains('-') && monthStr.length >= 7) {
        // Format: YYYY-MM
        final parts = monthStr.split('-');
        if (parts.length >= 2) {
          final year = parts[0];
          final month = int.parse(parts[1]);
          const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${monthNames[month]} $year';
        }
      }
    } catch (e) {
      debugPrint('Error formatting month: $monthStr - $e');
    }
    return monthStr;
  }
}

class TopConversationDaysChart extends StatelessWidget {
  final List<dynamic> data;

  const TopConversationDaysChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Take top days
    final topDays = data.take(ChartConstants.maxTopItems).toList();
    
    final maxCount = topDays.isEmpty ? 1 : 
        topDays.map((d) => (d as Map<String, dynamic>)['count'] as int? ?? 0)
               .reduce((a, b) => a > b ? a : b);
    
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
              'Top Conversation Days',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Days with the most messages',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            
            if (topDays.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No daily data available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Horizontal bars for top days
              ...topDays.asMap().entries.map((entry) {
                final index = entry.key;
                final dayData = entry.value as Map<String, dynamic>;
                final date = dayData['date'] as String? ?? 'Unknown';
                final count = dayData['count'] as int? ?? 0;
                final percentage = maxCount > 0 ? count / maxCount : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Rank
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _getRankColor(index),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Date
                      SizedBox(
                        width: 100,
                        child: Text(
                          _formatDate(date),
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
                                      color: _getRankColor(index).withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$count messages',
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
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    final colors = [
      const Color(0xFFFFD700), // Gold - 1st
      const Color(0xFFC0C0C0), // Silver - 2nd  
      const Color(0xFFCD7F32), // Bronze - 3rd
      Colors.blue,              // 4th+
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[rank % colors.length];
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.contains('/')) {
        // Handle DD/MM/YYYY or MM/DD/YYYY format
        final parts = dateStr.split('/');
        if (parts.length >= 3) {
          return '${parts[1]}/${parts[0]}'; // MM/DD
        }
      } else if (dateStr.contains('-')) {
        // Handle YYYY-MM-DD format
        final parts = dateStr.split('-');
        if (parts.length >= 3) {
          return '${parts[2]}/${parts[1]}'; // DD/MM
        }
      }
    } catch (e) {
      debugPrint('Error formatting date: $dateStr - $e');
    }
    return dateStr;
  }
}

// 📈 RECENT ACTIVITY CHART - Last 7-14 days
class RecentActivityChart extends StatelessWidget {
  final List<dynamic> data;

  const RecentActivityChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort by date and get recent data
    final sortedData = List<dynamic>.from(data);
    sortedData.sort((a, b) {
      final aDate = (a as Map<String, dynamic>)['date'] as String? ?? '';
      final bDate = (b as Map<String, dynamic>)['date'] as String? ?? '';
      return bDate.compareTo(aDate); // Reverse order for recent first
    });
    
    final recentData = sortedData.take(ChartConstants.maxRecentDays).toList();
    
    final maxCount = recentData.isEmpty ? 1 : 
        recentData.map((d) => (d as Map<String, dynamic>)['count'] as int? ?? 0)
                  .reduce((a, b) => a > b ? a : b);
    
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
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Messages in the last ${recentData.length} days',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            
            if (recentData.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No recent activity data available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Horizontal bars for recent days
              ...recentData.map((dayData) {
                final dayDataMap = dayData as Map<String, dynamic>;
                final date = dayDataMap['date'] as String? ?? 'Unknown';
                final count = dayDataMap['count'] as int? ?? 0;
                final percentage = maxCount > 0 ? count / maxCount : 0.0;
                final dayOfWeek = _getDayOfWeek(date);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      // Date and day
                      SizedBox(
                        width: 90,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(date),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              dayOfWeek,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Horizontal bar
                      Expanded(
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            children: [
                              if (percentage > 0)
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: percentage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getActivityColor(count, maxCount),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
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
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(int count, int maxCount) {
    final ratio = count / maxCount;
    if (ratio > 0.8) return Colors.green;
    if (ratio > 0.6) return Colors.blue;
    if (ratio > 0.4) return Colors.orange;
    if (ratio > 0.2) return Colors.yellow;
    return Colors.grey;
  }

  String _getDayOfWeek(String dateStr) {
    try {
      DateTime? date;
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length >= 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          date = DateTime(year, month, day);
        }
      } else if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length >= 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          date = DateTime(year, month, day);
        }
      }
      
      if (date != null) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateStr - $e');
    }
    return '';
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length >= 3) {
          return '${parts[0]}/${parts[1]}'; // DD/MM
        }
      } else if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length >= 3) {
          return '${parts[2]}/${parts[1]}'; // DD/MM
        }
      }
    } catch (e) {
      debugPrint('Error formatting date: $dateStr - $e');
    }
    return dateStr;
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
    debugPrint("😀 TopEmojisChart: Building with ${data.length} emoji entries");
    
    // Ensure we have valid data
    if (data.isEmpty) {
      return _buildNoDataCard(context);
    }

    // Convert and validate the data
    final validEmojis = <Map<String, dynamic>>[];
    for (final item in data) {
      if (item is Map<String, dynamic> && 
          item.containsKey('emoji') && 
          item.containsKey('count')) {
        validEmojis.add(item);
      } else {
        debugPrint("⚠️ TopEmojisChart: Invalid emoji data item: $item");
      }
    }

    if (validEmojis.isEmpty) {
      return _buildNoDataCard(context);
    }

    // Sort by count (descending) and take top emojis
    validEmojis.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    final topEmojis = validEmojis.take(ChartConstants.maxTopItems).toList();

    // Get the maximum count for scaling the bars
    final maxCount = topEmojis.isNotEmpty ? (topEmojis.first['count'] as int) : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_emotions, color: Colors.yellow),
                const SizedBox(width: 8),
                Text(
                  'Top Emojis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${topEmojis.length} emojis',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topEmojis.asMap().entries.map((entry) {
              final index = entry.key;
              final emoji = entry.value;
              return _buildEmojiBar(
                context, 
                emoji['emoji'] as String,
                emoji['count'] as int,
                maxCount,
                index,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiBar(
    BuildContext context,
    String emoji,
    int count,
    int maxCount,
    int index,
  ) {
    // Calculate the width percentage (0.0 to 1.0)
    final widthPercent = maxCount > 0 ? count / maxCount : 0.0;
    
    // Color gradient for different positions
    final colors = [
      Colors.yellow,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];
    final color = colors[index % colors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Emoji display
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Progress bar and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      emoji,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress bar
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthPercent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard(BuildContext context) {
    return Card(
      color: Colors.grey.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.emoji_emotions,
              size: 48,
              color: Colors.yellow.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Top Emojis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No emoji data available yet. Import more chat data to see emoji usage patterns.',
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
            ...data.take(ChartConstants.maxTopDomains).map((domain) {
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
    final short = data['short'] as int? ?? 0;
    final medium = data['medium'] as int? ?? 0;
    final long = data['long'] as int? ?? 0;
    final total = short + medium + long;

    if (total == 0) {
      return _buildNoDataCard(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Message Length Distribution',
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
                  child: _buildLengthCard(
                    context,
                    'Short',
                    short,
                    total,
                    Colors.green,
                    Icons.remove,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLengthCard(
                    context,
                    'Medium',
                    medium,
                    total,
                    Colors.orange,
                    Icons.text_fields,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLengthCard(
                    context,
                    'Long',
                    long,
                    total,
                    Colors.red,
                    Icons.subject,
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
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard(BuildContext context) {
    return Card(
      color: Colors.grey.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.green.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Message Length Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Message length analysis will appear here after processing more chat data.',
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
}

class TimeActivityOverview extends StatelessWidget {
  final Map<String, dynamic> timeData;

  const TimeActivityOverview({
    Key? key,
    required this.timeData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    context,
                    'Peak Hour',
                    _getPeakHour(),
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeCard(
                    context,
                    'Most Active Day',
                    _getMostActiveDay(),
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
                  child: _buildTimeCard(
                    context,
                    'Total Days',
                    _getTotalDays(),
                    Icons.date_range,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeCard(
                    context,
                    'Activity Span',
                    _getActivitySpan(),
                    Icons.timeline,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(
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
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getPeakHour() {
    if (timeData.containsKey('peakHour')) {
      final peakHour = timeData['peakHour'];
      if (peakHour is Map && peakHour.containsKey('timeRange')) {
        return peakHour['timeRange'].toString();
      }
      return peakHour.toString();
    }
    return '10:00 AM';
  }

  String _getMostActiveDay() {
    if (timeData.containsKey('mostActiveDay')) {
      return timeData['mostActiveDay'].toString();
    }
    if (timeData.containsKey('peakDay')) {
      return timeData['peakDay'].toString();
    }
    return 'Monday';
  }

  String _getTotalDays() {
    if (timeData.containsKey('totalDays')) {
      return timeData['totalDays'].toString();
    }
    if (timeData.containsKey('dayCount')) {
      return timeData['dayCount'].toString();
    }
    return '30+';
  }

  String _getActivitySpan() {
    if (timeData.containsKey('activitySpan')) {
      return timeData['activitySpan'].toString();
    }
    if (timeData.containsKey('dateRange')) {
      return timeData['dateRange'].toString();
    }
    return '1 Month';
  }
}
