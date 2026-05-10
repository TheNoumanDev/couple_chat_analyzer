// ============================================================================
// FILE: features/ai_insights/ui/widgets/strength_growth_card.dart
// Strengths and growth areas display widget
// ============================================================================
import 'package:flutter/material.dart';

class StrengthGrowthCard extends StatelessWidget {
  final List<String> strengths;
  final List<String> growthAreas;

  const StrengthGrowthCard({
    super.key,
    required this.strengths,
    required this.growthAreas,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Strengths section
            if (strengths.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Strengths',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...strengths.map((strength) => _buildListItem(
                    context,
                    strength,
                    Colors.green,
                    Icons.check_circle,
                  )),
            ],

            // Growth areas section
            if (growthAreas.isNotEmpty) ...[
              if (strengths.isNotEmpty) const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Growth Opportunities',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...growthAreas.map((area) => _buildListItem(
                    context,
                    area,
                    Colors.blue,
                    Icons.arrow_forward,
                  )),
            ],

            // Empty state
            if (strengths.isEmpty && growthAreas.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No specific insights available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    String text,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
