import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'analysis_events.dart';
import 'analysis_states.dart';
import 'analysis_use_cases.dart';

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final AnalyzeChatUseCase analyzeChatUseCase;

  AnalysisBloc({
    required this.analyzeChatUseCase,
  }) : super(AnalysisInitial()) {
    on<AnalyzeChatEvent>(_onAnalyzeChat);
  }

  /// Handle chat analysis event
  Future<void> _onAnalyzeChat(
      AnalyzeChatEvent event, Emitter<AnalysisState> emit) async {
    debugPrint("AnalysisBloc: Starting analysis for chat ID: ${event.chatId}");
    emit(AnalysisLoading());

    try {
      debugPrint("AnalysisBloc: Calling analyzeChatUseCase");
      final results = await analyzeChatUseCase(event.chatId);

      // Debug log the results structure
      debugPrint(
          "AnalysisBloc: Analysis completed with result keys: ${results.keys.toList()}");

      // Validate results
      if (results.isEmpty) {
        debugPrint("AnalysisBloc: Empty results returned");
        emit(AnalysisError("No analysis results available"));
        return;
      }

      // Check for error in results
      if (results.containsKey('error')) {
        debugPrint(
            "AnalysisBloc: Error in analysis results: ${results['error']}");
        emit(AnalysisError("Analysis failed: ${results['error']}"));
        return;
      }

      // Ensure we have essential data
      if (!results.containsKey('summary')) {
        debugPrint("AnalysisBloc: Missing summary in results");
        emit(AnalysisError("Analysis incomplete: Missing summary data"));
        return;
      }

      debugPrint("AnalysisBloc: Emitting AnalysisSuccess state");
      emit(AnalysisSuccess(event.chatId, results));
    } catch (e, stackTrace) {
      debugPrint("AnalysisBloc: Analysis failed with error: $e");
      debugPrint("AnalysisBloc: Stack trace: $stackTrace");
      emit(AnalysisError("Analysis failed: ${e.toString()}"));
    }
  }
}