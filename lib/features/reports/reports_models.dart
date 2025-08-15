// ============================================================================
// FILE: features/reports/reports_models.dart
// Reports models for report generation
// ============================================================================
import 'dart:io';
import 'package:equatable/equatable.dart';

// ============================================================================
// REPORT EVENTS
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
// REPORT STATES
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

class ReportsSuccess extends ReportsState {
  final File reportFile;

  const ReportsSuccess(this.reportFile);

  @override
  List<Object?> get props => [reportFile];
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
// REPORT CONFIGURATION
// ============================================================================
class ReportConfig {
  final bool includeCharts;
  final bool includeDetailedAnalysis;
  final bool includeUserBreakdown;
  final bool includeTimeAnalysis;
  final bool includeContentAnalysis;
  final bool includeInsights;
  final ReportFormat format;
  final String? customTitle;
  final bool includeRawData;

  const ReportConfig({
    this.includeCharts = true,
    this.includeDetailedAnalysis = true,
    this.includeUserBreakdown = true,
    this.includeTimeAnalysis = true,
    this.includeContentAnalysis = true,
    this.includeInsights = false,
    this.format = ReportFormat.pdf,
    this.customTitle,
    this.includeRawData = false,
  });

  factory ReportConfig.defaultConfig() {
    return const ReportConfig();
  }

  factory ReportConfig.simpleConfig() {
    return const ReportConfig(
      includeCharts: false,
      includeDetailedAnalysis: false,
      includeInsights: false,
      includeRawData: false,
    );
  }

  factory ReportConfig.fullConfig() {
    return const ReportConfig(
      includeCharts: true,
      includeDetailedAnalysis: true,
      includeUserBreakdown: true,
      includeTimeAnalysis: true,
      includeContentAnalysis: true,
      includeInsights: true,
      includeRawData: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeCharts': includeCharts,
      'includeDetailedAnalysis': includeDetailedAnalysis,
      'includeUserBreakdown': includeUserBreakdown,
      'includeTimeAnalysis': includeTimeAnalysis,
      'includeContentAnalysis': includeContentAnalysis,
      'includeInsights': includeInsights,
      'format': format.index,
      'customTitle': customTitle,
      'includeRawData': includeRawData,
    };
  }

  factory ReportConfig.fromJson(Map<String, dynamic> json) {
    return ReportConfig(
      includeCharts: json['includeCharts'] ?? true,
      includeDetailedAnalysis: json['includeDetailedAnalysis'] ?? true,
      includeUserBreakdown: json['includeUserBreakdown'] ?? true,
      includeTimeAnalysis: json['includeTimeAnalysis'] ?? true,
      includeContentAnalysis: json['includeContentAnalysis'] ?? true,
      includeInsights: json['includeInsights'] ?? false,
      format: ReportFormat.values[json['format'] ?? 0],
      customTitle: json['customTitle'],
      includeRawData: json['includeRawData'] ?? false,
    );
  }
}

enum ReportFormat {
  pdf,
  html,
  csv,
  json,
}

// ============================================================================
// REPORT METADATA
// ============================================================================
class ReportMetadata {
  final String reportId;
  final String chatId;
  final String fileName;
  final String filePath;
  final DateTime generatedAt;
  final ReportFormat format;
  final int fileSizeBytes;
  final ReportConfig config;
  final Map<String, dynamic> summary;

  ReportMetadata({
    required this.reportId,
    required this.chatId,
    required this.fileName,
    required this.filePath,
    required this.generatedAt,
    required this.format,
    required this.fileSizeBytes,
    required this.config,
    this.summary = const {},
  });

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formatName {
    switch (format) {
      case ReportFormat.pdf:
        return 'PDF';
      case ReportFormat.html:
        return 'HTML';
      case ReportFormat.csv:
        return 'CSV';
      case ReportFormat.json:
        return 'JSON';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'chatId': chatId,
      'fileName': fileName,
      'filePath': filePath,
      'generatedAt': generatedAt.toIso8601String(),
      'format': format.index,
      'fileSizeBytes': fileSizeBytes,
      'config': config.toJson(),
      'summary': summary,
    };
  }

  factory ReportMetadata.fromJson(Map<String, dynamic> json) {
    return ReportMetadata(
      reportId: json['reportId'],
      chatId: json['chatId'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      generatedAt: DateTime.parse(json['generatedAt']),
      format: ReportFormat.values[json['format']],
      fileSizeBytes: json['fileSizeBytes'],
      config: ReportConfig.fromJson(json['config']),
      summary: Map<String, dynamic>.from(json['summary'] ?? {}),
    );
  }
}

// ============================================================================
// REPORT GENERATION RESULT
// ============================================================================
class ReportGenerationResult {
  final File file;
  final ReportMetadata metadata;
  final bool success;
  final String? errorMessage;

  ReportGenerationResult({
    required this.file,
    required this.metadata,
    this.success = true,
    this.errorMessage,
  });

  factory ReportGenerationResult.success(File file, ReportMetadata metadata) {
    return ReportGenerationResult(
      file: file,
      metadata: metadata,
      success: true,
    );
  }

  factory ReportGenerationResult.error(String errorMessage) {
    return ReportGenerationResult(
      file: File(''),
      metadata: ReportMetadata(
        reportId: '',
        chatId: '',
        fileName: '',
        filePath: '',
        generatedAt: DateTime.now(),
        format: ReportFormat.pdf,
        fileSizeBytes: 0,
        config: ReportConfig.defaultConfig(),
      ),
      success: false,
      errorMessage: errorMessage,
    );
  }
}

// ============================================================================
// REPORT SHARING RESULT
// ============================================================================
class ReportSharingResult {
  final bool success;
  final String message;
  final String? errorDetails;

  ReportSharingResult({
    required this.success,
    required this.message,
    this.errorDetails,
  });

  factory ReportSharingResult.success(String message) {
    return ReportSharingResult(
      success: true,
      message: message,
    );
  }

  factory ReportSharingResult.error(String message, [String? errorDetails]) {
    return ReportSharingResult(
      success: false,
      message: message,
      errorDetails: errorDetails,
    );
  }
}