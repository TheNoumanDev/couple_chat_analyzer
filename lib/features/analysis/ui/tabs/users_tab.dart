// ============================================================================
// COMPLETE ENHANCED USERS TAB - With Per-User Emoji Breakdown
// File: lib/features/analysis/ui/tabs/users_tab.dart
// ============================================================================

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
    final userAnalysis = _extractUserAnalysis(results);
    final behaviorPatterns = _extractBehaviorPatterns(results);
    
    debugPrint("👥 UsersTab: messagesByUser count: ${messagesByUser.length}");
    debugPrint("👥 UsersTab: userAnalysis keys: ${userAnalysis.keys.join(', ')}");
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Breakdown Chart (keep existing)
          UserStatisticsWidget(
            messagesByUser: messagesByUser,
            userAnalysis: userAnalysis,
          ),
          
          const SizedBox(height: 24),
          
          // 😀 NEW: Per-User Emoji Breakdown
          if (behaviorPatterns.isNotEmpty && messagesByUser.length >= 2)
            PerUserEmojiBreakdownWidget(
              messagesByUser: messagesByUser,
              behaviorPatterns: behaviorPatterns,
            ),
          
          const SizedBox(height: 24),
          
          // Enhanced Response Times Section
          if (userAnalysis.isNotEmpty)
            _buildEnhancedResponseTimesSection(context, userAnalysis),
          
          const SizedBox(height: 24),
          
          // Behavior Patterns (enhanced with compatibility explanation)
          if (results.containsKey('behaviorPatterns'))
            _buildEnhancedBehaviorPatternsSection(context, results['behaviorPatterns']),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEnhancedResponseTimesSection(BuildContext context, Map<String, dynamic> userAnalysis) {
    final userData = userAnalysis['userData'] as List<dynamic>? ?? [];

    // Get users with response times and add average response time to user cards
    final usersWithResponses = userData
        .where((user) {
          final responseTime = (user as Map<String, dynamic>)['avgResponseTimeSeconds'] as int? ?? 0;
          return responseTime > 0;
        })
        .cast<Map<String, dynamic>>()
        .toList();

    if (usersWithResponses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Response Patterns',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Show all users with their response times
        _buildAllUserResponseTimes(context, usersWithResponses),
      ],
    );
  }

  Widget _buildAllUserResponseTimes(BuildContext context, List<Map<String, dynamic>> usersWithResponses) {
    // Sort by response time
    usersWithResponses.sort((a, b) {
      final aTime = a['avgResponseTimeSeconds'] as int? ?? 0;
      final bTime = b['avgResponseTimeSeconds'] as int? ?? 0;
      return aTime.compareTo(bTime);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Response Times',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...usersWithResponses.map((user) {
              final name = user['name'] as String? ?? 'Unknown';
              final responseTime = user['avgResponseTimeSeconds'] as int? ?? 0;
              final formattedTime = _formatResponseTime(responseTime);
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getResponseTimeColor(responseTime).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getResponseTimeColor(responseTime),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        formattedTime,
                        style: TextStyle(
                          color: _getResponseTimeColor(responseTime),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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

  Widget _buildEnhancedBehaviorPatternsSection(BuildContext context, dynamic behaviorPatternsData) {
    Map<String, dynamic> behaviorPatterns;
    
    if (behaviorPatternsData is Map<String, dynamic> && behaviorPatternsData.containsKey('data')) {
      behaviorPatterns = _convertToStringMap(behaviorPatternsData['data']) ?? {};
    } else {
      behaviorPatterns = _convertToStringMap(behaviorPatternsData) ?? {};
    }

    final compatibilityScore = behaviorPatterns['compatibilityScore'] as int? ?? 0;
    final communicationStyles = _convertToStringMap(behaviorPatterns['communicationStyles']) ?? {};
    
    debugPrint("🧠 Behavior patterns - compatibilityScore: $compatibilityScore");
    debugPrint("🧠 Behavior patterns - communicationStyles keys: ${communicationStyles.keys.join(', ')}");
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Compatibility',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Compatibility Score Card
        if (compatibilityScore > 0)
          _buildCompatibilityScoreCard(context, compatibilityScore),
        
        const SizedBox(height: 16),
        
        // Communication Styles
        if (communicationStyles.isNotEmpty)
          _buildCommunicationStylesCard(context, communicationStyles),
      ],
    );
  }

  Widget _buildCompatibilityScoreCard(BuildContext context, int compatibilityScore) {
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;
    String explanation;
    
    if (compatibilityScore >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Highly Compatible';
      scoreIcon = Icons.favorite;
      explanation = 'You have very balanced communication with similar participation levels.';
    } else if (compatibilityScore >= 60) {
      scoreColor = Colors.lightGreen;
      scoreLabel = 'Well Matched';
      scoreIcon = Icons.thumb_up;
      explanation = 'Good communication balance with mostly even participation.';
    } else if (compatibilityScore >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Moderately Compatible';
      scoreIcon = Icons.sentiment_neutral;
      explanation = 'Some imbalance in participation, but still functional communication.';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Different Styles';
      scoreIcon = Icons.psychology;
      explanation = 'Significant imbalance in communication participation levels.';
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                scoreIcon,
                color: scoreColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$compatibilityScore%',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        scoreLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compatibility is based on message balance and participation patterns. It looks at message counts between users - more balanced participation means higher compatibility.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    explanation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scoreColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationStylesCard(BuildContext context, Map<String, dynamic> communicationStyles) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Communication Styles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...communicationStyles.entries.map((entry) {
              final userName = entry.key;
              final style = _convertToStringMap(entry.value) ?? {};
              final styleType = style['styleType'] as String? ?? 'Unknown';
              final avgLength = (style['avgMessageLength'] as num?)?.toDouble() ?? 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
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
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              styleType,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Avg: ${avgLength.toInt()} chars',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Extract userAnalysis data - it might be nested
  Map<String, dynamic> _extractUserAnalysis(Map<String, dynamic> results) {
    if (results.containsKey('userAnalysis')) {
      final userData = _convertToStringMap(results['userAnalysis']);
      if (userData != null && userData.isNotEmpty) {
        debugPrint("👥 Found userAnalysis directly");
        return userData;
      }
    }
    
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
    
    debugPrint("👥 No userAnalysis data found");
    return {};
  }

  /// Extract behavior patterns data
  Map<String, dynamic> _extractBehaviorPatterns(Map<String, dynamic> results) {
    if (results.containsKey('behaviorPatterns')) {
      final data = _convertToStringMap(results['behaviorPatterns']);
      if (data != null && data.isNotEmpty) {
        return data;
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

  Color _getResponseTimeColor(int seconds) {
    if (seconds < 60) return Colors.green;     // Under 1 minute - very fast
    if (seconds < 300) return Colors.blue;    // Under 5 minutes - fast
    if (seconds < 1800) return Colors.orange; // Under 30 minutes - moderate
    return Colors.red;                        // Over 30 minutes - slow
  }

  String _formatResponseTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()}m';
    if (seconds < 86400) return '${(seconds / 3600).round()}h';
    return '${(seconds / 86400).round()}d';
  }
}

// ============================================================================
// NEW: PER-USER EMOJI BREAKDOWN WIDGET
// ============================================================================

class PerUserEmojiBreakdownWidget extends StatelessWidget {
  final List<dynamic> messagesByUser;
  final Map<String, dynamic> behaviorPatterns;

  const PerUserEmojiBreakdownWidget({
    Key? key,
    required this.messagesByUser,
    required this.behaviorPatterns,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract communication styles which contain emoji data
    final communicationStyles = _convertToStringMap(behaviorPatterns['communicationStyles']) ?? {};
    
    if (communicationStyles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_emotions,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Emoji Usage by User',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'How each person uses emojis in conversations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            
            // User emoji breakdowns
            ...messagesByUser.map((user) {
              final userData = user as Map<String, dynamic>;
              final userName = userData['name'] as String? ?? 'Unknown';
              final emojiCount = userData['emojiCount'] as int? ?? 0;
              final messageCount = userData['messageCount'] as int? ?? 1;
              final emojiRate = emojiCount / messageCount;
              
              // Get communication style data for more details
              final userStyle = communicationStyles[userName] as Map<String, dynamic>? ?? {};
              final styleEmojiRate = double.tryParse(userStyle['emojiRate'] as String? ?? '0') ?? emojiRate;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildUserEmojiCard(
                  context,
                  userName,
                  emojiCount,
                  messageCount,
                  styleEmojiRate,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserEmojiCard(
    BuildContext context,
    String userName,
    int emojiCount,
    int messageCount,
    double emojiRate,
  ) {
    final userColor = _getUserColor(userName);
    final emojiCategory = _categorizeEmojiUsage(emojiRate);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: userColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: userColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: userColor.withOpacity(0.2),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: userColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // User emoji stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  emojiCategory,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: userColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Emoji stats row
                Row(
                  children: [
                    _buildEmojiStat(context, 'Total Emojis', emojiCount.toString(), Icons.emoji_emotions),
                    const SizedBox(width: 20),
                    _buildEmojiStat(context, 'Per Message', emojiRate.toStringAsFixed(1), Icons.trending_up),
                  ],
                ),
              ],
            ),
          ),
          
          // Visual indicator
          Container(
            width: 50,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (emojiRate * 0.5).clamp(0.0, 1.0), // Scale for visual
              child: Container(
                decoration: BoxDecoration(
                  color: userColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiStat(BuildContext context, String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _categorizeEmojiUsage(double rate) {
    if (rate > 2.0) return '🎭 Emoji Master';
    if (rate > 1.0) return '😊 Emoji Lover';
    if (rate > 0.5) return '🙂 Moderate User';
    if (rate > 0.1) return '😐 Light User';
    return '📝 Text Focused';
  }

  Color _getUserColor(String userName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];
    return colors[userName.hashCode.abs() % colors.length];
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
