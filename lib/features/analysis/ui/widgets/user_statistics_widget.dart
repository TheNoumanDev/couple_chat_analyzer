import 'package:flutter/material.dart';

class UserStatisticsWidget extends StatelessWidget {
  final List<dynamic> messagesByUser;
  final Map<String, dynamic> userAnalysis;

  const UserStatisticsWidget({
    Key? key,
    required this.messagesByUser,
    required this.userAnalysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (messagesByUser.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No user data available',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // User breakdown cards
        ...messagesByUser.map((user) {
          final userData = user as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildUserCard(context, userData),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> userData) {
    final userName = userData['name'] as String? ?? 'Unknown';
    final messageCount = userData['messageCount'] as int? ?? 0;
    final percentage = (userData['percentage'] as num?)?.toDouble() ?? 0.0;
    final wordCount = userData['wordCount'] as int? ?? 0;
    final letterCount = userData['letterCount'] as int? ?? 0;
    final mediaCount = userData['mediaCount'] as int? ?? 0;
    final emojiCount = userData['emojiCount'] as int? ?? 0;

    // Get user color based on their position
    final userIndex = messagesByUser.indexOf(userData);
    final userColor = _getUserColor(userIndex);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header with avatar and basic stats
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: userColor.withOpacity(0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: userColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: userColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$messageCount messages',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: userColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: userColor,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Detailed statistics grid
            _buildStatisticsGrid(context, wordCount, letterCount, mediaCount,
                emojiCount, userData['avgResponseTimeSeconds'] as int? ?? 0),

            const SizedBox(height: 16),

            // First and last message info
            _buildMessageTimestamps(context, userData),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid(
      BuildContext context,
      int wordCount,
      int letterCount,
      int mediaCount,
      int emojiCount,
      int avgResponseTimeSeconds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Breakdown',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // First row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Words',
                wordCount.toString(),
                Icons.text_fields,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Characters',
                letterCount.toString(),
                Icons.keyboard,
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
              child: _buildStatCard(
                context,
                'Media Files',
                mediaCount.toString(),
                Icons.image,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Emojis',
                emojiCount.toString(),
                Icons.emoji_emotions,
                Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Third row - Response time (centered)
        if (avgResponseTimeSeconds > 0)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Avg Response',
                  _formatResponseTime(avgResponseTimeSeconds),
                  Icons.timer,
                  Colors.teal,
                ),
              ),
              const Expanded(child: SizedBox()), // Empty space for balance
            ],
          ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
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

  Widget _buildMessageTimestamps(
      BuildContext context, Map<String, dynamic> userData) {
    final firstMessageDate = userData['firstMessageDate'] as String?;
    final lastMessageDate = userData['lastMessageDate'] as String?;
    final firstMessageTime = userData['firstMessageTime'] as String?;
    final lastMessageTime = userData['lastMessageTime'] as String?;
    final firstMessageContent = userData['firstMessageContent'] as String?;
    final lastMessageContent = userData['lastMessageContent'] as String?;

    if ((firstMessageDate == null || firstMessageDate == 'No data') &&
        (lastMessageDate == null || lastMessageDate == 'No data')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message Timeline',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimelineCardWithMessage(
                context,
                'First Message',
                firstMessageDate ?? 'No data',
                firstMessageTime ?? 'No data',
                firstMessageContent ?? 'No message',
                Icons.play_arrow,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimelineCardWithMessage(
                context,
                'Last Message',
                lastMessageDate ?? 'No data',
                lastMessageTime ?? 'No data',
                lastMessageContent ?? 'No message',
                Icons.stop,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineCardWithMessage(
      BuildContext context,
      String title,
      String date,
      String time,
      String messageContent,
      IconData icon,
      Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date
          Text(
            date,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          // Time (if available)
          if (time != 'No data') ...[
            const SizedBox(height: 2),
            Text(
              time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],

          // NEW: Message content
          if (messageContent != 'No message') ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Text(
                messageContent,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatResponseTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h';
    final days = hours ~/ 24;
    return '${days}d';
  }

  Color _getUserColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];
    return colors[index % colors.length];
  }
}
