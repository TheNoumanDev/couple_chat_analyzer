// features/analysis/analysis_ui.dart - PART 1
// Consolidated: analysis_page.dart + all charts + all cards + all widgets

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/common.dart';
import '../reports/reports_ui.dart';
import '../reports/reports_feature.dart';
import 'analysis_feature.dart';

// ============================================================================
// ANALYSIS PAGE
// ============================================================================
class AnalysisPage extends StatefulWidget {
  final String chatId;

  const AnalysisPage({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  late AnalysisBloc _analysisBloc;
  late ReportBloc _reportBloc;
  late TabController _tabController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    debugPrint("AnalysisPage: initState called with chatId: ${widget.chatId}");

    try {
      _analysisBloc = AnalysisBloc(analyzeChatUseCase: GetIt.instance.get());
      _reportBloc = ReportBloc(generateReportUseCase: GetIt.instance.get());
      _tabController =
          TabController(length: 9, vsync: this); // Updated to 9 tabs

      // Start analysis immediately
      _analysisBloc.add(AnalyzeChatEvent(widget.chatId));
      debugPrint("✅ AnalysisPage initialized successfully");
    } catch (e, stackTrace) {
      debugPrint("❌ Error in AnalysisPage initState: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  @override
  void dispose() {
    debugPrint("AnalysisPage: dispose called");
    _isDisposed = true;
    _analysisBloc.close();
    _reportBloc.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _analysisBloc),
        BlocProvider.value(value: _reportBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text('Analysis: ${widget.chatId.substring(0, 8)}...'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.summarize), text: 'Summary'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.access_time), text: 'Time'),
              Tab(icon: Icon(Icons.analytics), text: 'Content'),
              // New enhanced tabs
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Conversations'),
              Tab(icon: Icon(Icons.psychology), text: 'Behavior'),
              Tab(icon: Icon(Icons.favorite), text: 'Relationship'),
              Tab(icon: Icon(Icons.school), text: 'Intelligence'),
              Tab(icon: Icon(Icons.timeline), text: 'Evolution'),
            ],
          ),
          actions: [
            BlocBuilder<AnalysisBloc, AnalysisState>(
              builder: (context, state) {
                if (state is AnalysisSuccess) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Analysis',
                    onPressed: () {
                      _analysisBloc.add(AnalyzeChatEvent(widget.chatId));
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<AnalysisBloc, AnalysisState>(
          builder: (context, state) {
            if (state is AnalysisLoading) {
              return const LoadingIndicator(
                message:
                    'Analyzing your chat data...\nThis may take a moment for large chats',
              );
            }

            if (state is AnalysisError) {
              return _buildErrorView(context, state);
            }

            if (state is AnalysisSuccess) {
              if (!state.results.containsKey('summary')) {
                return _buildErrorView(
                    context,
                    const AnalysisError(
                        "Analysis results incomplete. Missing summary data."));
              }

              return _buildSuccessContent(context, state);
            }

            return _buildInitialView(context);
          },
        ),
        // Fixed floating action button
        floatingActionButton: BlocBuilder<AnalysisBloc, AnalysisState>(
          builder: (context, state) {
            if (state is AnalysisSuccess) {
              return Padding(
                padding: const EdgeInsets.only(
                    bottom: 20), // More padding from bottom
                child: FloatingActionButton.extended(
                  onPressed: () => _generateReport(context, state),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate Report'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

// Enhanced floating action button with better positioning
  Widget _buildFloatingReportButton(
      BuildContext context, AnalysisSuccess state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Add margin from bottom
      child: FloatingActionButton.extended(
        onPressed: () => _generateReport(context, state),
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generate Report'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 8,
      ),
    );
  }

// Enhanced success content with bottom padding
  Widget _buildSuccessContent(BuildContext context, AnalysisSuccess state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildSummaryTab(context, state),
        _buildUserStatsTab(context, state),
        _buildTimeAnalysisTab(context, state),
        _buildContentAnalysisTab(context, state),
        // New enhanced tabs
        _buildConversationDynamicsTab(context, state),
        _buildBehaviorPatternsTab(context, state),
        _buildRelationshipTab(context, state),
        _buildIntelligenceTab(context, state),
        _buildEvolutionTab(context, state),
      ],
    );
  }

// Update all tab methods to include bottom padding
  Widget _buildUserStatsTab(BuildContext context, AnalysisSuccess state) {
    final results = state.results;
    final userAnalysis = results['userAnalysis'] ?? {};
    final userData = userAnalysis['userData'] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Statistics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${userData.length} participants analyzed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // User Cards (with full stats)
        if (userData.isNotEmpty)
          ...List.generate(userData.length, (index) {
            final user = userData[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: UserStatsCard(
                title: '#${index + 1} - ${user['name'] ?? 'Unknown'}',
                user: user,
              ),
            );
          })
        else
          _buildPlaceholderCard("No user data available"),

        // Response Time Analysis (only if data available)
        if (userAnalysis['fastestResponder'] != null ||
            userAnalysis['slowestResponder'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Response Time Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (userAnalysis['fastestResponder'] != null)
                  _buildResponseTimeRow(
                    context,
                    'Fastest Responder',
                    userAnalysis['fastestResponder']['name'],
                    _formatDuration(userAnalysis['fastestResponder']
                        ['avgResponseTimeSeconds']),
                    Icons.flash_on,
                    Colors.green,
                  ),
                if (userAnalysis['slowestResponder'] != null)
                  _buildResponseTimeRow(
                    context,
                    'Slower One',
                    userAnalysis['slowestResponder']['name'],
                    _formatDuration(userAnalysis['slowestResponder']
                        ['avgResponseTimeSeconds']),
                    Icons.schedule,
                    Colors.orange,
                  ),
              ],
            ),
          ),

        // Bottom padding for floating button
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTimeAnalysisTab(BuildContext context, AnalysisSuccess state) {
    final results = state.results;
    final timeAnalysis = results['timeAnalysis'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _buildSectionHeader(
            context,
            'Activity Patterns',
            'When are you most active in this chat?',
            Icons.insights,
          ),
          const SizedBox(height: 16),

          // Day of Week Chart
          Text(
            'Messages by Day of Week',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (timeAnalysis['dayOfWeek'] != null)
            TimeDistributionChart.dayOfWeek(timeAnalysis['dayOfWeek'])
          else
            _buildPlaceholderCard("Day of week data not available"),

          const SizedBox(height: 32),

          // Hour of Day Chart
          Text(
            'Messages by Hour of Day',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (timeAnalysis['hourOfDay'] != null)
            TimeDistributionChart.hourOfDay(timeAnalysis['hourOfDay'])
          else
            _buildPlaceholderCard("Hour of day data not available"),

          const SizedBox(height: 32),

          // Top Active Days
          Text(
            'Most Active Days',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          if (timeAnalysis['topDays'] != null &&
              (timeAnalysis['topDays'] as List).isNotEmpty)
            _buildTopDaysList(context, timeAnalysis['topDays'])
          else
            _buildPlaceholderCard("Top days data not available"),

          // Bottom padding for floating button
          const SizedBox(height: 80),
        ],
      ),
    );
  }

// Update content analysis tab
  Widget _buildContentAnalysisTab(BuildContext context, AnalysisSuccess state) {
    final results = state.results;
    final contentAnalysis = results['contentAnalysis'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _buildSectionHeader(
            context,
            'Content Analysis',
            'What do you talk about most?',
            Icons.analytics,
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildContentStatCard(
                  context,
                  'Total Words',
                  '${contentAnalysis['totalWords'] ?? 0}',
                  Icons.text_fields,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContentStatCard(
                  context,
                  'Unique Words',
                  '${contentAnalysis['totalUniqueWords'] ?? 0}',
                  Icons.psychology,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top Words - Word Cloud Style
          Text(
            'Most Used Words',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Size indicates frequency • All words counted without filtering',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 16),
          if (contentAnalysis['topWords'] != null &&
              (contentAnalysis['topWords'] as List).isNotEmpty)
            ContentAnalysisChart.topWords(contentAnalysis['topWords'])
          else
            _buildPlaceholderCard("Word analysis data not available"),

          const SizedBox(height: 32),

          // Emoji Usage
          Row(
            children: [
              Expanded(
                child: Text(
                  'Emoji Usage',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${contentAnalysis['totalEmojis'] ?? 0} total',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your most frequently used emojis',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 16),
          if (contentAnalysis['topEmojis'] != null &&
              (contentAnalysis['topEmojis'] as List).isNotEmpty)
            ContentAnalysisChart.topEmojis(contentAnalysis['topEmojis'])
          else
            _buildPlaceholderCard("No emojis found in this chat"),

          const SizedBox(height: 32),

          // Top Domains
          Text(
            'Shared Links',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Most frequently shared websites',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 16),
          if (contentAnalysis['topDomains'] != null &&
              (contentAnalysis['topDomains'] as List).isNotEmpty)
            _buildTopDomainsList(context, contentAnalysis['topDomains'])
          else
            _buildPlaceholderCard("No shared links found in this chat"),

          const SizedBox(height: 32),

          // Word Statistics Summary
          _buildWordStatsSummary(context, contentAnalysis),

          // Bottom padding for floating button
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInitialView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to analyze your chat data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _analysisBloc.add(AnalyzeChatEvent(widget.chatId));
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Analysis'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, AnalysisError state) {
    return ErrorView(
      message: state.message,
      onRetry: () => _analysisBloc.add(AnalyzeChatEvent(widget.chatId)),
    );
  }

  void _generateReport(BuildContext context, AnalysisSuccess state) {
    try {
      _reportBloc.add(GenerateReportEvent(widget.chatId, state.results));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: _reportBloc,
            child: const ReportPage(),
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ Error generating report: $e");

      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _generateReport(context, state),
            ),
          ),
        );
      }
    }
  }

  // Updated _buildSummaryTab method - replace chart with user cards
  Widget _buildSummaryTab(BuildContext context, AnalysisSuccess state) {
    final results = state.results;
    final summary = results['summary'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Summary Card
          SummaryCard(
            totalMessages: summary['totalMessages'] ?? 0,
            totalParticipants: summary['totalParticipants'] ?? 0,
            dateRange: summary['dateRange'] ?? 'N/A',
            avgMessagesPerDay: (summary['avgMessagesPerDay'] ?? 0).toDouble(),
          ),
          const SizedBox(height: 24),

          // User Cards List (instead of chart)
          if (results['messageCount'] != null)
            UserCardsList(data: results['messageCount'])
          else
            _buildPlaceholderCard("Message count data not available"),

          const SizedBox(height: 24),

          // Stats Grid - 2x2 layout
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  context,
                  'Total Media',
                  '${summary['totalMedia'] ?? 0}',
                  Icons.image,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickStatCard(
                  context,
                  'Chat Duration',
                  '${summary['durationDays'] ?? 0} days',
                  Icons.calendar_month,
                  Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Second row of stats
          Row(
            children: [
              Expanded(
                child: _buildTimeStatCard(
                  context,
                  'Most Active Day',
                  results['timeAnalysis']?['mostActiveDay']?['day'] ?? 'N/A',
                  '${results['timeAnalysis']?['mostActiveDay']?['count'] ?? 0} msgs',
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeStatCard(
                  context,
                  'Peak Hour',
                  '${results['timeAnalysis']?['mostActiveHour']?['hour'] ?? '00'}:00',
                  '${results['timeAnalysis']?['mostActiveHour']?['count'] ?? 0} msgs',
                  Icons.access_time,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Most Active User - Simple Card (no detailed stats)
          if (results['userAnalysis'] != null &&
              results['userAnalysis']['mostTalkative'] != null)
            _buildSimpleMostActiveUser(
                context, results['userAnalysis']['mostTalkative'])
          else
            _buildPlaceholderCard("User analysis data not available"),

          const SizedBox(height: 80), // Extra padding for floating button
        ],
      ),
    );
  }

  Widget _buildTimeStatCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// Simple most active user card (no detailed stats)
  Widget _buildSimpleMostActiveUser(
      BuildContext context, Map<String, dynamic> user) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Most Active Participant',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _getInitials(user['name'] ?? ''),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Unknown',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${user['messageCount'] ?? 0} messages',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.split(' ');
    if (parts.length == 1) {
      return name.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

// Helper method to build content stat cards
  Widget _buildContentStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// Helper method to build word statistics summary
  Widget _buildWordStatsSummary(
      BuildContext context, Map<String, dynamic> contentAnalysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Word Statistics Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Words Used',
                  '${contentAnalysis['totalWords'] ?? 0}',
                  Icons.format_list_numbered,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Unique Words',
                  '${contentAnalysis['totalUniqueWords'] ?? 0}',
                  Icons.star,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Emojis',
                  '${contentAnalysis['totalEmojis'] ?? 0}',
                  Icons.emoji_emotions,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Links Shared',
                  '${contentAnalysis['totalDomains'] ?? 0}',
                  Icons.link,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Helper method to build individual stat items
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widgets and methods
  Widget _buildPlaceholderCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeRow(
    BuildContext context,
    String label,
    String name,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDaysList(BuildContext context, List<dynamic> topDays) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: List.generate(
          topDays.take(5).length,
          (index) {
            final day = topDays[index];
            return ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                day['date'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${day['count'] ?? 0} messages',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Complete _buildTopDomainsList method in AnalysisPage
  Widget _buildTopDomainsList(BuildContext context, List<dynamic> topDomains) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Top ${topDomains.length} Shared Domains',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          // List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topDomains.take(10).length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
            itemBuilder: (context, index) {
              final domain = topDomains[index];
              final isEven = index % 2 == 0;

              return Container(
                color: isEven
                    ? null
                    : Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.public, size: 20),
                      ),
                    ],
                  ),
                  title: Text(
                    domain['domain'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Shared ${domain['count']} time${domain['count'] > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${domain['count']}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Footer
          if (topDomains.length > 10)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  'And ${topDomains.length - 10} more domains...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Add these methods to the _AnalysisPageState class in analysis_ui.dart

  Widget _buildConversationDynamicsTab(
      BuildContext context, AnalysisSuccess state) {
    final results = state.results;
    final conversationDynamics = results['conversationDynamics'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Conversation Dynamics',
            'Who starts and drives conversations?',
            Icons.chat_bubble_outline,
          ),
          const SizedBox(height: 16),

          // Conversation Stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  context,
                  'Total Conversations',
                  '${conversationDynamics['totalConversations'] ?? 0}',
                  Icons.chat,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickStatCard(
                  context,
                  'Health Score',
                  '${conversationDynamics['conversationHealthScore'] ?? 0}%',
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Conversation Initiators
          if (conversationDynamics['conversationInitiators'] != null)
            _buildInitiatorsSection(
                context, conversationDynamics['conversationInitiators']),

          const SizedBox(height: 24),

          // Dialog Flow Patterns
          if (conversationDynamics['dialogFlowTypes'] != null)
            _buildDialogFlowSection(
                context, conversationDynamics['dialogFlowTypes']),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBehaviorPatternsTab(
      BuildContext context, AnalysisSuccess state) {
    final results = state.results;
    final behaviorPatterns = results['behaviorPatterns'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Behavior Patterns',
            'Your unique communication personalities',
            Icons.psychology,
          ),
          const SizedBox(height: 16),

          // Time Personalities
          if (behaviorPatterns['timePersonalities'] != null)
            _buildTimePersonalitiesSection(
                context, behaviorPatterns['timePersonalities']),

          const SizedBox(height: 24),

          // Energy Levels
          if (behaviorPatterns['energyLevels'] != null)
            _buildEnergyLevelsSection(
                context, behaviorPatterns['energyLevels']),

          const SizedBox(height: 24),

          // Compatibility Score
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compatibility Score',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${behaviorPatterns['compatibilityScore'] ?? 0}%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildRelationshipTab(BuildContext context, AnalysisSuccess state) {
    final results = state.results;
    final relationshipDynamics = results['relationshipDynamics'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Relationship Dynamics',
            'How you connect and support each other',
            Icons.favorite,
          ),
          const SizedBox(height: 16),

          // Relationship Health Score
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.green, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relationship Health Score',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${relationshipDynamics['relationshipHealthScore'] ?? 0}%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Support Patterns
          if (relationshipDynamics['supportPatterns'] != null)
            _buildSupportPatternsSection(
                context, relationshipDynamics['supportPatterns']),

          const SizedBox(height: 24),

          // Response Patterns
          if (relationshipDynamics['responsePatterns'] != null)
            _buildResponsePatternsSection(
                context, relationshipDynamics['responsePatterns']),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildIntelligenceTab(BuildContext context, AnalysisSuccess state) {
    final results = state.results;
    final contentIntelligence = results['contentIntelligence'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Communication Intelligence',
            'Your communication styles and intelligence patterns',
            Icons.school,
          ),
          const SizedBox(height: 16),

          // Intelligence Scores
          if (contentIntelligence['intelligenceScores'] != null)
            _buildIntelligenceScoresSection(
                context, contentIntelligence['intelligenceScores']),

          const SizedBox(height: 24),

          // Communication Styles
          if (contentIntelligence['communicationStyles'] != null)
            _buildCommunicationStylesSection(
                context, contentIntelligence['communicationStyles']),

          const SizedBox(height: 24),

          // Vocabulary Analysis
          if (contentIntelligence['vocabularyAnalysis'] != null)
            _buildVocabularySection(
                context, contentIntelligence['vocabularyAnalysis']),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEvolutionTab(BuildContext context, AnalysisSuccess state) {
    final results = state.results;
    final temporalInsights = results['temporalInsights'] ?? {};

    if (temporalInsights['message'] != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 80,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 24),
              Text(
                temporalInsights['message'],
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (temporalInsights['recommendation'] != null) ...[
                const SizedBox(height: 16),
                Text(
                  temporalInsights['recommendation'],
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Evolution Timeline',
            'How your communication has evolved over time',
            Icons.timeline,
          ),
          const SizedBox(height: 16),

          // Overall Trends
          if (temporalInsights['overallTrends'] != null)
            _buildOverallTrendsSection(
                context, temporalInsights['overallTrends']),

          const SizedBox(height: 24),

          // Relationship Evolution
          if (temporalInsights['relationshipEvolution'] != null)
            _buildRelationshipEvolutionSection(
                context, temporalInsights['relationshipEvolution']),

          const SizedBox(height: 24),

          // Evolution Timeline
          if (temporalInsights['evolutionTimeline'] != null)
            _buildEvolutionTimelineSection(
                context, temporalInsights['evolutionTimeline']),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

// Helper methods for building sections (you can add more as needed)
  Widget _buildInitiatorsSection(
      BuildContext context, List<dynamic> initiators) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversation Initiators',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...initiators
                .map((initiator) => ListTile(
                      title: Text(initiator['name']),
                      subtitle:
                          Text('${initiator['percentage']}% of conversations'),
                      trailing: Text('${initiator['count']}'),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

// Add more helper methods as needed for other sections...

  // Add these complete helper methods to the _AnalysisPageState class in analysis_ui.dart

// Dialog Flow Section
  Widget _buildDialogFlowSection(BuildContext context, Map<String, dynamic> dialogFlow) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Conversation Flow Patterns',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showFlowPatternsInfo(context),
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'How you exchange messages with each other',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedFlowTypeCard(
                  context, 
                  'Rapid Fire', 
                  '${dialogFlow['rapidFire'] ?? 0}', 
                  Icons.flash_on, 
                  Colors.orange,
                  'Quick back-and-forth\nresponses (<10 sec)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(  
                child: _buildEnhancedFlowTypeCard(
                  context, 
                  'Balanced', 
                  '${dialogFlow['balanced'] ?? 0}', 
                  Icons.balance, 
                  Colors.green,
                  'Natural turn-taking\nconversations',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedFlowTypeCard(
                  context, 
                  'Monologue', 
                  '${dialogFlow['monologue'] ?? 0}', 
                  Icons.record_voice_over, 
                  Colors.blue,
                  'Multiple messages\nin a row',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildEnhancedFlowTypeCard(
  BuildContext context, 
  String title, 
  String count, 
  IconData icon, 
  Color color,
  String description,
) {
  return GestureDetector(
    onTap: () => _showFlowTypeDetails(context, title, description),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget _buildTimePersonalitiesSection(BuildContext context, Map<String, dynamic> personalities) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Time Personalities',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showTimePersonalityInfo(context),
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'When each person is most active in chat',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ...personalities.entries.map((entry) {
            final userData = entry.value as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getPersonalityColor(userData['personality'] ?? ''),
                    child: Text(
                      _getInitials(entry.key),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(userData['personality'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          'Most active at ${userData['peakHour'] ?? 'N/A'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPersonalityColor(userData['personality'] ?? ''),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Peak: ${userData['peakHour'] ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ),
  );
}

// Helper method to get personality colors
Color _getPersonalityColor(String personality) {
  if (personality.contains('Night Owl')) return Colors.deepPurple;
  if (personality.contains('Early Bird')) return Colors.orange;
  if (personality.contains('Afternoon')) return Colors.blue;
  if (personality.contains('Evening')) return Colors.indigo;
  return Colors.grey;
}

// Information dialogs
void _showFlowPatternsInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Conversation Flow Patterns'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.flash_on, 'Rapid Fire', 'Quick back-and-forth exchanges within 10 seconds. Shows active, engaged conversations.', Colors.orange),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.balance, 'Balanced', 'Natural turn-taking where both people participate equally in the conversation.', Colors.green),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.record_voice_over, 'Monologue', 'One person sends multiple messages in a row before the other responds.', Colors.blue),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    ),
  );
}

void _showTimePersonalityInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Time Personalities'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('We analyze when each person is most active:'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.nightlight, 'Night Owl 🦉', 'Most active between 10 PM - 6 AM', Colors.deepPurple),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.wb_sunny, 'Early Bird 🐦', 'Most active between 6 AM - 10 AM', Colors.orange),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.sunny, 'Afternoon Person ☀️', 'Most active between 12 PM - 5 PM', Colors.blue),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.wb_twilight, 'Evening Person 🌅', 'Most active between 6 PM - 10 PM', Colors.indigo),
          const SizedBox(height: 12),
          const Text(
            'Peak Time = The hour when they send the most messages',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    ),
  );
}

void _showFlowTypeDetails(BuildContext context, String title, String description) {
  String detailedDescription = '';
  String example = '';
  
  switch (title) {
    case 'Rapid Fire':
      detailedDescription = 'These are fast-paced conversations where people respond quickly (within 10 seconds). Shows high engagement and active participation.';
      example = 'Example:\n👤 Hey!\n👥 Hi there!\n👤 How are you?\n👥 Good! You?\n👤 Great!';
      break;
    case 'Balanced':
      detailedDescription = 'Natural conversations where both people participate equally, taking turns in a healthy way.';
      example = 'Example:\n👤 Had a great day at work\n👥 That\'s awesome! What happened?\n👤 Got promoted!\n👥 Congratulations! 🎉';
      break;
    case 'Monologue':
      detailedDescription = 'One person sends multiple messages in a row. This can show storytelling, explaining something detailed, or one-sided conversations.';
      example = 'Example:\n👤 So I went to the store\n👤 And guess what happened\n👤 I met our old teacher!\n👤 She remembered me\n👥 Wow that\'s cool!';
      break;
  }
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detailedDescription),
          const SizedBox(height: 16),
          if (example.isNotEmpty) ...[
            Text(
              'Example:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                example,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(IconData icon, String title, String description, Color color) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              description,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildFlowTypeCard(BuildContext context, String title, String count,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// Energy Levels Section
  Widget _buildEnergyLevelsSection(
      BuildContext context, Map<String, dynamic> energyLevels) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy Levels',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...energyLevels.entries.map((entry) {
              final userData = entry.value as Map<String, dynamic>;
              final energyScore =
                  double.tryParse(userData['energyScore'] ?? '50') ?? 50.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.key,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getEnergyColor(energyScore),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            userData['energyType'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: energyScore / 100,
                      backgroundColor: Colors.grey[300],
                      color: _getEnergyColor(energyScore),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Score: ${userData['energyScore']}%'),
                        const Spacer(),
                        Text('Avg Length: ${userData['avgMessageLength']}'),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getEnergyColor(double score) {
    if (score > 80) return Colors.red;
    if (score > 60) return Colors.orange;
    if (score > 40) return Colors.green;
    return Colors.blue;
  }

// Support Patterns Section
  Widget _buildSupportPatternsSection(
      BuildContext context, Map<String, dynamic> supportPatterns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support Patterns',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...supportPatterns.entries.map((entry) {
              final userData = entry.value as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.key,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            userData['supportType'] ?? '',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSupportStat(
                              context,
                              'Questions',
                              '${userData['questionsAsked'] ?? 0}',
                              Icons.help_outline),
                        ),
                        Expanded(
                          child: _buildSupportStat(context, 'Help',
                              '${userData['helpProvided'] ?? 0}', Icons.build),
                        ),
                        Expanded(
                          child: _buildSupportStat(
                              context,
                              'Support',
                              '${userData['emotionalSupport'] ?? 0}',
                              Icons.favorite),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportStat(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

// Response Patterns Section
  Widget _buildResponsePatternsSection(BuildContext context, Map<String, dynamic> responsePatterns) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Response Patterns',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showResponsePatternsInfo(context),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'How quickly each person responds to messages',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ...responsePatterns.entries.map((entry) {
            final userData = entry.value as Map<String, dynamic>;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // User Header Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _getResponseColor(userData['responsiveness'] ?? 'Moderate'),
                        child: Text(
                          _getInitials(entry.key),
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userData['profile'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Average Response Time
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userData['avgResponseTime'] ?? 'N/A',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Average',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        
                        // Responsiveness Badge
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getResponseColor(userData['responsiveness'] ?? 'Moderate'),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  userData['responsiveness'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Speed Rating',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        
                        // Response Count
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                Icons.reply,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${userData['responseCount'] ?? 0}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Responses',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ),
  );
}


// Intelligence Scores Section
  Widget _buildIntelligenceScoresSection(
      BuildContext context, Map<String, dynamic> intelligenceScores) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Intelligence Scores',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...intelligenceScores.entries.map((entry) {
              final userData = entry.value as Map<String, dynamic>;
              final score =
                  double.tryParse(userData['overallScore'] ?? '50') ?? 50.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getIntelligenceColor(score).withOpacity(0.1),
                      _getIntelligenceColor(score).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _getIntelligenceColor(score).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getIntelligenceColor(score),
                          child: Text(
                            _getInitials(entry.key),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(userData['intelligenceType'] ?? ''),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getIntelligenceColor(score),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${userData['overallScore']}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: Colors.grey[300],
                      color: _getIntelligenceColor(score),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: Text(
                                'Vocab: ${userData['vocabContribution']}%')),
                        Expanded(
                            child: Text(
                                'Curiosity: ${userData['curiosityContribution']}%')),
                        Expanded(
                            child: Text(
                                'Info: ${userData['infoSharingContribution']}%')),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getIntelligenceColor(double score) {
    if (score > 85) return Colors.purple;
    if (score > 75) return Colors.indigo;
    if (score > 65) return Colors.blue;
    if (score > 55) return Colors.green;
    return Colors.orange;
  }

// Communication Styles Section
// Replace the _buildCommunicationStylesSection method in analysis_ui.dart

// Clean stat card design
Widget _buildCleanStyleStat(
  BuildContext context,
  String label,
  String value,
  IconData icon,
  Color color,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

// Much Better Evolution Timeline Section - Visual and Intuitive
Widget _buildEvolutionTimelineSection(BuildContext context, Map<String, dynamic> evolutionTimeline) {
  final milestones = evolutionTimeline['milestones'] as List? ?? [];
  final totalDays = evolutionTimeline['totalTimeSpanDays'] as int? ?? 0;
  final startDate = evolutionTimeline['startDate'] as String? ?? '';
  final endDate = evolutionTimeline['endDate'] as String? ?? '';
  
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with duration info
          Row(
            children: [
              Icon(Icons.timeline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Your Journey Together',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Duration Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$totalDays days of conversation',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$startDate → $endDate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Visual Timeline
          ...milestones.asMap().entries.map((entry) {
            final index = entry.key;
            final milestone = entry.value;
            final isLast = index == milestones.length - 1;
            final daysSinceStart = milestone['daysSinceStart'] as int? ?? 0;
            final progress = totalDays > 0 ? (daysSinceStart / totalDays) : 0.0;
            
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline visual element
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _getMilestoneColor(milestone['milestone'] ?? ''),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _getMilestoneIcon(milestone['milestone'] ?? ''),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Milestone content
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    milestone['milestone'] ?? '',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    milestone['date'] ?? '',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              milestone['description'] ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            // Progress indicator
                            Row(
                              children: [
                                Text(
                                  'Day $daysSinceStart',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    color: _getMilestoneColor(milestone['milestone'] ?? ''),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast) const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ),
    ),
  );
}

Color _getMilestoneColor(String milestone) {
  if (milestone.contains('Messages')) return Colors.blue;
  if (milestone.contains('Busiest')) return Colors.orange;
  if (milestone.contains('Year')) return Colors.green;
  return Colors.purple;
}

Widget _getMilestoneIcon(String milestone) {
  IconData icon = Icons.chat;
  if (milestone.contains('Messages')) icon = Icons.chat_bubble;
  if (milestone.contains('Busiest')) icon = Icons.trending_up;
  if (milestone.contains('Year')) icon = Icons.celebration;
  
  return Icon(
    icon,
    color: Colors.white,
    size: 12,
  );
}

// Info dialogs for new sections
void _showResponsePatternsInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Response Patterns'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We analyze how quickly people respond to messages:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            
            // Response Speed Categories
            const Text(
              'Response Speed Types:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            
            _buildInfoRow(Icons.flash_on, 'Lightning Fast ⚡', 'Responds within 5 minutes', Colors.green),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.directions_run, 'Quick Responder 🏃', 'Responds within 30 minutes', Colors.lightGreen),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.schedule, 'Steady Responder 🚶', 'Responds within 2 hours', Colors.blue),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, 'Thoughtful Responder 🤔', 'Responds within 12 hours', Colors.orange),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.timer, 'Takes Their Time ⏰', 'Responds after several hours/days', Colors.red),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // Speed Rating Categories
            const Text(
              'Speed Ratings:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            
            _buildSpeedRatingRow(context, 'Very High', 'Lightning fast responses', Colors.green),
            const SizedBox(height: 6),
            _buildSpeedRatingRow(context, 'High', 'Quick and responsive', Colors.lightGreen),
            const SizedBox(height: 6),
            _buildSpeedRatingRow(context, 'Good', 'Steady, reliable responses', Colors.blue),
            const SizedBox(height: 6),
            _buildSpeedRatingRow(context, 'Moderate', 'Thoughtful response time', Colors.orange),
            const SizedBox(height: 6),
            _buildSpeedRatingRow(context, 'Low', 'Takes time to respond', Colors.red),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'What this means:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Average Response Time = How long it typically takes them to reply to your messages\n'
                    '• Speed Rating = Overall responsiveness level\n'
                    '• Responses = Total number of times they replied to messages',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    ),
  );
}

// New helper method for speed rating rows
Widget _buildSpeedRatingRow(BuildContext context, String rating, String description, Color color) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          rating,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          description,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ],
  );
}

// Also update the _getResponseColor method to match your actual categories
Color _getResponseColor(String responsiveness) {
  switch (responsiveness.toLowerCase()) {
    case 'very high':
      return Colors.green;
    case 'high':
      return Colors.lightGreen;
    case 'good':
      return Colors.blue;        // This matches your "Good" rating
    case 'moderate':
      return Colors.orange;
    case 'low':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// Vocabulary Section
  // Replace the _buildVocabularySection method in analysis_ui.dart

Widget _buildVocabularySection(BuildContext context, Map<String, dynamic> vocabularyAnalysis) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Theme.of(context).colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                'Vocabulary Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showVocabularyAnalysisInfo(context),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Word complexity and language sophistication analysis',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          
          // User Cards
          ...vocabularyAnalysis.entries.map((entry) {
            final userData = entry.value as Map<String, dynamic>;
            final complexityScore = double.tryParse(userData['complexityScore'] ?? '50') ?? 50.0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Header with user info and vocabulary type
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: _getVocabularyColor(complexityScore),
                              child: Text(
                                _getInitials(entry.key),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getVocabularyColor(complexityScore),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      userData['vocabularyType'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Complexity Progress Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Vocabulary Complexity',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${userData['complexityScore']}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: complexityScore / 100,
                              backgroundColor: Colors.grey[300],
                              color: _getVocabularyColor(complexityScore),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Stats section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // First row of stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildVocabStat(
                                context,
                                'Total Words Used',
                                '${userData['totalWords'] ?? 0}',
                                Icons.chat_bubble_outline,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildVocabStat(
                                context,
                                'Unique Words',
                                '${userData['uniqueWords'] ?? 0}',
                                Icons.auto_awesome,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Second row of stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildVocabStat(
                                context,
                                'Average Word Length',
                                '${userData['avgWordLength']} letters',
                                Icons.straighten,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildVocabStat(
                                context,
                                'Complex Words',
                                '${userData['complexWordPercentage']}%',
                                Icons.psychology,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ),
  );
}

// Clean vocabulary stat card design
Widget _buildVocabStat(
  BuildContext context,
  String label,
  String value,
  IconData icon,
  Color color,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

// Updated Communication Styles section with clear explanations
Widget _buildCommunicationStylesSection(BuildContext context, Map<String, dynamic> communicationStyles) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'Communication Styles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showCommunicationStylesInfo(context),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Writing patterns and expression habits (averaged across all messages)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          
          // User Cards (same as before but with clearer labels)
          ...communicationStyles.entries.map((entry) {
            final userData = entry.value as Map<String, dynamic>;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Header with user info and style type
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          child: Text(
                            _getInitials(entry.key),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  userData['styleType'] ?? '',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Stats section with clearer labels
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // First row of stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildCleanStyleStat(
                                context,
                                'Avg Message Length',
                                '${userData['avgMessageLength']} chars',
                                Icons.text_fields,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildCleanStyleStat(
                                context,
                                'CAPS Usage',
                                '${userData['capsPercentage']}%',
                                Icons.format_size,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Second row of stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildCleanStyleStat(
                                context,
                                'Emojis per Message',
                                userData['emojisPerMessage'] ?? '0.0',
                                Icons.emoji_emotions,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildCleanStyleStat(
                                context,
                                'Long Messages',
                                '${userData['longMessagePercentage']}% (>100 chars)',
                                Icons.article,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ),
  );
}

// Info dialog for vocabulary analysis
void _showVocabularyAnalysisInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Vocabulary Analysis'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We analyze the complexity and richness of each person\'s vocabulary:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.chat_bubble_outline, 'Total Words Used', 'All words they\'ve written in the chat', Colors.blue),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.auto_awesome, 'Unique Words', 'Different words (without repetition)', Colors.purple),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.straighten, 'Average Word Length', 'How long their words are on average', Colors.orange),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.psychology, 'Complex Words', 'Percentage of sophisticated/long words (>6 letters)', Colors.red),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            const Text(
              'Vocabulary Types:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            
            _buildVocabTypeRow('Sophisticated Speaker 🎓', '80-100%', Colors.deepPurple),
            _buildVocabTypeRow('Articulate Communicator 💬', '65-79%', Colors.purple),
            _buildVocabTypeRow('Clear Expresser 🗣️', '50-64%', Colors.blue),
            _buildVocabTypeRow('Simple & Direct 🎯', '35-49%', Colors.teal),
            _buildVocabTypeRow('Standard Vocabulary 📝', '0-34%', Colors.orange),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    ),
  );
}

Widget _buildVocabTypeRow(String type, String range, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          type,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          range,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// Updated Communication Styles info dialog
void _showCommunicationStylesInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Communication Styles'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('We analyze how people write and express themselves:'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.text_fields, 'Average Message Length', 'Typical number of characters per message', Colors.blue),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.format_size, 'CAPS Usage', 'Percentage of CAPITAL LETTERS used', Colors.red),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.emoji_emotions, 'Emojis per Message', 'Average number of emojis used per message 😊', Colors.orange),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.article, 'Long Messages', 'Percentage of messages over 100 characters', Colors.green),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'All statistics are calculated as averages across all messages in the chat.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    ),
  );
}

  Color _getVocabularyColor(double score) {
    if (score > 80) return Colors.deepPurple;
    if (score > 65) return Colors.purple;
    if (score > 50) return Colors.blue;
    return Colors.teal;
  }

// Overall Trends Section
  Widget _buildOverallTrendsSection(
      BuildContext context, Map<String, dynamic> overallTrends) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Overall Evolution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getTrendColor(overallTrends['overallEvolution'] ?? '')
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getTrendColor(overallTrends['overallEvolution'] ?? '')
                      .withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTrendIcon(overallTrends['overallEvolution'] ?? ''),
                    color:
                        _getTrendColor(overallTrends['overallEvolution'] ?? ''),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overallTrends['overallEvolution'] ?? '',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text('Score: ${overallTrends['evolutionScore'] ?? 0}%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Key Trends:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...(overallTrends['keyTrends'] as List? ?? [])
                .map(
                  (trend) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.fiber_manual_record,
                            size: 8,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(trend)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Color _getTrendColor(String trend) {
    if (trend.contains('Positive')) return Colors.green;
    if (trend.contains('Concerning')) return Colors.red;
    if (trend.contains('Stable')) return Colors.blue;
    return Colors.grey;
  }

  IconData _getTrendIcon(String trend) {
    if (trend.contains('Positive')) return Icons.trending_up;
    if (trend.contains('Concerning')) return Icons.trending_down;
    if (trend.contains('Stable')) return Icons.trending_flat;
    return Icons.analytics;
  }

// Relationship Evolution Section
  Widget _buildRelationshipEvolutionSection(
      BuildContext context, Map<String, dynamic> relationshipEvolution) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relationship Evolution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        relationshipEvolution['relationshipTrend'] ?? '',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Spacer(),
                      Text(
                        'Change: ${relationshipEvolution['engagementChange'] ?? 0}%',
                        style: TextStyle(
                          color: _getChangeColor(double.tryParse(
                                  relationshipEvolution['engagementChange'] ??
                                      '0') ??
                              0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Initial'),
                            Text(
                              '${relationshipEvolution['initialEngagement'] ?? 0}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.primary),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Current'),
                            Text(
                              '${relationshipEvolution['currentEngagement'] ?? 0}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChangeColor(double change) {
    if (change > 0) return Colors.green;
    if (change < 0) return Colors.red;
    return Colors.grey;
  }

// Evolution Timeline Section
  
}

// features/analysis/analysis_ui.dart - PART 3
// All Chart Widgets, Card Components, and Enums

// Replace MessageCountChart with UserCardsList
class UserCardsList extends StatelessWidget {
  final Map<String, dynamic> data;

  const UserCardsList({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final perUser = data['perUser'] as Map<String, dynamic>? ?? {};

    // Filter out System user and sort by message count
    final filteredEntries = perUser.entries
        .where((entry) =>
            entry.key != "System" && entry.key.toLowerCase() != "system")
        .toList();

    filteredEntries.sort((a, b) => (b.value as int).compareTo(a.value as int));

    if (filteredEntries.isEmpty) {
      return const _PlaceholderCard(message: "No message data available");
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Messages per User',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${filteredEntries.length} participants in this chat',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 16),
            // User cards in a grid or list
            ...List.generate(filteredEntries.length, (index) {
              final entry = filteredEntries[index];
              final userName = entry.key;
              final messageCount = entry.value as int;
              final totalMessages = filteredEntries.fold<int>(
                  0, (sum, e) => sum + (e.value as int));
              final percentage = totalMessages > 0
                  ? ((messageCount / totalMessages) * 100).toStringAsFixed(1)
                  : '0';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildUserCard(
                  context,
                  userName,
                  messageCount,
                  percentage,
                  index,
                  filteredEntries.length,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    String userName,
    int messageCount,
    String percentage,
    int index,
    int totalUsers,
  ) {
    // Generate colors for each user
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];

    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$messageCount messages',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Percentage badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.split(' ');
    if (parts.length == 1) {
      return name.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _PlaceholderCard extends StatelessWidget {
  final String message;

  const _PlaceholderCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CHARTS
// ============================================================================

// Message Count Chart
// Fixed MessageCountChart - filters out System user and fixes name display
class MessageCountChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const MessageCountChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final perUser = data['perUser'] as Map<String, dynamic>? ?? {};

    // Filter out System user completely
    final filteredEntries = perUser.entries
        .where((entry) =>
            entry.key != "System" && entry.key.toLowerCase() != "system")
        .toList();

    filteredEntries.sort((a, b) => (b.value as int).compareTo(a.value as int));

    if (filteredEntries.isEmpty) {
      return const _PlaceholderCard(message: "No message data available");
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Messages per User',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: filteredEntries.isNotEmpty
                      ? (filteredEntries.first.value as int) * 1.2
                      : 10,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < filteredEntries.length) {
                            String name = filteredEntries[value.toInt()].key;

                            // Better name truncation - show more characters
                            if (name.length > 10) {
                              name = '${name.substring(0, 8)}...';
                            }

                            return Container(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Transform.rotate(
                                angle:
                                    -0.5, // Slight rotation for better readability
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (filteredEntries.isNotEmpty
                            ? (filteredEntries.first.value as int) / 5
                            : 10)
                        .toDouble(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: List.generate(
                    filteredEntries.length,
                    (index) {
                      final count = filteredEntries[index].value as int;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: count.toDouble(),
                            color: _getBarColor(
                                context, index, filteredEntries.length),
                            width: 24,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            // Add value on top of bar
                            rodStackItems: [],
                          ),
                        ],
                        showingTooltipIndicators: [0],
                      );
                    },
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Theme.of(context).colorScheme.surface,
                      tooltipBorder: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex < filteredEntries.length) {
                          final entry = filteredEntries[groupIndex];
                          return BarTooltipItem(
                            '${entry.key}\n${entry.value} messages',
                            TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Add legend below chart
            _buildChartLegend(context, filteredEntries),
          ],
        ),
      ),
    );
  }

  // Generate different colors for each bar
  Color _getBarColor(BuildContext context, int index, int total) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];

    return colors[index % colors.length];
  }

  // Build legend for the chart
  Widget _buildChartLegend(
      BuildContext context, List<MapEntry<String, dynamic>> entries) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participants (${entries.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(entries.length, (index) {
              final entry = entries[index];
              final color = _getBarColor(context, index, entries.length);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.key}: ${entry.value}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Time Distribution Chart
class TimeDistributionChart extends StatelessWidget {
  final Map<String, dynamic> data;
  final TimeDistributionType type;

  const TimeDistributionChart({
    Key? key,
    required this.data,
    required this.type,
  }) : super(key: key);

  factory TimeDistributionChart.dayOfWeek(Map<String, dynamic> data) {
    return TimeDistributionChart(
        data: data, type: TimeDistributionType.dayOfWeek);
  }

  factory TimeDistributionChart.hourOfDay(Map<String, dynamic> data) {
    return TimeDistributionChart(
        data: data, type: TimeDistributionType.hourOfDay);
  }

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case TimeDistributionType.dayOfWeek:
        return _buildDayOfWeekChart(context);
      case TimeDistributionType.hourOfDay:
        return _buildHourOfDayChart(context);
    }
  }

  Widget _buildDayOfWeekChart(BuildContext context) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final List<double> values =
        days.map((day) => (data[day] as int? ?? 0).toDouble()).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Activity by Day of Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue * 1.2,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                days[value.toInt()].substring(0, 3),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(
                    days.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index],
                          color: Theme.of(context).colorScheme.secondary,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourOfDayChart(BuildContext context) {
    final hours = List.generate(24, (i) => i.toString().padLeft(2, '0'));
    final List<double> values =
        hours.map((hour) => (data[hour] as int? ?? 0).toDouble()).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Activity by Hour of Day',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 23,
                  minY: 0,
                  maxY: maxValue * 1.2,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 4,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          if (hour % 4 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '$hour:00',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(
                      show: true,
                      horizontalInterval: 20,
                      drawVerticalLine: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(24,
                          (index) => FlSpot(index.toDouble(), values[index])),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Content Analysis Chart
// Enhanced ContentAnalysisChart with word cloud style display
class ContentAnalysisChart extends StatelessWidget {
  final List<dynamic> data;
  final ContentAnalysisType type;

  const ContentAnalysisChart({
    Key? key,
    required this.data,
    required this.type,
  }) : super(key: key);

  factory ContentAnalysisChart.topWords(List<dynamic> data) {
    return ContentAnalysisChart(data: data, type: ContentAnalysisType.words);
  }

  factory ContentAnalysisChart.topEmojis(List<dynamic> data) {
    return ContentAnalysisChart(data: data, type: ContentAnalysisType.emojis);
  }

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ContentAnalysisType.words:
        return _buildWordCloudView(context);
      case ContentAnalysisType.emojis:
        return _buildTopEmojisView(context);
    }
  }

  Widget _buildWordCloudView(BuildContext context) {
    final topWords = data.take(30).toList(); // Show top 30 words

    if (topWords.isEmpty) {
      return const _PlaceholderCard(message: "No word data available");
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Most Used Words',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Top ${topWords.length} words (common words filtered)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 16),
            _buildWordCloudLayout(context, topWords),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCloudLayout(BuildContext context, List<dynamic> words) {
    final maxCount = words.isNotEmpty ? words.first['count'] as int : 1;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: words.map((wordData) {
          final word = wordData['word'] as String;
          final count = wordData['count'] as int;
          final percentage = wordData['percentage'] as String? ?? '0';

          // Calculate font size based on word frequency (12-24 range)
          final fontSize = 12.0 + (12.0 * (count / maxCount));

          // Calculate opacity based on frequency
          final opacity = 0.6 + (0.4 * (count / maxCount));

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(opacity),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  word,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '$count ($percentage%)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopEmojisView(BuildContext context) {
    final topEmojis = data.take(24).toList(); // Show top 24 emojis in 4x6 grid

    if (topEmojis.isEmpty) {
      return const _PlaceholderCard(message: "No emojis found in this chat");
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_emotions,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Most Used Emojis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Top ${topEmojis.length} emojis used in conversations',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: topEmojis.length,
              itemBuilder: (context, index) {
                final emoji = topEmojis[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        emoji['emoji'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${emoji['count']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CARDS
// ============================================================================

// Summary Card
// Fixed SummaryCard with better date range display
class SummaryCard extends StatelessWidget {
  final int totalMessages;
  final int totalParticipants;
  final String dateRange;
  final double avgMessagesPerDay;

  const SummaryCard({
    Key? key,
    required this.totalMessages,
    required this.totalParticipants,
    required this.dateRange,
    required this.avgMessagesPerDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.summarize,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Chat Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildStatRow(context, 'Total Messages', totalMessages.toString(),
                  Icons.chat_bubble_outline),
              const SizedBox(height: 12),
              _buildStatRow(context, 'Participants',
                  totalParticipants.toString(), Icons.people_outline),
              const SizedBox(height: 12),
              _buildDateRangeRow(
                  context, 'Date Range', dateRange, Icons.calendar_today),
              const SizedBox(height: 12),
              _buildStatRow(context, 'Daily Average',
                  avgMessagesPerDay.toStringAsFixed(1), Icons.show_chart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDateRangeRow(
      BuildContext context, String label, String dateRange, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      dateRange,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Stats Card
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  const StatsCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// User Stats Card
class UserStatsCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> user;

  const UserStatsCard({
    Key? key,
    required this.title,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _getInitials(user['name'] ?? ''),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user['messageCount'] ?? 0} messages',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildStatChip(context, 'Words', '${user['wordCount'] ?? 0}',
                    Icons.text_fields),
                _buildStatChip(context, 'Media', '${user['mediaCount'] ?? 0}',
                    Icons.image),
                _buildStatChip(context, 'Emojis', '${user['emojiCount'] ?? 0}',
                    Icons.emoji_emotions),
                _buildStatChip(
                    context,
                    'Avg Length',
                    '${(user['avgMessageLength'] as double? ?? 0).toStringAsFixed(0)} chars',
                    Icons.text_snippet),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Avg Response Time: ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    _formatDuration(
                        user['avgResponseTimeSeconds'] as double? ?? 0),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.split(' ');
    if (parts.length == 1) {
      return name.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

// ============================================================================
// ENUMS
// ============================================================================
enum TimeDistributionType {
  dayOfWeek,
  hourOfDay,
}

enum ContentAnalysisType {
  words,
  emojis,
}
