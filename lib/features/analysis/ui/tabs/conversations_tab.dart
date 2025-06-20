import 'package:flutter/material.dart';
import '../widgets/conversation_dynamics_widget.dart';

class ConversationsTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const ConversationsTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final conversationDynamics = results['conversationDynamics'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversation Dynamics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (conversationDynamics.isNotEmpty)
            ConversationDynamicsWidget(data: conversationDynamics)
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No conversation dynamics data available'),
              ),
            ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}