import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../widgets/common.dart';
import '../../reports/reports_ui.dart';
import '../../reports/reports_feature.dart';
import '../analysis_bloc.dart';
import '../analysis_events.dart';
import '../analysis_states.dart';
import 'tabs/overview_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/time_tab.dart';
import 'tabs/content_tab.dart';
import 'tabs/conversations_tab.dart';
import 'tabs/behavior_tab.dart';
import 'tabs/relationship_tab.dart';
import 'tabs/intelligence_tab.dart';
import 'tabs/evolution_tab.dart';

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
      _tabController = TabController(length: 9, vsync: this);

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
                message: 'Analyzing your chat data...\nThis may take a moment for large chats',
              );
            }

            if (state is AnalysisError) {
              return _buildErrorView(context, state);
            }

            if (state is AnalysisSuccess) {
              if (!state.results.containsKey('summary')) {
                return _buildErrorView(
                    context,
                    const AnalysisError("Analysis results incomplete. Missing summary data."));
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  OverviewTab(results: state.results),
                  UsersTab(results: state.results),
                  TimeTab(results: state.results),
                  ContentTab(results: state.results),
                  ConversationsTab(results: state.results),
                  BehaviorTab(results: state.results),
                  RelationshipTab(results: state.results),
                  IntelligenceTab(results: state.results),
                  EvolutionTab(results: state.results),
                ],
              );
            }

            return const Center(
              child: Text('Ready to analyze'),
            );
          },
        ),
        floatingActionButton: BlocBuilder<AnalysisBloc, AnalysisState>(
          builder: (context, state) {
            if (state is AnalysisSuccess) {
              return FloatingActionButton.extended(
                onPressed: () => _generateReport(context, state.results),
                icon: const Icon(Icons.file_download),
                label: const Text('Generate Report'),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, AnalysisError state) {
    return ErrorView(
      title: 'Analysis Failed',
      message: state.message,
      onRetry: () {
        _analysisBloc.add(AnalyzeChatEvent(widget.chatId));
      },
    );
  }

  void _generateReport(BuildContext context, Map<String, dynamic> results) {
    _reportBloc.add(GenerateReportEvent(widget.chatId, results));
    
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _reportBloc,
        child: const ReportGenerationDialog(),
      ),
    );
  }
}