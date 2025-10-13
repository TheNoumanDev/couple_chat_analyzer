import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';
import '../widgets/analysis_charts.dart';

class OverviewTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const OverviewTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use safe conversion methods instead of direct casting
    final summary = _convertToStringMap(results['summary']) ?? {};
    final timeAnalysis = _extractTimeAnalysis(results);
    final messagesByUser = results['messagesByUser'] as List<dynamic>? ?? [];
    
    debugPrint("📊 OverviewTab: summary keys: ${summary.keys.join(', ')}");
    debugPrint("📊 OverviewTab: timeAnalysis keys: ${timeAnalysis.keys.join(', ')}");
    debugPrint("📊 OverviewTab: messagesByUser count: ${messagesByUser.length}");
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Summary Cards (keep existing)
          SummaryCards(summary: summary),
          
          const SizedBox(height: 24),
          
          // Key Metrics (redesigned as colorful boxes like summary)
          _buildKeyMetricsCards(context),
          
          const SizedBox(height: 24),
          
          // Activity Overview (redesigned layout)
          _buildActivityOverviewCards(context, timeAnalysis),
          
          const SizedBox(height: 24),
          
          // Conversation Health (enhanced)
          if (results.containsKey('conversationDynamics'))
            _buildEnhancedHealthCard(context, _convertToStringMap(results['conversationDynamics']) ?? {}),
          
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildKeyMetricsCards(BuildContext context) {
    final summary = _convertToStringMap(results['summary']) ?? {};
    final totalWords = _extractTotalWords(results);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Messages/Day',
                summary['avgMessagesPerDay']?.toString() ?? '0',
                Icons.message,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Media Files',
                summary['totalMedia']?.toString() ?? '0',
                Icons.image,
                Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Total Words',
                totalWords.toString(),
                Icons.text_fields,
                Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 120, // Fixed height like summary cards
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: color,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoTimeDataCard(BuildContext context) {
  return Card(
    color: Colors.grey.withOpacity(0.1),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 48,
            color: Colors.blue.withOpacity(0.5),
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

  /// FIXED: Overview Tab Time Data Extraction Methods
/// Replace these methods in overview_tab.dart

/// Enhanced Activity Overview Cards with correct data extraction
Widget _buildActivityOverviewCards(BuildContext context, Map<String, dynamic> timeAnalysis) {
  debugPrint("🕐 OverviewTab: Building activity cards with keys: ${timeAnalysis.keys.join(', ')}");
  
  if (timeAnalysis.isEmpty) {
    return _buildNoTimeDataCard(context);
  }

  // Extract peak hour and peak day with correct field names
  final peakHour = _convertToStringMap(timeAnalysis['peakHour']) ?? {};
  final peakDay = _convertToStringMap(timeAnalysis['peakDay']) ?? {};
  final peakDate = _convertToStringMap(timeAnalysis['peakDate']);

  debugPrint("🕐 Peak Hour data: $peakHour");
  debugPrint("🕐 Peak Day data: $peakDay");

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
                      '${peakHour['count'] ?? 0} messages', // FIXED: Use 'count' instead of 'messages'
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
                      '${peakDay['count'] ?? 0} messages', // FIXED: Use 'count' instead of 'messages'
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
                        ? _buildActivityCard(
                            context,
                            'Most Active Date',
                            _formatPeakDate(peakDate),
                            '${peakDate['count'] ?? 0} messages', // FIXED: Use 'count'
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

  Widget _buildEnhancedHealthCard(BuildContext context, Map<String, dynamic> conversationDynamics) {
    // Check for both possible field names
    int healthScore = 0;
    if (conversationDynamics.containsKey('healthScore')) {
      healthScore = _safeInt(conversationDynamics['healthScore']) ?? 0;
    } else if (conversationDynamics.containsKey('conversationHealthScore')) {
      healthScore = _safeInt(conversationDynamics['conversationHealthScore']) ?? 0;
    }

    if (healthScore == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Health',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      color: _getHealthColor(healthScore),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Overall Health Score',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getHealthColor(healthScore).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getHealthColor(healthScore).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$healthScore/100',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getHealthColor(healthScore),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: healthScore / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getHealthColor(healthScore),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Text(
                  _getHealthDescription(healthScore),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _buildHealthDetailsRow(context, conversationDynamics),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthDetailsRow(BuildContext context, Map<String, dynamic> conversationDynamics) {
    final totalConversations = _safeInt(conversationDynamics['totalConversations']) ?? 0;
    final avgLength = _safeInt(conversationDynamics['averageConversationLength']) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // First row - Peak Hour and Peak Day
        Row(
          children: [
            Expanded(
              child: _buildHealthDetail(
                context,
                'Conversations',
                totalConversations.toString(),
                Icons.chat_bubble_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHealthDetail(
                context,
                'Quality',
                _getQualityLabel(conversationDynamics),
                Icons.verified,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Second row - Peak Date (centered)
          Row(
            children: [
              Expanded(
                child: _buildHealthDetail(
                  context,
                  'Avg Length',
                  '${avgLength.toString()} msgs',
                  Icons.straighten,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildHealthDetail(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getQualityLabel(Map<String, dynamic> conversationDynamics) {
    final healthScore = _safeInt(conversationDynamics['conversationHealthScore']) ?? 0;
    if (healthScore >= 80) return 'Excellent';
    if (healthScore >= 60) return 'Good';
    if (healthScore >= 40) return 'Fair';
    return 'Needs Work';
  }

  // Peak hour formatting methods (same as before)
  String _formatPeakHour(Map<String, dynamic> peakHour) {
  if (peakHour.isEmpty) return 'Not Available';
  
  final timeRange = peakHour['timeRange'] as String?;
  final hour = peakHour['hour'] as int?;
  
  if (timeRange != null && timeRange.isNotEmpty) {
    return timeRange;
  }
  
  if (hour != null) {
    // Convert 24-hour format to 12-hour format
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
    // Handle both 0-based (Sunday=0) and 1-based (Monday=1) indexing
    if (day >= 1 && day <= 7) {
      return dayNames[(day - 1) % 7]; // Convert 1-based to 0-based
    } else if (day >= 0 && day <= 6) {
      return dayNames[day]; // Already 0-based
    }
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

/// Format peak date
String _formatPeakDate(Map<String, dynamic> peakDate) {
  if (peakDate.isEmpty) return 'Not Available';
  
  final date = peakDate['date'] as String?;
  if (date != null && date.isNotEmpty) {
    return date;
  }
  
  return 'Not Available';
}

  String _formatPeakDateDetails(Map<String, dynamic> peakDate) {
    final messages = peakDate['messages'] as int? ?? 0;
    final dayName = peakDate['dayName'] as String?;
    
    if (dayName != null && dayName.isNotEmpty) {
      return '$messages messages\n$dayName';
    }
    
    return '$messages messages';
  }

  Color _getHealthColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getHealthDescription(int score) {
    if (score >= 80) return 'Excellent communication flow with strong engagement patterns and balanced participation.';
    if (score >= 60) return 'Good conversation patterns with healthy interaction dynamics and room for growth.';
    if (score >= 40) return 'Moderate conversation health showing mixed patterns that could benefit from attention.';
    return 'Communication patterns suggest areas for improvement in engagement and interaction quality.';
  }

  /// Enhanced extraction of total words from multiple possible sources
  int _extractTotalWords(Map<String, dynamic> results) {
    // Check content analysis first
    final contentAnalysis = _extractContentAnalysis(results);
    if (contentAnalysis.containsKey('totalWords')) {
      final words = contentAnalysis['totalWords'];
      if (words is int) return words;
      if (words is String) return int.tryParse(words) ?? 0;
    }
    
    // Check user analysis and sum up word counts
    final userAnalysis = _extractUserAnalysis(results);
    if (userAnalysis.containsKey('userData')) {
      final userData = userAnalysis['userData'] as List?;
      if (userData != null) {
        int totalWords = 0;
        for (final user in userData) {
          if (user is Map<String, dynamic>) {
            final wordCount = user['wordCount'];
            if (wordCount is int) {
              totalWords += wordCount;
            } else if (wordCount is String) {
              totalWords += int.tryParse(wordCount) ?? 0;
            }
          }
        }
        if (totalWords > 0) return totalWords;
      }
    }
    
    // Check messagesByUser for word counts
    final messagesByUser = results['messagesByUser'] as List<dynamic>? ?? [];
    int totalWords = 0;
    for (final user in messagesByUser) {
      if (user is Map<String, dynamic>) {
        final wordCount = user['wordCount'];
        if (wordCount is int) {
          totalWords += wordCount;
        } else if (wordCount is String) {
          totalWords += int.tryParse(wordCount) ?? 0;
        }
      }
    }
    
    return totalWords;
  }

  /// Extract timeAnalysis data - it might be nested
  Map<String, dynamic> _extractTimeAnalysis(Map<String, dynamic> results) {
  debugPrint("🕐 OverviewTab: Extracting time analysis from keys: ${results.keys.join(', ')}");
  
  // PRIORITY 1: Check direct timeAnalysis key
  if (results.containsKey('timeAnalysis')) {
    final timeData = _convertToStringMap(results['timeAnalysis']);
    if (timeData != null && timeData.isNotEmpty) {
      debugPrint("✅ Found timeAnalysis directly");
      return timeData;
    }
  }
  
  // PRIORITY 2: Check nested in time container
  if (results.containsKey('time')) {
    final timeContainer = _convertToStringMap(results['time']);
    if (timeContainer != null && timeContainer.containsKey('timeAnalysis')) {
      final timeData = _convertToStringMap(timeContainer['timeAnalysis']);
      if (timeData != null && timeData.isNotEmpty) {
        debugPrint("✅ Found timeAnalysis nested in time container");
        return timeData;
      }
    }
    
    // OR if the time container itself contains the data directly
    if (timeContainer != null && (timeContainer.containsKey('peakHour') || timeContainer.containsKey('peakDay'))) {
      debugPrint("✅ Found time data directly in time container");
      return timeContainer;
    }
  }
  
  // PRIORITY 3: Check for individual time fields at root level
  final directTimeFields = <String, dynamic>{};
  for (final key in results.keys) {
    if (key == 'peakHour' || key == 'peakDay' || key == 'totalMessages' || 
        key.contains('hourly') || key.contains('weekly') || key.contains('monthly') ||
        key.contains('peak') || key.contains('activity')) {
      directTimeFields[key] = results[key];
    }
  }
  
  if (directTimeFields.isNotEmpty) {
    debugPrint("✅ Found direct time fields at root: ${directTimeFields.keys.join(', ')}");
    return directTimeFields;
  }
  
  debugPrint("❌ No timeAnalysis data found");
  return {};
}

  /// Extract contentAnalysis data - it might be nested
  Map<String, dynamic> _extractContentAnalysis(Map<String, dynamic> results) {
    if (results.containsKey('contentAnalysis')) {
      final contentData = _convertToStringMap(results['contentAnalysis']);
      if (contentData != null && contentData.isNotEmpty) {
        return contentData;
      }
    }
    
    if (results.containsKey('content')) {
      final contentContainer = _convertToStringMap(results['content']);
      if (contentContainer != null) {
        if (contentContainer.containsKey('data')) {
          final dataContainer = _convertToStringMap(contentContainer['data']);
          if (dataContainer != null && dataContainer.isNotEmpty) {
            return dataContainer;
          }
        }
        if (contentContainer.containsKey('contentAnalysis')) {
          final contentData = _convertToStringMap(contentContainer['contentAnalysis']);
          if (contentData != null && contentData.isNotEmpty) {
            return contentData;
          }
        }
        if (contentContainer.isNotEmpty) {
          return contentContainer;
        }
      }
    }
    
    final directContentFields = <String, dynamic>{};
    for (final key in results.keys) {
      if (key.contains('total') && (key.contains('Words') || key.contains('Emojis') || key.contains('Media'))) {
        directContentFields[key] = results[key];
      }
    }
    
    return directContentFields;
  }

  /// Extract userAnalysis data - it might be nested
  Map<String, dynamic> _extractUserAnalysis(Map<String, dynamic> results) {
    if (results.containsKey('userAnalysis')) {
      final userData = _convertToStringMap(results['userAnalysis']);
      if (userData != null && userData.isNotEmpty) {
        return userData;
      }
    }
    
    if (results.containsKey('users')) {
      final usersContainer = _convertToStringMap(results['users']);
      if (usersContainer != null && usersContainer.containsKey('userAnalysis')) {
        final userData = _convertToStringMap(usersContainer['userAnalysis']);
        if (userData != null && userData.isNotEmpty) {
          return userData;
        }
      }
    }
    
    return {};
  }

  /// Helper method to safely convert Map<dynamic, dynamic> to Map<String, dynamic>
  Map<String, dynamic>? _convertToStringMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// Helper method to safely convert to int
  int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}