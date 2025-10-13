import 'package:flutter/material.dart';

class SummaryCards extends StatelessWidget {
  final Map<String, dynamic> summary;

  const SummaryCards({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'Messages',
            summary['totalMessages']?.toString() ?? '0',
            Icons.message,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Users',
            summary['totalUsers']?.toString() ?? '0',
            Icons.people,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Duration',
            _formatDuration(summary['durationDays']),
            Icons.calendar_today,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  String _formatDuration(dynamic days) {
    if (days == null) return '0 days';
    final dayCount = days is int ? days : int.tryParse(days.toString()) ?? 0;
    
    if (dayCount <= 30) {
      return '$dayCount days';
    } else if (dayCount <= 365) {
      final months = (dayCount / 30).round();
      return '${months}mo';
    } else {
      final years = (dayCount / 365).round();
      return '${years}yr';
    }
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 120, // Fixed height to prevent size changes
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
          const SizedBox(height: 4),
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
}

class QuickStatsCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> stats;

  const QuickStatsCard({
    Key? key,
    required this.title,
    required this.stats,
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
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Create a 2x2 grid with fixed dimensions
            _buildStatsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    // Ensure we have exactly 4 stats, pad with empty ones if needed
    final paddedStats = List<Map<String, dynamic>>.from(stats);
    while (paddedStats.length < 4) {
      paddedStats.add({
        'icon': Icons.info,
        'label': 'N/A',
        'value': '0',
      });
    }

    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                paddedStats[0]['label'] as String,
                paddedStats[0]['value'] as String,
                paddedStats[0]['icon'] as IconData,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                context,
                paddedStats[1]['label'] as String,
                paddedStats[1]['value'] as String,
                paddedStats[1]['icon'] as IconData,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                paddedStats[2]['label'] as String,
                paddedStats[2]['value'] as String,
                paddedStats[2]['icon'] as IconData,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: paddedStats.length > 3
                  ? _buildStatItem(
                      context,
                      paddedStats[3]['label'] as String,
                      paddedStats[3]['value'] as String,
                      paddedStats[3]['icon'] as IconData,
                    )
                  : _buildEmptyStatItem(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      height: 80, // Fixed height
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatItem(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
    );
  }
}

class TopPerformersCards extends StatelessWidget {
  final Map<String, dynamic> userAnalysis;

  const TopPerformersCards({
    Key? key,
    required this.userAnalysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mostTalkative = userAnalysis['mostTalkative'] as Map<String, dynamic>?;
    final fastestResponder = userAnalysis['fastestResponder'] as Map<String, dynamic>?;

    return Column(
      children: [
        if (mostTalkative != null)
          _buildPerformerCard(
            context,
            'Most Active',
            mostTalkative['name'] as String? ?? 'Unknown',
            '${mostTalkative['messageCount']} messages',
            Icons.chat_bubble,
            Colors.purple,
          ),
        if (fastestResponder != null) ...[
          const SizedBox(height: 12),
          _buildPerformerCard(
            context,
            'Fastest Responder',
            fastestResponder['name'] as String? ?? 'Unknown',
            '${fastestResponder['avgResponseTimeSeconds']}s avg',
            Icons.speed,
            Colors.green,
          ),
        ],
      ],
    );
  }

  Widget _buildPerformerCard(
    BuildContext context,
    String title,
    String name,
    String stat,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stat,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
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
}

class ContentOverviewCards extends StatelessWidget {
  final Map<String, dynamic> contentAnalysis;

  const ContentOverviewCards({
    Key? key,
    required this.contentAnalysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint("🎨 ContentOverviewCards: Building with data keys: ${contentAnalysis.keys.join(', ')}");
    debugPrint("🎨 ContentOverviewCards: Full data: $contentAnalysis");
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildContentCard(
                context,
                'Words',
                _extractValue('totalWords'),
                Icons.text_fields,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContentCard(
                context,
                'Emojis',
                _extractValue('totalEmojis'),
                Icons.emoji_emotions,
                Colors.yellow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContentCard(
                context,
                'Media',
                _extractValue('totalMedia'),
                Icons.image,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildContentCard(
                context,
                'URLs',
                _extractValue('totalUrls'),
                Icons.link,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContentCard(
                context,
                'Characters',
                _extractValue('totalCharacters'),
                Icons.keyboard,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            // Empty space to maintain alignment
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  /// Extract value with multiple fallback attempts
  String _extractValue(String key) {
    // Try direct key access first
    if (contentAnalysis.containsKey(key)) {
      final value = contentAnalysis[key];
      if (value != null) {
        return value.toString();
      }
    }
    
    // Try alternative key names
    final alternativeKeys = _getAlternativeKeys(key);
    for (final altKey in alternativeKeys) {
      if (contentAnalysis.containsKey(altKey)) {
        final value = contentAnalysis[altKey];
        if (value != null) {
          debugPrint("🔄 ContentOverviewCards: Using alternative key '$altKey' for '$key'");
          return value.toString();
        }
      }
    }
    
    debugPrint("⚠️ ContentOverviewCards: No value found for '$key', available keys: ${contentAnalysis.keys.join(', ')}");
    return '0';
  }
  
  /// Get alternative key names for a given key
  List<String> _getAlternativeKeys(String key) {
    switch (key) {
      case 'totalWords':
        return ['words', 'wordCount', 'total_words'];
      case 'totalEmojis':
        return ['emojis', 'emojiCount', 'total_emojis'];
      case 'totalMedia':
        return ['media', 'mediaCount', 'total_media'];
      case 'totalUrls':
        return ['urls', 'urlCount', 'total_urls', 'links', 'linkCount'];
      case 'totalCharacters':
        return ['characters', 'charCount', 'total_characters', 'chars'];
      default:
        return [];
    }
  }

  Widget _buildContentCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
class UserDetailsList extends StatelessWidget {
  final List<dynamic> messagesByUser;

  const UserDetailsList({
    Key? key,
    required this.messagesByUser,
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
              'User Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...messagesByUser.map((user) => _buildUserTile(context, user)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, dynamic user) {
    final userData = user as Map<String, dynamic>;
    final name = userData['name'] as String? ?? 'Unknown';
    final messageCount = userData['messageCount'] as int? ?? 0;
    final percentage = userData['percentage'] as double? ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
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
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$messageCount messages (${percentage.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
