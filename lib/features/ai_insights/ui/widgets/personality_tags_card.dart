// ============================================================================
// FILE: features/ai_insights/ui/widgets/personality_tags_card.dart
// Personality tags display widget
// ============================================================================
import 'package:flutter/material.dart';
import '../../models/llm_models.dart';

class PersonalityTagsCard extends StatelessWidget {
  final List<PersonalityTag> tags;

  const PersonalityTagsCard({
    super.key,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    // Group tags by user
    final tagsByUser = <String, List<PersonalityTag>>{};
    for (final tag in tags) {
      tagsByUser.putIfAbsent(tag.userName, () => []).add(tag);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Personality Traits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tagsByUser.entries.map((entry) => _buildUserTags(
                  context,
                  entry.key,
                  entry.value,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTags(
    BuildContext context,
    String userName,
    List<PersonalityTag> userTags,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: userTags.map((tag) => _buildTagChip(context, tag)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, PersonalityTag tag) {
    final color = _getCategoryColor(tag.category);

    return Tooltip(
      message: tag.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(tag.category),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              tag.tag,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'communication':
        return Colors.blue;
      case 'emotional':
        return Colors.pink;
      case 'social':
        return Colors.green;
      case 'intellectual':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'communication':
        return Icons.chat_bubble_outline;
      case 'emotional':
        return Icons.favorite_outline;
      case 'social':
        return Icons.people_outline;
      case 'intellectual':
        return Icons.lightbulb_outline;
      default:
        return Icons.star_outline;
    }
  }
}
