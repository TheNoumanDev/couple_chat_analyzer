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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (messagesByUser.isNotEmpty) ...[
              _buildUserRanking(context),
              const SizedBox(height: 16),
              _buildUserMetrics(context),
            ] else
              const Text('No user data available'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRanking(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message Distribution',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...messagesByUser.take(5).map((user) {
          final userData = user as Map<String, dynamic>;
          final rank = messagesByUser.indexOf(user) + 1;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getRankColor(rank),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rank.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    userData['name'] as String? ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${userData['messageCount'] ?? 0}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${(userData['percentage'] as double? ?? 0.0).toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildUserMetrics(BuildContext context) {
    final userData = userAnalysis['userData'] as List<dynamic>? ?? [];
    if (userData.isEmpty) return const SizedBox.shrink();

    final totalMessages = userData.fold<int>(0, (sum, user) {
      final userMap = user as Map<String, dynamic>;
      return sum + (userMap['messageCount'] as int? ?? 0);
    });

    final avgMessagesPerUser = userData.isNotEmpty ? totalMessages / userData.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Metrics',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                'Total Users',
                userData.length.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                'Avg/User',
                avgMessagesPerUser.toStringAsFixed(0),
                Icons.bar_chart,
                Colors.green,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}