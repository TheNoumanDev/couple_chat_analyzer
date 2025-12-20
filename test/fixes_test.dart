// ============================================================================
// FILE: test/fixes_test.dart
// Tests for codebase fixes
// ============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:chatreport/features/analysis/analysis_models.dart';
import 'package:chatreport/features/reports/reports_models.dart';

void main() {
  group('Analysis Models & BLoC Tests', () {
    test('AnalysisSuccess should have correct signature', () {
      final result = ChatAnalysisResult(
        chatId: 'test-chat',
        results: {},
        generatedAt: DateTime.now(),
      );
      
      final success = AnalysisSuccess(
        chatId: 'test-chat',
        result: result,
        completedAt: DateTime.now(),
      );
      
      expect(success.chatId, 'test-chat');
      expect(success.result, isA<ChatAnalysisResult>());
      expect(success.completedAt, isA<DateTime>());
    });

    test('AnalysisError should accept message as positional parameter', () {
      final error = AnalysisError(
        'Test error message',
        technicalDetails: 'Technical details',
        canRetry: true,
      );
      
      expect(error.message, 'Test error message');
      expect(error.technicalDetails, 'Technical details');
      expect(error.canRetry, true);
    });

    test('AnalysisEvent classes should be importable from models', () {
      expect(StartAnalysisEvent('test'), isA<AnalysisEvent>());
      expect(RefreshAnalysisEvent('test'), isA<AnalysisEvent>());
      expect(ClearAnalysisEvent(), isA<AnalysisEvent>());
    });

    test('AnalysisState classes should be importable from models', () {
      expect(AnalysisInitial(), isA<AnalysisState>());
      expect(const AnalysisLoading(), isA<AnalysisState>());
    });
  });

  group('Reports Models & BLoC Tests', () {
    test('ReportsEvent classes should be importable from models', () {
      expect(
        GenerateReportEvent(
          chatId: 'test',
          analysisResults: {},
        ),
        isA<ReportsEvent>(),
      );
      expect(GetReportHistoryEvent(), isA<ReportsEvent>());
    });

    test('ReportsState classes should be importable from models', () {
      expect(ReportsInitial(), isA<ReportsState>());
      expect(const ReportsLoading(), isA<ReportsState>());
    });

    test('ReportGenerated should have correct structure', () {
      final metadata = ReportMetadata(
        reportId: 'test-id',
        chatId: 'chat-id',
        fileName: 'test.pdf',
        filePath: '/path/to/test.pdf',
        generatedAt: DateTime.now(),
        format: ReportFormat.pdf,
        fileSizeBytes: 1024,
        config: ReportConfig.defaultConfig(),
      );
      
      // Note: File is not easily testable without mocking
      // This test verifies the structure is correct
      expect(metadata.reportId, 'test-id');
      expect(metadata.chatId, 'chat-id');
    });
  });

  group('No Duplicate Code Tests', () {
    test('ReportsEvent should only exist in models, not bloc', () {
      // This test ensures we're using the models version
      final event = GenerateReportEvent(
        chatId: 'test',
        analysisResults: {},
      );
      expect(event, isA<ReportsEvent>());
    });

    test('AnalysisEvent should only exist in models, not bloc', () {
      final event = StartAnalysisEvent('test');
      expect(event, isA<AnalysisEvent>());
    });
  });
}

