import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';

class BehaviorTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const BehaviorTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final behaviorPatterns = results['behaviorPatterns'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Behavior Patterns',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (behaviorPatterns.isNotEmpty)
            BehaviorPatternsCard(data: behaviorPatterns)
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No behavior patterns data available'),
              ),
            ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}