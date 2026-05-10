// ============================================================================
// FILE: features/ai_insights/ui/widgets/report_card_widget.dart
// Report Card widget showing letter grades for different aspects
// ============================================================================
import 'package:flutter/material.dart';
import '../../models/llm_models.dart';

class ReportCardWidget extends StatelessWidget {
  final ReportCard reportCard;

  const ReportCardWidget({super.key, required this.reportCard});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.indigo[600]),
                const SizedBox(width: 8),
                Text(
                  'Relationship Report Card',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _GradeItem(
                  label: 'Communication',
                  grade: reportCard.communication,
                  icon: Icons.chat_bubble_outline,
                ),
                _GradeItem(
                  label: 'Connection',
                  grade: reportCard.emotionalConnection,
                  icon: Icons.favorite_border,
                ),
                _GradeItem(
                  label: 'Balance',
                  grade: reportCard.balance,
                  icon: Icons.balance,
                ),
                _GradeItem(
                  label: 'Support',
                  grade: reportCard.support,
                  icon: Icons.handshake_outlined,
                ),
                _GradeItem(
                  label: 'Growth',
                  grade: reportCard.growth,
                  icon: Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Center(
              child: _OverallGrade(grade: reportCard.overall),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeItem extends StatelessWidget {
  final String label;
  final String grade;
  final IconData icon;

  const _GradeItem({
    required this.label,
    required this.grade,
    required this.icon,
  });

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green;
    if (grade.startsWith('B')) return Colors.blue;
    if (grade.startsWith('C')) return Colors.orange;
    if (grade.startsWith('D')) return Colors.deepOrange;
    if (grade.startsWith('F')) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGradeColor(grade);
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            grade,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OverallGrade extends StatelessWidget {
  final String grade;

  const _OverallGrade({required this.grade});

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green;
    if (grade.startsWith('B')) return Colors.blue;
    if (grade.startsWith('C')) return Colors.orange;
    if (grade.startsWith('D')) return Colors.deepOrange;
    if (grade.startsWith('F')) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGradeColor(grade);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Overall',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            grade,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
