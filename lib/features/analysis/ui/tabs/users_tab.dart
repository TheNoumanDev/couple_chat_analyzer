import 'package:flutter/material.dart';
import '../widgets/analysis_cards.dart';
import '../widgets/user_statistics_widget.dart';

class UsersTab extends StatelessWidget {
  final Map<String, dynamic> results;

  const UsersTab({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messagesByUser = results['messagesByUser'] as List<dynamic>? ?? [];
    final userAnalysis = results['userAnalysis'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Statistics Overview
          UserStatisticsWidget(
            messagesByUser: messagesByUser,
            userAnalysis: userAnalysis,
          ),
          
          const SizedBox(height: 24),
          
          // Top Performers Cards
          if (userAnalysis.isNotEmpty)
            TopPerformersCards(userAnalysis: userAnalysis),
          
          const SizedBox(height: 24),
          
          // Detailed User List
          UserDetailsList(messagesByUser: messagesByUser),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}