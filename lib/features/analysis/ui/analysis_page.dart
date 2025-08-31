// ============================================================================
// FILE: features/analysis/ui/analysis_page.dart
// Fixed analysis page with correct data extraction
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../widgets/common.dart';
import '../../reports/reports_bloc.dart';
import '../../reports/reports_ui.dart';
import '../analysis_bloc.dart';
import '../analysis_models.dart' as models;
import 'tabs/overview_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/content_tab.dart';
import 'tabs/insights_tab.dart';
import 'tabs/debug_tab.dart'; // Added debug tab import

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
  late ReportsBloc _reportBloc;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    debugPrint("AnalysisPage: initState called with chatId: ${widget.chatId}");

    try {
      _analysisBloc = AnalysisBloc(analyzeChatUseCase: GetIt.instance.get());
      
      _reportBloc = ReportsBloc(
        generateReportUseCase: GetIt.instance.get(),
        shareReportUseCase: GetIt.instance.get(),
        deleteReportUseCase: GetIt.instance.get(),
        getReportHistoryUseCase: GetIt.instance.get(),
      );
      
      _tabController = TabController(length: 5, vsync: this); // Changed from 4 to 5

      _analysisBloc.add(StartAnalysisEvent(widget.chatId));
      debugPrint("✅ AnalysisPage initialized successfully");
    } catch (e, stackTrace) {
      debugPrint("❌ Error in AnalysisPage initState: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  @override
  void dispose() {
    debugPrint("AnalysisPage: dispose called");
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
            isScrollable: true, // Changed to scrollable for 5 tabs
            tabs: const [
              Tab(icon: Icon(Icons.summarize), text: 'Overview'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.analytics), text: 'Content'),
              Tab(icon: Icon(Icons.psychology), text: 'Insights'),
              Tab(icon: Icon(Icons.bug_report), text: 'Debug'), // Added debug tab
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
                      _analysisBloc.add(RefreshAnalysisEvent(widget.chatId));
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
              return LoadingIndicator(
                message: state.message,
              );
            }

            if (state is AnalysisError) {
              return _buildErrorView(context, state);
            }

            if (state is AnalysisSuccess) {
              // Fixed: Convert ChatAnalysisResult to Map with proper structure
              final results = _convertAnalysisResultToMap(state.result);
              
              if (!results.containsKey('summary')) {
                return _buildErrorView(
                    context,
                    const AnalysisError(message: "Analysis results incomplete. Missing summary data."));
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  OverviewTab(results: results),
                  UsersTab(results: results),
                  ContentTab(results: results),
                  InsightsTab(results: results),
                  DebugTab(results: results), // Added debug tab
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
              final results = _convertAnalysisResultToMap(state.result);
              return FloatingActionButton.extended(
                onPressed: () => _generateReport(context, results),
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
      technicalDetails: state.technicalDetails,
      onRetry: () {
        _analysisBloc.add(StartAnalysisEvent(widget.chatId));
      },
    );
  }

  void _generateReport(BuildContext context, Map<String, dynamic> results) {
    _reportBloc.add(GenerateReportEvent(
      chatId: widget.chatId, 
      analysisResults: results,
    ));
    
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _reportBloc,
        child: const ReportGenerationDialog(),
      ),
    );
  }

  /// Convert ChatAnalysisResult to Map for backward compatibility with UI
  /// FIXED: Preserve analyzer keys while extracting data properly
  Map<String, dynamic> _convertAnalysisResultToMap(models.ChatAnalysisResult result) {
    final combinedResults = <String, dynamic>{};
    
    debugPrint("🔍 Converting analysis result with ${result.results.length} entries:");
    
    // Process each analyzer result
    for (final entry in result.results.entries) {
      final analyzerKey = entry.key;       // e.g., 'conversationDynamics'
      final analysisResult = entry.value;  // AnalysisResult object
      
      debugPrint("  - Processing $analyzerKey: type=${analysisResult.type}");
      debugPrint("    Data keys: ${analysisResult.data.keys.join(', ')}");
      
      // Simply store the data under the analyzer key - this is what the UI expects
      combinedResults[analyzerKey] = analysisResult.data;
      
      // ALSO: For backward compatibility, merge the data contents at root level
      // This ensures widgets that expect data at root level still work
      for (final dataEntry in analysisResult.data.entries) {
        if (!combinedResults.containsKey(dataEntry.key)) {
          combinedResults[dataEntry.key] = dataEntry.value;
        }
      }
    }
    
    debugPrint("🔍 Final combined results structure:");
    debugPrint("  All keys: ${combinedResults.keys.toList()}");
    
    // Verify the analyzer keys are present
    final expectedKeys = ['conversationDynamics', 'behaviorPatterns', 'relationshipDynamics', 'contentIntelligence', 'temporalInsights'];
    final presentKeys = expectedKeys.where((key) => combinedResults.containsKey(key)).toList();
    debugPrint("✅ Present analyzer keys: $presentKeys");
    
    // Debug: Print the actual structure of each analyzer's data
    for (final key in expectedKeys) {
      if (combinedResults.containsKey(key)) {
        final data = combinedResults[key];
        if (data is Map) {
          debugPrint("📊 $key data structure: ${(data as Map).keys.join(', ')}");
        } else {
          debugPrint("📊 $key data type: ${data.runtimeType}");
        }
      }
    }
    
    return combinedResults;
  }
}