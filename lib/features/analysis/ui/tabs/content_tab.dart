import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';
import '../widgets/analysis_charts.dart';

class ContentTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const ContentTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final contentAnalysis = results['contentAnalysis'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Overview Cards
          ContentOverviewCards(contentAnalysis: contentAnalysis),
          
          const SizedBox(height: 24),
          
          // Top Emojis
          if (contentAnalysis.containsKey('topEmojis'))
            TopEmojisChart(
              data: contentAnalysis['topEmojis'] as List<dynamic>,
            ),
          
          const SizedBox(height: 24),
          
          // Top Domains
          if (contentAnalysis.containsKey('topDomains'))
            TopDomainsChart(
              data: contentAnalysis['topDomains'] as List<dynamic>,
            ),
          
          const SizedBox(height: 24),
          
          // Message Length Distribution
          if (contentAnalysis.containsKey('messageLengthDistribution'))
            MessageLengthChart(
              data: contentAnalysis['messageLengthDistribution'] as Map<String, dynamic>,
            ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}