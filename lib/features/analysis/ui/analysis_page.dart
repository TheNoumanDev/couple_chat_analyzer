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
import '../analysis_bloc.dart' show AnalysisBloc;
import '../../reports/reports_bloc.dart' show ReportsBloc;
import '../../reports/reports_models.dart' show GenerateReportEvent;
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
  
  // Static tracking to prevent duplicate initialization across widget rebuilds
  static final Set<String> _initializedChats = <String>{};
  static bool _isInitializing = false;
  
  // Cache for converted results to prevent duplicate conversion during build
  Map<String, dynamic>? _cachedConvertedResults;
  String? _cachedResultsChatId;
  
  // Flag to show overlay while tabs are building for the first time
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    debugPrint("AnalysisPage: initState called with chatId: ${widget.chatId}");

    // Prevent duplicate initialization across all widget instances using static tracking
    if (_initializedChats.contains(widget.chatId) || _isInitializing) {
      debugPrint("⚠️ AnalysisPage: Chat ${widget.chatId} already initialized or initializing, skipping");
      return;
    }

    _isInitializing = true;

    try {
      _analysisBloc = AnalysisBloc(analyzeChatUseCase: GetIt.instance.get());

      _reportBloc = ReportsBloc(
        generateReportUseCase: GetIt.instance.get(),
        shareReportUseCase: GetIt.instance.get(),
        deleteReportUseCase: GetIt.instance.get(),
        getReportHistoryUseCase: GetIt.instance.get(),
      );

      _tabController =
          TabController(length: 5, vsync: this); // Changed from 4 to 5

      // Mark this chat as initialized before starting analysis
      _initializedChats.add(widget.chatId);
      
      // Wait for next frame to ensure widget tree is built, then start analysis
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Check if bloc already has results or is loading before starting
          final currentState = _analysisBloc.state;
          if (currentState is models.AnalysisSuccess && 
              currentState.chatId == widget.chatId) {
            debugPrint("ℹ️ AnalysisPage: Analysis already completed, not starting again");
            _isInitializing = false;
            return;
          }
          if (currentState is models.AnalysisLoading) {
            debugPrint("ℹ️ AnalysisPage: Analysis already in progress, not starting again");
            _isInitializing = false;
            return;
          }
          
          // Start analysis - the bloc will emit loading state immediately
          _analysisBloc.add(models.StartAnalysisEvent(widget.chatId));
          debugPrint("✅ AnalysisPage: Analysis event sent for chat ${widget.chatId}");
          _isInitializing = false;
        }
      });
      
      debugPrint("✅ AnalysisPage initialized successfully");
    } catch (e, stackTrace) {
      debugPrint("❌ Error in AnalysisPage initState: $e");
      debugPrint("Stack trace: $stackTrace");
      _initializedChats.remove(widget.chatId); // Remove on error
      _isInitializing = false;
    }
  }

  @override
  void dispose() {
    debugPrint("AnalysisPage: dispose called for chat ${widget.chatId}");
    _analysisBloc.close();
    _reportBloc.close();
    _tabController.dispose();
    // Remove from initialized set when page is disposed
    _initializedChats.remove(widget.chatId);
    // Clear cache
    _cachedConvertedResults = null;
    _cachedResultsChatId = null;
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
              Tab(
                  icon: Icon(Icons.bug_report),
                  text: 'Debug'), // Added debug tab
            ],
          ),
          actions: [
            BlocBuilder<AnalysisBloc, models.AnalysisState>(
              builder: (context, state) {
                if (state is models.AnalysisSuccess) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Analysis',
                    onPressed: () {
                      _analysisBloc.add(models.RefreshAnalysisEvent(widget.chatId));
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<AnalysisBloc, models.AnalysisState>(
          builder: (context, state) {
            if (state is models.AnalysisLoading) {
              return LoadingIndicator(
                message: state.message,
              );
            }

            if (state is models.AnalysisError) {
              return _buildErrorView(context, state);
            }

            if (state is models.AnalysisSuccess) {
              // Use cached conversion or convert once
              Map<String, dynamic> results;
              if (_cachedResultsChatId == state.chatId && _cachedConvertedResults != null) {
                results = _cachedConvertedResults!;
                debugPrint("✅ Using cached converted results for ${state.chatId}");
              } else {
                // Convert and cache
                results = _convertAnalysisResultToMap(state.result);
                _cachedConvertedResults = results;
                _cachedResultsChatId = state.chatId;
                debugPrint("✅ Converted and cached results for ${state.chatId}");
              }

              // Check if we have any valid results (not just error)
              final hasErrorOnly = results.containsKey('error') && 
                                   results['error'] is Map && 
                                   (results['error'] as Map)['error'] == true;
              
              if (hasErrorOnly && !results.containsKey('summary')) {
                return _buildErrorView(
                    context,
                    models.AnalysisError(
                        "Analysis failed. ${(results['error'] as Map?)?['errorMessage'] ?? 'Unknown error'}"));
              }

              // If we have partial results (some analyzers succeeded), show them
              // Generate minimal summary if missing
              if (!results.containsKey('summary') && !hasErrorOnly) {
                // Try to generate a basic summary from available data
                results['summary'] = _generateMinimalSummary(state.result);
              }

              // Defer tab building to next frame to prevent ANR
              if (_isFirstBuild) {
                _isFirstBuild = false;
                // Schedule tab building for next frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {}); // Trigger rebuild to show tabs
                  }
                });
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Preparing results...'),
                    ],
                  ),
                );
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

            // If we reach here, state is AnalysisInitial
            // This shouldn't happen after initState, but show loading as fallback
            return const LoadingIndicator(
              message: 'Initializing analysis...',
            );
          },
        ),
        floatingActionButton: BlocBuilder<AnalysisBloc, models.AnalysisState>(
          builder: (context, state) {
            if (state is models.AnalysisSuccess) {
              // Use cached results
              final results = _cachedConvertedResults ?? _convertAnalysisResultToMap(state.result);
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

  Widget _buildErrorView(BuildContext context, models.AnalysisError state) {
    return ErrorView(
      title: 'Analysis Failed',
      message: state.message,
      technicalDetails: state.technicalDetails,
      onRetry: () {
        _analysisBloc.add(models.StartAnalysisEvent(widget.chatId));
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
  Map<String, dynamic> _convertAnalysisResultToMap(
      models.ChatAnalysisResult result) {
    final combinedResults = <String, dynamic>{};

    debugPrint(
        "🔄 Converting analysis result with ${result.results.length} entries:");

    // Process each analyzer result
    for (final entry in result.results.entries) {
      final analyzerKey = entry.key; // e.g., 'content'
      final analysisResult = entry.value; // AnalysisResult object

      debugPrint("  - Processing $analyzerKey: type=${analysisResult.type}");
      debugPrint("    Data keys: ${analysisResult.data.keys.join(', ')}");

      // Store the analyzer result under its key
      combinedResults[analyzerKey] = analysisResult.data;

      // ENHANCED: Also merge data contents at root level for backward compatibility
      // This ensures widgets that expect data at root level still work
      for (final dataEntry in analysisResult.data.entries) {
        if (!combinedResults.containsKey(dataEntry.key)) {
          combinedResults[dataEntry.key] = dataEntry.value;
          debugPrint("    ✅ Merged '${dataEntry.key}' to root level");
        } else {
          debugPrint(
              "    ⚠️ Skipped '${dataEntry.key}' (already exists at root)");
        }
      }
    }

    debugPrint("🎯 Final combined results structure:");
    debugPrint("  All keys: ${combinedResults.keys.toList()}");

    // Enhanced debugging: Show the structure of content-related data
    if (combinedResults.containsKey('content')) {
      final contentData = combinedResults['content'];
      if (contentData is Map) {
        debugPrint("📊 Content analyzer data structure:");
        debugPrint("  Content keys: ${contentData.keys.join(', ')}");

        // Show specific content analysis structure
        contentData.forEach((key, value) {
          if (value is Map) {
            debugPrint(
                "    $key -> Map with ${value.keys.length} keys");
          } else if (value is List) {
            debugPrint("    $key -> List with ${value.length} items");
          } else {
            debugPrint("    $key -> ${value.runtimeType}: $value");
          }
        });
      }
    }

    // Check for direct contentAnalysis key
    if (combinedResults.containsKey('contentAnalysis')) {
      final contentAnalysisData = combinedResults['contentAnalysis'];
      if (contentAnalysisData is Map) {
        debugPrint(
            "📋 Direct contentAnalysis found with keys: ${contentAnalysisData.keys.join(', ')}");
      }
    }

    // Verify the analyzer keys are present
    final expectedKeys = [
      'content',
      'conversationDynamics',
      'behaviorPatterns',
      'relationshipDynamics',
      'contentIntelligence',
      'temporalInsights'
    ];
    final presentKeys =
        expectedKeys.where((key) => combinedResults.containsKey(key)).toList();
    debugPrint("✅ Present analyzer keys: $presentKeys");

    // Debug: Print the actual structure of each analyzer's data
    for (final key in expectedKeys) {
      if (combinedResults.containsKey(key)) {
        final data = combinedResults[key];
        if (data is Map) {
          debugPrint(
              "📊 $key data structure: ${data.keys.join(', ')}");
        } else {
          debugPrint("📊 $key data type: ${data.runtimeType}");
        }
      }
    }

    return combinedResults;
  }

  /// Generate a minimal summary from available analysis results
  Map<String, dynamic> _generateMinimalSummary(models.ChatAnalysisResult result) {
    // Try to extract summary from messages analyzer
    if (result.results.containsKey('messages') && 
        result.results['messages']!.data.containsKey('summary')) {
      return result.results['messages']!.data['summary'] as Map<String, dynamic>;
    }

    // Try to extract from error result
    if (result.results.containsKey('error') && 
        result.results['error']!.data.containsKey('summary')) {
      return result.results['error']!.data['summary'] as Map<String, dynamic>;
    }

    // Generate minimal summary from available data
    int totalMessages = 0;
    int totalUsers = 0;
    
    if (result.results.containsKey('messages')) {
      final messagesData = result.results['messages']!.data;
      if (messagesData.containsKey('summary')) {
        final summary = messagesData['summary'] as Map<String, dynamic>?;
        totalMessages = summary?['totalMessages'] as int? ?? 0;
        totalUsers = summary?['totalUsers'] as int? ?? 0;
      }
    }

    return {
      'totalMessages': totalMessages,
      'totalUsers': totalUsers,
      'dateRange': 'Unknown',
      'avgMessagesPerDay': '0',
      'totalMedia': 0,
      'durationDays': 0,
      'status': 'Partial analysis - some analyzers may have failed',
    };
  }
}
