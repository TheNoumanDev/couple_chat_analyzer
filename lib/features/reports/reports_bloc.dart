// ============================================================================
// FILE: features/reports/reports_bloc.dart
// Reports BLoC - State management for report generation
// ============================================================================
import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'reports_models.dart';
import 'reports_use_cases.dart';

// ============================================================================
// REPORTS EVENTS
// ============================================================================
abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class GenerateReportEvent extends ReportsEvent {
  final String chatId;
  final Map<String, dynamic> analysisResults;
  final ReportConfig? config;

  const GenerateReportEvent({
    required this.chatId,
    required this.analysisResults,
    this.config,
  });

  @override
  List<Object?> get props => [chatId, analysisResults, config];
}

class ShareReportEvent extends ReportsEvent {
  final File reportFile;

  const ShareReportEvent(this.reportFile);

  @override
  List<Object?> get props => [reportFile];
}

class DeleteReportEvent extends ReportsEvent {
  final String reportPath;

  const DeleteReportEvent(this.reportPath);

  @override
  List<Object?> get props => [reportPath];
}

class ClearReportsEvent extends ReportsEvent {}

class GetReportHistoryEvent extends ReportsEvent {}

// ============================================================================
// REPORTS STATES
// ============================================================================
abstract class ReportsState extends Equatable {
  const ReportsState();
  
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {
  final String message;
  final double? progress;

  const ReportsLoading({
    this.message = 'Generating report...',
    this.progress,
  });

  @override
  List<Object?> get props => [message, progress];
}

class ReportGenerated extends ReportsState {
  final File reportFile;
  final ReportMetadata metadata;

  const ReportGenerated({
    required this.reportFile,
    required this.metadata,
  });

  @override
  List<Object?> get props => [reportFile, metadata];
}

class ReportShared extends ReportsState {
  final String message;

  const ReportShared(this.message);

  @override
  List<Object?> get props => [message];
}

class ReportHistoryLoaded extends ReportsState {
  final List<ReportMetadata> reports;

  const ReportHistoryLoaded(this.reports);

  @override
  List<Object?> get props => [reports];
}

class ReportsError extends ReportsState {
  final String message;
  final String? technicalDetails;

  const ReportsError({
    required this.message,
    this.technicalDetails,
  });

  @override
  List<Object?> get props => [message, technicalDetails];
}

// ============================================================================
// REPORTS BLOC
// ============================================================================
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GenerateReportUseCase _generateReportUseCase;
  final ShareReportUseCase _shareReportUseCase;
  final DeleteReportUseCase _deleteReportUseCase;
  final GetReportHistoryUseCase _getReportHistoryUseCase;

  ReportsBloc({
    required GenerateReportUseCase generateReportUseCase,
    required ShareReportUseCase shareReportUseCase,
    required DeleteReportUseCase deleteReportUseCase,
    required GetReportHistoryUseCase getReportHistoryUseCase,
  }) : _generateReportUseCase = generateReportUseCase,
       _shareReportUseCase = shareReportUseCase,
       _deleteReportUseCase = deleteReportUseCase,
       _getReportHistoryUseCase = getReportHistoryUseCase,
       super(ReportsInitial()) {
    
    // Register event handlers
    on<GenerateReportEvent>(_onGenerateReport);
    on<ShareReportEvent>(_onShareReport);
    on<DeleteReportEvent>(_onDeleteReport);
    on<ClearReportsEvent>(_onClearReports);
    on<GetReportHistoryEvent>(_onGetReportHistory);
  }

  // ========================================================================
  // EVENT HANDLERS
  // ========================================================================

  /// Handle report generation
  Future<void> _onGenerateReport(
    GenerateReportEvent event,
    Emitter<ReportsState> emit,
  ) async {
    debugPrint("📄 Starting report generation for chat: ${event.chatId}");
    
    emit(const ReportsLoading(message: 'Preparing report data...'));

    try {
      // Validate input data
      if (event.analysisResults.isEmpty) {
        throw Exception('No analysis results available for report generation');
      }

      emit(const ReportsLoading(
        message: 'Generating report content...',
        progress: 0.3,
      ));

      // Generate the report using the use case
      final reportResult = await _generateReportUseCase.execute(
        chatId: event.chatId,
        analysisResults: event.analysisResults,
        config: event.config ?? ReportConfig.defaultConfig(),
      );

      emit(const ReportsLoading(
        message: 'Finalizing report...',
        progress: 0.9,
      ));

      debugPrint("✅ Report generated successfully: ${reportResult.file.path}");

      emit(ReportGenerated(
        reportFile: reportResult.file,
        metadata: reportResult.metadata,
      ));

    } catch (e, stackTrace) {
      debugPrint("❌ Report generation failed: $e");
      debugPrint("Stack trace: $stackTrace");
      
      emit(ReportsError(
        message: _getUserFriendlyErrorMessage(e),
        technicalDetails: e.toString(),
      ));
    }
  }

