import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';
import '../widgets/user_statistics_widget.dart';

class UsersTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const UsersTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messagesByUser = results['messagesByUser'] as List<dynamic>? ?? [];
    // Use safe conversion for userAnalysis - might be nested
    final userAnalysis = _extractUserAnalysis(results);
    
    debugPrint("👥 UsersTab: messagesByUser count: ${messagesByUser.length}");
    debugPrint("👥 UsersTab: userAnalysis keys: ${userAnalysis.keys.join(', ')}");
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Statistics Overview
          UserStatisticsWidget(
            messagesByUser: messagesByUser,
            userAnalysis: userAnalysis,
          ),
          
          const SizedBox(height: 24),
          
          // Top Performers Cards
          if (userAnalysis.isNotEmpty)
            TopPerformersCards(userAnalysis: userAnalysis),
          
          const SizedBox(height: 24),
          
          // Detailed User List
          UserDetailsList(messagesByUser: messagesByUser),
          
          const SizedBox(height: 24),
          
          // User Behavior Patterns (if available) - Fixed with safe conversion
          if (results.containsKey('behaviorPatterns'))
            _buildBehaviorPatternsSection(context, _convertToStringMap(results['behaviorPatterns']) ?? {}),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Extract userAnalysis data - it might be nested
  Map<String, dynamic> _extractUserAnalysis(Map<String, dynamic> results) {
    // Check direct userAnalysis key
    if (results.containsKey('userAnalysis')) {
      final userData = _convertToStringMap(results['userAnalysis']);
      if (userData != null && userData.isNotEmpty) {
        debugPrint("👥 Found userAnalysis directly");
        return userData;
      }
    }
    
    // Check nested in users container
    if (results.containsKey('users')) {
      final usersContainer = _convertToStringMap(results['users']);
      if (usersContainer != null && usersContainer.containsKey('userAnalysis')) {
        final userData = _convertToStringMap(usersContainer['userAnalysis']);
        if (userData != null && userData.isNotEmpty) {
          debugPrint("👥 Found userAnalysis nested in users");
          return userData;
        }
      }
    }
    
    // Check for direct user-related fields at root level
    final directUserFields = <String, dynamic>{};
    for (final key in results.keys) {
      if (key.contains('mostTalkative') || key.contains('leastTalkative') || 
          key.contains('fastestResponder') || key.contains('slowestResponder') ||
          key.contains('userData')) {
        directUserFields[key] = results[key];
      }
    }
    
    if (directUserFields.isNotEmpty) {
      debugPrint("👥 Found user fields at root level: ${directUserFields.keys.join(', ')}");
      return directUserFields;
    }
    
    debugPrint("👥 No userAnalysis data found");
    return {};
  }

  Widget _buildBehaviorPatternsSection(BuildContext context, Map<String, dynamic> behaviorPatterns) {
    final compatibilityScore = _safeInt(behaviorPatterns['compatibilityScore']) ?? 0;
    // Use safe conversion for communicationStyles
    final communicationStyles = _convertToStringMap(behaviorPatterns['communicationStyles']) ?? {};
    
    debugPrint("🧠 Behavior patterns - compatibilityScore: $compatibilityScore");
    debugPrint("🧠 Behavior patterns - communicationStyles keys: ${communicationStyles.keys.join(', ')}");
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Behavior Patterns',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Compatibility Score
            if (compatibilityScore > 0) ...[
              _buildCompatibilityCard(context, compatibilityScore),
              const SizedBox(height: 16),
            ],
            
            // Communication Styles
            if (communicationStyles.isNotEmpty) ...[
              Text(
                'Communication Styles',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...communicationStyles.entries.map((entry) {
                final userName = entry.key;
                // Use safe conversion for style data
                final style = _convertToStringMap(entry.value) ?? {};
                final styleType = style['styleType'] as String? ?? 'Unknown';
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              styleType,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              Text(
                'Behavior pattern analysis reveals communication styles, response patterns, and compatibility between conversation participants.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityCard(BuildContext context, int compatibilityScore) {
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;
    
    if (compatibilityScore >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Highly Compatible';
      scoreIcon = Icons.favorite;
    } else if (compatibilityScore >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Well Matched';
      scoreIcon = Icons.thumb_up;
    } else if (compatibilityScore >= 40) {
      scoreColor = Colors.amber;
      scoreLabel = 'Moderately Compatible';
      scoreIcon = Icons.sentiment_neutral;
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Different Styles';
      scoreIcon = Icons.psychology;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(scoreIcon, color: scoreColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compatibility Score',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '$compatibilityScore% - $scoreLabel',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to safely extract integer values
  int? _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper method to safely convert Map<dynamic, dynamic> to Map<String, dynamic>
  Map<String, dynamic>? _convertToStringMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        final result = <String, dynamic>{};
        data.forEach((key, value) {
          final stringKey = key.toString();
          // Recursively convert nested maps
          if (value is Map && value is! Map<String, dynamic>) {
            result[stringKey] = _convertToStringMap(value);
          } else if (value is List) {
            result[stringKey] = _convertList(value);
          } else {
            result[stringKey] = value;
          }
        });
        return result;
      } catch (e) {
        debugPrint('UsersTab: Error converting map: $e');
        return {};
      }
    }
    debugPrint('UsersTab: Data is not a map, type: ${data.runtimeType}');
    return {};
  }

  /// Helper method to safely convert lists with nested maps
  List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map && item is! Map<String, dynamic>) {
        return _convertToStringMap(item);
      }
      return item;
    }).toList();
  }
}