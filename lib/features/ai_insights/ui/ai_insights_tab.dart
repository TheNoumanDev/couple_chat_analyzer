// ============================================================================
// FILE: features/ai_insights/ui/ai_insights_tab.dart
// AI Insights Tab for the analysis screen
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../analysis/analysis_models.dart';
import '../bloc/ai_insights_bloc.dart';
import '../models/llm_models.dart';
import 'widgets/personality_tags_card.dart';
import 'widgets/relationship_summary_card.dart';
import 'widgets/communication_insights_card.dart';
import 'widgets/strength_growth_card.dart';
import 'widgets/api_key_setup_card.dart';
import 'widgets/report_card_widget.dart';
import 'widgets/additional_insights_card.dart';

class AIInsightsTab extends StatefulWidget {
  final ChatAnalysisResult analysisResult;

  const AIInsightsTab({
    super.key,
    required this.analysisResult,
  });

  @override
  State<AIInsightsTab> createState() => _AIInsightsTabState();
}

class _AIInsightsTabState extends State<AIInsightsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Note: AI insights are now pre-fetched when analysis completes
    // This ensures results are ready when user navigates to this tab
    // We only trigger generation here as a fallback if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndGenerateInsights();
      }
    });
  }

  void _checkAndGenerateInsights() {
    final bloc = context.read<AIInsightsBloc>();
    // Only trigger if configured and not already loading/loaded
    if (bloc.isConfigured && bloc.state is AIInsightsInitial) {
      bloc.add(GenerateInsightsEvent(analysisResult: widget.analysisResult));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<AIInsightsBloc, AIInsightsState>(
      builder: (context, state) {
        if (state is AIInsightsInitial) {
          return _buildSetupView(context);
        }

        if (state is AIInsightsConfigured && !state.isApiKeyValid) {
          return _buildInvalidKeyView(context);
        }

        if (state is AIInsightsLoading) {
          return _buildLoadingView(context, state);
        }

        if (state is AIInsightsError) {
          return _buildErrorView(context, state);
        }

        if (state is AIInsightsSuccess) {
          return _buildInsightsView(context, state.insights);
        }

        // Default: show setup
        return _buildSetupView(context);
      },
    );
  }

  Widget _buildSetupView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 64,
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          Text(
            'AI-Powered Insights',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get personalized analysis of your chat patterns using AI',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          const ApiKeySetupCard(),
        ],
      ),
    );
  }

  Widget _buildInvalidKeyView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            'Invalid API Key',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'The API key you provided is invalid. Please check and try again.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          const ApiKeySetupCard(),
        ],
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context, AIInsightsLoading state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          const SizedBox(height: 24),
          Text(
            state.message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing patterns with AI...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, AIInsightsError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Generating Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (state.canRetry) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AIInsightsBloc>().add(
                        GenerateInsightsEvent(
                          analysisResult: widget.analysisResult,
                          forceRefresh: true,
                        ),
                      );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsView(BuildContext context, AIInsights insights) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AIInsightsBloc>().add(
              GenerateInsightsEvent(
                analysisResult: widget.analysisResult,
                forceRefresh: true,
              ),
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${insights.tokensUsed} tokens',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Overall narrative
            if (insights.overallNarrative.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Summary',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        insights.overallNarrative,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Personality tags
            if (insights.personalityTags.isNotEmpty) ...[
              PersonalityTagsCard(tags: insights.personalityTags),
              const SizedBox(height: 16),
            ],

            // Relationship summary
            RelationshipSummaryCard(summary: insights.relationshipSummary),
            const SizedBox(height: 16),

            // Communication insights
            if (insights.communicationInsights.isNotEmpty) ...[
              CommunicationInsightsCard(
                  insights: insights.communicationInsights),
              const SizedBox(height: 16),
            ],

            // Report Card with letter grades
            if (insights.reportCard != null) ...[
              ReportCardWidget(reportCard: insights.reportCard!),
              const SizedBox(height: 16),
            ],

            // Additional deep insights
            AdditionalInsightsCard(insights: insights),
            const SizedBox(height: 16),

            // Strengths and growth areas
            StrengthGrowthCard(
              strengths: insights.strengthAreas,
              growthAreas: insights.growthAreas,
            ),

            const SizedBox(height: 24),

            // Footer with provider info
            Center(
              child: Text(
                'Generated by ${context.read<AIInsightsBloc>().providerName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