  /// Handle report sharing
  Future<void> _onShareReport(
    ShareReportEvent event,
    Emitter<ReportsState> emit,
  ) async {
    debugPrint("📤 Sharing report: ${event.reportFile.path}");
    
    emit(const ReportsLoading(message: 'Preparing to share...'));

    try {
      final result = await _shareReportUseCase.execute(event.reportFile);
      
      debugPrint("✅ Report shared successfully");
      emit(ReportShared(result.message));
      
    } catch (e, stackTrace) {
      debugPrint("❌ Report sharing failed: $e");
      debugPrint("Stack trace: $stackTrace");
      
      emit(ReportsError(
        message: 'Failed to share report: ${e.toString()}',
        technicalDetails: e.toString(),
      ));
    }
  }

  /// Handle report deletion
  Future<void> _onDeleteReport(
    DeleteReportEvent event,
    Emitter<ReportsState> emit,
  ) async {
    debugPrint("🗑️ Deleting report: ${event.reportPath}");
    
    try {
      await _deleteReportUseCase.execute(event.reportPath);
      
      debugPrint("✅ Report deleted successfully");
      
      // Refresh the report history
      add(GetReportHistoryEvent());
      
    } catch (e, stackTrace) {
      debugPrint("❌ Report deletion failed: $e");
      debugPrint("Stack trace: $stackTrace");
      
      emit(ReportsError(
        message: 'Failed to delete report: ${e.toString()}',
        technicalDetails: e.toString(),
      ));
    }
  }

  /// Handle clearing all reports
  Future<void> _onClearReports(
    ClearReportsEvent event,
    Emitter<ReportsState> emit,
  ) async {
    debugPrint("🧹 Clearing all reports");
    
    emit(const ReportsLoading(message: 'Clearing reports...'));

    try {
      // Get all reports and delete them
      final reports = await _getReportHistoryUseCase.execute();
      
      for (final report in reports) {
        await _deleteReportUseCase.execute(report.filePath);
      }
      
      debugPrint("✅ All reports cleared successfully");
      emit(const ReportHistoryLoaded([]));
      
    } catch (e, stackTrace) {
      debugPrint("❌ Clearing reports failed: $e");
      debugPrint("Stack trace: $stackTrace");
      
      emit(ReportsError(
        message: 'Failed to clear reports: ${e.toString()}',
        technicalDetails: e.toString(),
      ));
    }
  }

  /// Handle getting report history
  Future<void> _onGetReportHistory(
    GetReportHistoryEvent event,
    Emitter<ReportsState> emit,
  ) async {
    debugPrint("📋 Getting report history");
    
    try {
      final reports = await _getReportHistoryUseCase.execute();
      
      debugPrint("📋 Found ${reports.length} reports in history");
      emit(ReportHistoryLoaded(reports));
      
    } catch (e, stackTrace) {
      debugPrint("❌ Getting report history failed: $e");
      debugPrint("Stack trace: $stackTrace");
      
      emit(ReportsError(
        message: 'Failed to load report history: ${e.toString()}',
        technicalDetails: e.toString(),
      ));
    }
  }

  // ========================================================================
  // ERROR HANDLING
  // ========================================================================

  /// Convert technical errors to user-friendly messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission') || errorString.contains('access denied')) {
      return 'Permission denied. Please check file access permissions.';
    } else if (errorString.contains('space') || errorString.contains('storage')) {
      return 'Not enough storage space to generate the report.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Report generation is taking too long. Please try again.';
    } else if (errorString.contains('no analysis results')) {
      return 'No analysis data available. Please analyze the chat first.';
    } else if (errorString.contains('invalid data') || errorString.contains('corrupt')) {
      return 'The analysis data appears to be corrupted. Please re-analyze the chat.';
    } else {
      return 'An unexpected error occurred while generating the report.';
    }
  }

  // ========================================================================
  // GETTERS
  // ========================================================================

  /// Check if a report is currently being generated
  bool get isGenerating => state is ReportsLoading;

  /// Get the last generated report file
  File? get lastGeneratedReport {
    final currentState = state;
    if (currentState is ReportGenerated) {
      return currentState.reportFile;
    }
    return null;
  }

  /// Get the last generated report metadata
  ReportMetadata? get lastReportMetadata {
    final currentState = state;
    if (currentState is ReportGenerated) {
      return currentState.metadata;
    }
    return null;
  }

  /// Get the current report history
  List<ReportMetadata> get reportHistory {
    final currentState = state;
    if (currentState is ReportHistoryLoaded) {
      return currentState.reports;
    }
    return [];
  }
}