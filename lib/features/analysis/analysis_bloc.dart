// ============================================================================
// FILE: features/analysis/analysis_bloc.dart
// Analysis BLoC - State management for chat analysis
// ============================================================================
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'analysis_use_cases.dart';
import 'analysis_repository.dart';
import 'analysis_models.dart' show AnalysisEvent, AnalysisState, StartAnalysisEvent, RefreshAnalysisEvent, ClearAnalysisEvent, UpdateAnalysisConfigEvent, AnalysisInitial, AnalysisLoading, AnalysisSuccess, AnalysisError, AnalysisConfig, ChatAnalysisResult;

// ============================================================================
// ANALYSIS BLOC
// ============================================================================
class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final AnalyzeChatUseCase _analyzeChatUseCase;
  final AnalysisRepository _analysisRepository;

  // Current analysis tracking
  String? _currentChatId;
  StreamSubscription<double>? _progressSubscription;

  // Static set to track currently analyzing chat IDs across all bloc instances.
  // Thread-safety note: This is safe because BLoC events are always processed
  // on the main isolate. The analysis work runs in separate isolates via compute(),
  // but the state tracking happens only on the main isolate through event handlers.
  static final Set<String> _analyzingChatIds = <String>{};

  AnalysisBloc({
    required AnalyzeChatUseCase analyzeChatUseCase,
    required AnalysisRepository analysisRepository,
  }) : _analyzeChatUseCase = analyzeChatUseCase,
       _analysisRepository = analysisRepository,
       super(AnalysisInitial()) {
    
    // Register event handlers
    on<StartAnalysisEvent>(_onStartAnalysis);
    on<RefreshAnalysisEvent>(_onRefreshAnalysis);
    on<ClearAnalysisEvent>(_onClearAnalysis);
    on<UpdateAnalysisConfigEvent>(_onUpdateAnalysisConfig);
  }

  // ========================================================================
  // EVENT HANDLERS
  // ========================================================================

  /// Handle starting a new analysis
  Future<void> _onStartAnalysis(
    StartAnalysisEvent event,
    Emitter<AnalysisState> emit,
  ) async {
    // CRITICAL: Emit loading state IMMEDIATELY to prevent UI from blocking
    // This must happen before any async operations so UI can update
    emit(const AnalysisLoading(message: 'Loading analysis...'));
    
    // Yield control immediately to allow UI to render loading state
    await Future.delayed(Duration.zero);
    
    // If we already have results for this chat in current state, use them
    if (state is AnalysisSuccess && 
        _currentChatId == event.chatId && 
        event.config == null) {
      debugPrint("ℹ️ Analysis already completed for chat: ${event.chatId}, use RefreshAnalysisEvent to re-analyze");
      return; // State already has results, no need to change
    }
    
    // Prevent duplicate analysis - use atomic check-and-set pattern
    // Try to add chatId to set - if it already exists, analysis is in progress
    final wasAlreadyAnalyzing = !_analyzingChatIds.add(event.chatId);
    
    if (wasAlreadyAnalyzing) {
      debugPrint("⚠️ Analysis already in progress for chat: ${event.chatId}, checking for existing results...");
      emit(const AnalysisLoading(message: 'Checking for existing results...'));
      await Future.delayed(Duration.zero);
      
      // Try to load existing results from repository directly (don't trigger new analysis)
      try {
        final existingResults = await _analysisRepository.getAnalysisResults(event.chatId);
        if (existingResults != null && existingResults.isNotEmpty) {
          debugPrint("✅ Found existing results, loading them...");
          emit(AnalysisSuccess(
            chatId: event.chatId,
            result: existingResults,
            completedAt: DateTime.now(),
          ));
          _currentChatId = event.chatId;
          return;
        }
      } catch (e) {
        debugPrint("⚠️ Could not load existing results: $e");
      }
      // If no existing results, keep showing loading state
      emit(const AnalysisLoading(message: 'Analysis in progress, please wait...'));
      return;
    }
    
    // Prevent duplicate analysis if already running in this bloc instance
    if (_currentChatId == event.chatId && state is AnalysisLoading) {
      debugPrint("⚠️ Analysis already in progress for chat: ${event.chatId}, ignoring duplicate request");
      _analyzingChatIds.remove(event.chatId); // Remove since we're not starting
      return; // Already showing loading state
    }
    
    debugPrint("🔍 Starting analysis for chat: ${event.chatId}");
    
    _currentChatId = event.chatId;
    // chatId already added to _analyzingChatIds above
    
    // Update loading message before starting heavy work
    emit(const AnalysisLoading(message: 'Initializing analysis...'));
    await Future.delayed(Duration.zero);

    try {
      // Start the analysis with progress tracking
      await _performAnalysis(event.chatId, event.config, emit);
      
    } catch (e, stackTrace) {
      debugPrint("❌ Analysis failed: $e");
      debugPrint("Stack trace: $stackTrace");
      
      emit(AnalysisError(
        _getUserFriendlyErrorMessage(e),
        technicalDetails: e.toString(),
        canRetry: _canRetryError(e),
      ));
    }
  }

  /// Handle refreshing an existing analysis
  Future<void> _onRefreshAnalysis(
    RefreshAnalysisEvent event,
    Emitter<AnalysisState> emit,
  ) async {
    debugPrint("🔄 Refreshing analysis for chat: ${event.chatId}");
    
    // Force refresh by clearing cache (if implemented)
    emit(const AnalysisLoading(message: 'Refreshing analysis...'));
    
    try {
      await _performAnalysis(event.chatId, null, emit, forceRefresh: true);
    } catch (e) {
      emit(AnalysisError(
        _getUserFriendlyErrorMessage(e),
        technicalDetails: e.toString(),
      ));
    }
  }

  /// Handle clearing analysis state
  Future<void> _onClearAnalysis(
    ClearAnalysisEvent event,
    Emitter<AnalysisState> emit,
  ) async {
    debugPrint("🧹 Clearing analysis state");
    
    _currentChatId = null;
    _progressSubscription?.cancel();
    _progressSubscription = null;
    
    emit(AnalysisInitial());
  }

  /// Handle updating analysis configuration
  Future<void> _onUpdateAnalysisConfig(
    UpdateAnalysisConfigEvent event,
    Emitter<AnalysisState> emit,
  ) async {
    debugPrint("⚙️ Updating analysis configuration");
    
    // If we have a current analysis, restart it with new config
    if (_currentChatId != null) {
      add(StartAnalysisEvent(_currentChatId!, config: event.config));
    }
  }

  // ========================================================================
  // ANALYSIS EXECUTION
  // ========================================================================

  /// Perform the actual analysis with progress tracking
  Future<void> _performAnalysis(
    String chatId,
    AnalysisConfig? config,
    Emitter<AnalysisState> emit, {
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Execute the analysis
      final result = await _analyzeChatUseCase.execute(
        chatId: chatId,
        config: config ?? AnalysisConfig.defaultConfig(),
        forceRefresh: forceRefresh,
      );

      stopwatch.stop();
      debugPrint("✅ Analysis completed in ${stopwatch.elapsedMilliseconds}ms");

      _analyzingChatIds.remove(chatId); // Remove from tracking set
      
      emit(AnalysisSuccess(
        chatId: chatId,
        result: result,
        completedAt: DateTime.now(),
      ));

    } catch (e) {
      stopwatch.stop();
      debugPrint("❌ Analysis failed after ${stopwatch.elapsedMilliseconds}ms: $e");
      _analyzingChatIds.remove(chatId); // Remove from tracking set on error
      rethrow;
    }
  }

  // ========================================================================
  // ERROR HANDLING
  // ========================================================================

  /// Convert technical errors to user-friendly messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('chat not found')) {
      return 'The chat could not be found. Please try importing it again.';
    } else if (errorString.contains('insufficient data')) {
      return 'Not enough data in the chat to perform analysis.';
    } else if (errorString.contains('memory')) {
      return 'The chat is too large to analyze. Please try with a smaller chat file.';
    } else if (errorString.contains('timeout')) {
      return 'Analysis is taking too long. Please try again.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error occurred. Please check your connection and try again.';
    } else {
      return 'An unexpected error occurred during analysis.';
    }
  }

  /// Determine if an error can be retried
  bool _canRetryError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Don't retry for data-related errors
    if (errorString.contains('chat not found') ||
        errorString.contains('insufficient data') ||
        errorString.contains('invalid format')) {
      return false;
    }
    
    // Retry for temporary errors
    return true;
  }

  // ========================================================================
  // GETTERS
  // ========================================================================

  /// Get current chat ID being analyzed
  String? get currentChatId => _currentChatId;

  /// Check if analysis is currently running
  bool get isAnalyzing => state is AnalysisLoading;

  /// Get the last successful analysis result
  ChatAnalysisResult? get lastResult {
    final currentState = state;
    if (currentState is AnalysisSuccess) {
      return currentState.result;
    }
    return null;
  }

  // ========================================================================
  // CLEANUP
  // ========================================================================

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    // Clean up tracking if this bloc was analyzing
    if (_currentChatId != null) {
      _analyzingChatIds.remove(_currentChatId);
    }
    return super.close();
  }
}