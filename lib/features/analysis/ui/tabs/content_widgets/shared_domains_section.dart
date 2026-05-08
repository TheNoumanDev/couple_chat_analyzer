import 'package:flutter/material.dart';
import '../../widgets/chart_constants.dart';
import 'missing_data_card.dart';

/// Shared domains section widget.
class SharedDomainsSection extends StatelessWidget {
  final Map<String, dynamic> contentAnalysis;

  const SharedDomainsSection({
    Key? key,
    required this.contentAnalysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (contentAnalysis.containsKey('topDomains')) {
      final topDomains = contentAnalysis['topDomains'];
      if (topDomains is List && topDomains.isNotEmpty) {
        return _buildTopDomainsChart(context, topDomains);
      }
    }

    return const MissingDataCard(
      title: 'Most Shared Domains',
      message: "No shared links detected yet. When you share websites, they'll appear here.",
      icon: Icons.link,
      color: Colors.blue,
    );
  }

  Widget _buildTopDomainsChart(BuildContext context, List<dynamic> topDomains) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Most Shared Domains',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topDomains.take(ChartConstants.maxTopDomains).map((domain) {
              final domainData = domain as Map<String, dynamic>;
              final domainName = domainData['domain'] as String? ?? 'Unknown';
              final count = domainData['count'] as int? ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        domainName,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
