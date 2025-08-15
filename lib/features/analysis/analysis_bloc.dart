// ============================================================================
// FILE: features/analysis/analysis_bloc.dart
// Analysis BLoC - State management for chat analysis
// ============================================================================
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'analysis_use_cases.dart';
import 'analysis_models.dart';

// ============================================================================
// ANALYSIS EVENTS
// ============================================================================
abstract class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object?> get props => [];
}

class StartAnalysisEvent extends AnalysisEvent {
  final String chatId;
  final AnalysisConfig? config;

  const StartAnalysisEvent(this.chatId, {this.config});

  @override
  List<Object?> get props => [chatId, config];
}

class RefreshAnalysisEvent extends AnalysisEvent {
  final String chatId;

  const RefreshAnalysisEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class ClearAnalysisEvent extends AnalysisEvent {}

class UpdateAnalysisConfigEvent extends AnalysisEvent {
  final AnalysisConfig config;

  const UpdateAnalysisConfigEvent(this.config);

  @override
  List<Object?> get props => [config];
}

// ============================================================================
// ANALYSIS STATES
// ============================================================================
abstract class AnalysisState extends Equatable {
  const AnalysisState();
  
  @override
  List<Object?> get props => [];
}

class AnalysisInitial extends AnalysisState {}

class AnalysisLoading extends AnalysisState {
  final String message;
  final double? progress;

  const AnalysisLoading({
    this.message = 'Analyzing chat...',
    this.progress,
  });

  @override
  List<Object?> get props => [message, progress];
}

class AnalysisSuccess extends AnalysisState {
  final String chatId;
  final ChatAnalysisResult result;
  final DateTime completedAt;

  const AnalysisSuccess({
    required this.chatId,
    required this.result,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [chatId, result, completedAt];
}

class AnalysisError extends AnalysisState {
  final String message;
  final String? technicalDetails;
  final bool canRetry;

  const AnalysisError({
    required this.message,
    this.technicalDetails,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, technicalDetails, canRetry];
}

// ============================================================================
// ANALYSIS BLOC
// ============================================================================
class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final AnalyzeChatUseCase _analyzeChatUseCase;
  
  // Current analysis tracking
  String? _currentChatId;
  StreamSubscription<double>? _progressSubscription;

  AnalysisBloc({
    required AnalyzeChatUseCase analyzeChatUseCase,
  }) : _analyzeChatUseCase = analyzeChatUseCase,
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
    debugPrint("🔍 Starting analysis for chat: ${event.chatId}");
    
    _currentChatId = event.chatId;
    emit(const AnalysisLoading(message: 'Initializing analysis...'));

    try {
      // Start the analysis with progress tracking
      await _performAnalysis(event.chatId, event.config, emit);
      
    } catch (e, stackTrace) {
      debugPrint("❌ Analysis failed: $e");
      debugPrint("Stack trace: $stackTrace");
      
      emit(AnalysisError(
        message: _getUserFriendlyErrorMessage(e),
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
        message: _getUserFriendlyErrorMessage(e),
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
      // Update progress through different analysis phases
      emit(const AnalysisLoading(
        message: 'Loading chat data...',
        progress: 0.1,
      ));

      emit(const AnalysisLoading(
        message: 'Analyzing message patterns...',
        progress: 0.3,
      ));

      emit(const AnalysisLoading(
        message: 'Processing user behavior...',
        progress: 0.5,
      ));

      emit(const AnalysisLoading(
        message: 'Generating insights...',
        progress: 0.7,
      ));

      // Execute the analysis
      final result = await _analyzeChatUseCase.execute(
        chatId: chatId,
        config: config ?? AnalysisConfig.defaultConfig(),
        forceRefresh: forceRefresh,
      );

      emit(const AnalysisLoading(
        message: 'Finalizing results...',
        progress: 0.9,
      ));

      stopwatch.stop();
      debugPrint("✅ Analysis completed in ${stopwatch.elapsedMilliseconds}ms");

      emit(AnalysisSuccess(
        chatId: chatId,
        result: result,
        completedAt: DateTime.now(),
      ));

    } catch (e) {
      stopwatch.stop();
      debugPrint("❌ Analysis failed after ${stopwatch.elapsedMilliseconds}ms: $e");
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
    return super.close();
  }
}