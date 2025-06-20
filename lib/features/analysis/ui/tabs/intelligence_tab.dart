import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';

class IntelligenceTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const IntelligenceTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final contentIntelligence = results['contentIntelligence'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Intelligence',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (contentIntelligence.isNotEmpty)
            ContentIntelligenceCard(data: contentIntelligence)
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No content intelligence data available'),
              ),
            ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}