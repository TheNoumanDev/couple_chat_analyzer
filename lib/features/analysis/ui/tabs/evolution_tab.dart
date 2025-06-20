import 'package:flutter/material.dart';
import '../widgets/timeline_widget.dart';

class EvolutionTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const EvolutionTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final temporalInsights = results['temporalInsights'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolution Timeline',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (temporalInsights.isNotEmpty)
            TimelineWidget(data: temporalInsights)
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No temporal insights data available'),
              ),
            ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}