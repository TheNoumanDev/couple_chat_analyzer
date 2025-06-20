import 'package:flutter/material.dart';
import '../widgets/relationship_evolution_widget.dart';

class RelationshipTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const RelationshipTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final relationshipInsights = results['relationshipInsights'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Relationship Analysis',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (relationshipInsights.isNotEmpty)
            RelationshipEvolutionWidget(data: relationshipInsights)
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No relationship data available'),
              ),
            ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}