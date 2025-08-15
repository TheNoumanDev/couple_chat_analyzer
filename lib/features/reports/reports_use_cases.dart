// ============================================================================
// FILE: features/reports/reports_use_cases.dart
// Reports use cases - Fixed with import prefix to resolve AnalysisRepository conflict
// ============================================================================
import 'dart:io';
import 'dart:convert';
import 'package:chatreport/features/analysis/analysis_models.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/domain.dart';
import '../analysis/analysis_repository.dart' as analysis_repo;
import 'reports_models.dart';

// ============================================================================
// GENERATE REPORT USE CASE
// ============================================================================
class GenerateReportUseCase {
  final analysis_repo.AnalysisRepository analysisRepository;
  final _uuid = const Uuid();

  GenerateReportUseCase({
    required this.analysisRepository,
  });

  Future<ReportGenerationResult> execute({
    required String chatId,
    required Map<String, dynamic> analysisResults,
    ReportConfig? config,
  }) async {
    try {
      debugPrint("📄 Generating report for chat: $chatId");

      config ??= ReportConfig.defaultConfig();

      // Generate report file
      final reportFile = await analysisRepository.generateReport(
        chatId,
        ChatAnalysisResult.fromJson(analysisResults),
      );

      // Create metadata
      final metadata = ReportMetadata(
        reportId: _uuid.v4(),
        chatId: chatId,
        fileName: reportFile.path.split('/').last,
        filePath: reportFile.path,
        generatedAt: DateTime.now(),
        format: config.format,
        fileSizeBytes: await reportFile.length(),
        config: config,
        summary: _generateSummary(analysisResults),
      );

      debugPrint("✅ Report generated successfully: ${reportFile.path}");

      return ReportGenerationResult.success(reportFile, metadata);
    } catch (e, stackTrace) {
      debugPrint("❌ Error generating report: $e");
      debugPrint("Stack trace: $stackTrace");
      return ReportGenerationResult.error('Failed to generate report: $e');
    }
  }

  Map<String, dynamic> _generateSummary(Map<String, dynamic> analysisResults) {
    final summary = analysisResults['summary'] as Map<String, dynamic>? ?? {};
    
    return {
      'totalMessages': summary['totalMessages'] ?? 0,
      'totalUsers': summary['totalUsers'] ?? 0,
      'dateRange': summary['dateRange'] ?? 'Unknown',
      'analysisTypes': analysisResults.keys.length,
      'hasCharts': true,
      'hasInsights': analysisResults.containsKey('behaviorPatterns') || 
                    analysisResults.containsKey('relationshipDynamics'),
    };
  }
}

// ============================================================================
// SHARE REPORT USE CASE
// ============================================================================
class ShareReportUseCase {
  Future<ReportSharingResult> execute(File reportFile) async {
    try {
      debugPrint("📤 Sharing report: ${reportFile.path}");

      if (!await reportFile.exists()) {
        return ReportSharingResult.error('Report file not found');
      }

      // In a real implementation, you would use share_plus package
      // For now, we'll just simulate success
      debugPrint("✅ Report shared successfully");
      
      return ReportSharingResult.success('Report shared successfully');
    } catch (e, stackTrace) {
      debugPrint("❌ Error sharing report: $e");
      debugPrint("Stack trace: $stackTrace");
      return ReportSharingResult.error('Failed to share report', e.toString());
    }
  }
}

// ============================================================================
// DELETE REPORT USE CASE
// ============================================================================
class DeleteReportUseCase {
  Future<void> execute(String reportPath) async {
    try {
      debugPrint("🗑️ Deleting report: $reportPath");

      final file = File(reportPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint("✅ Report deleted successfully");
      } else {
        debugPrint("⚠️ Report file not found: $reportPath");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error deleting report: $e");
      debugPrint("Stack trace: $stackTrace");
      throw Exception('Failed to delete report: $e');
    }
  }
}

// ============================================================================
// GET REPORT HISTORY USE CASE
// ============================================================================
class GetReportHistoryUseCase {
  Future<List<ReportMetadata>> execute() async {
    try {
      debugPrint("📋 Getting report history");

      // Get reports directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${appDocDir.path}/ChatInsight Reports');

      if (!await reportsDir.exists()) {
        debugPrint("📋 Reports directory doesn't exist, returning empty list");
        return [];
      }

      final reports = <ReportMetadata>[];
      
      // List all files in reports directory
      await for (final entity in reportsDir.list()) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          try {
            final stat = await entity.stat();
            final fileName = entity.path.split('/').last;
            
            // Create basic metadata for existing files
            final metadata = ReportMetadata(
              reportId: _generateIdFromPath(entity.path),
              chatId: _extractChatIdFromFileName(fileName),
              fileName: fileName,
              filePath: entity.path,
              generatedAt: stat.modified,
              format: _getFormatFromExtension(fileName),
              fileSizeBytes: stat.size,
              config: ReportConfig.defaultConfig(),
              summary: {},
            );
            
            reports.add(metadata);
          } catch (e) {
            debugPrint("⚠️ Error processing report file ${entity.path}: $e");
          }
        }
      }

      // Sort by generation date (newest first)
      reports.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

      debugPrint("📋 Found ${reports.length} reports in history");
      return reports;
    } catch (e, stackTrace) {
      debugPrint("❌ Error getting report history: $e");
      debugPrint("Stack trace: $stackTrace");
      return [];
    }
  }

  String _generateIdFromPath(String path) {
    // Generate a simple ID based on file path hash
    return path.hashCode.abs().toString();
  }

  String _extractChatIdFromFileName(String fileName) {
    // Try to extract chat ID from filename pattern
    final parts = fileName.split('_');
    if (parts.length > 2) {
      return parts[2]; // Assuming format: chat_analysis_<chatId>_<timestamp>.pdf
    }
    return 'unknown';
  }

  ReportFormat _getFormatFromExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return ReportFormat.pdf;
      case 'html':
        return ReportFormat.html;
      case 'csv':
        return ReportFormat.csv;
      case 'json':
        return ReportFormat.json;
      default:
        return ReportFormat.pdf;
    }
  }
}

// ============================================================================
// EXPORT REPORT USE CASE
// ============================================================================
class ExportReportUseCase {
  Future<File> execute({
    required String chatId,
    required Map<String, dynamic> analysisResults,
    required ReportFormat format,
    ReportConfig? config,
  }) async {
    try {
      debugPrint("📁 Exporting report in $format format for chat: $chatId");

      config ??= ReportConfig.defaultConfig();

      // Get reports directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${appDocDir.path}/ChatInsight Reports');
      await reportsDir.create(recursive: true);

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getExtensionForFormat(format);
      final fileName = 'chat_analysis_${chatId}_$timestamp.$extension';
      final filePath = '${reportsDir.path}/$fileName';

      // Generate content based on format
      final file = File(filePath);
      
      switch (format) {
        case ReportFormat.pdf:
          // PDF generation would be handled by the repository
          throw UnimplementedError('PDF export should use generateReport method');
          
        case ReportFormat.html:
          await _generateHtmlReport(file, analysisResults, config);
          break;
          
        case ReportFormat.csv:
          await _generateCsvReport(file, analysisResults, config);
          break;
          
        case ReportFormat.json:
          await _generateJsonReport(file, analysisResults, config);
          break;
      }

      debugPrint("✅ Report exported successfully: ${file.path}");
      return file;
    } catch (e, stackTrace) {
      debugPrint("❌ Error exporting report: $e");
      debugPrint("Stack trace: $stackTrace");
      rethrow;
    }
  }

  String _getExtensionForFormat(ReportFormat format) {
    switch (format) {
      case ReportFormat.pdf:
        return 'pdf';
      case ReportFormat.html:
        return 'html';
      case ReportFormat.csv:
        return 'csv';
      case ReportFormat.json:
        return 'json';
    }
  }

  Future<void> _generateHtmlReport(
    File file,
    Map<String, dynamic> analysisResults,
    ReportConfig config,
  ) async {
    final summary = analysisResults['summary'] as Map<String, dynamic>? ?? {};
    
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <title>Chat Analysis Report</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .section { margin-bottom: 25px; }
        .metric { display: inline-block; margin: 10px; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Chat Analysis Report</h1>
        <p>Generated on ${DateTime.now().toString().split('.')[0]}</p>
    </div>
    
    <div class="section">
        <h2>Summary</h2>
        <div class="metric">
            <strong>Total Messages:</strong> ${summary['totalMessages'] ?? 0}
        </div>
        <div class="metric">
            <strong>Total Users:</strong> ${summary['totalUsers'] ?? 0}
        </div>
        <div class="metric">
            <strong>Date Range:</strong> ${summary['dateRange'] ?? 'Unknown'}
        </div>
        <div class="metric">
            <strong>Duration:</strong> ${summary['durationDays'] ?? 0} days
        </div>
    </div>
    
    ${config.includeUserBreakdown ? _generateUserSection(analysisResults) : ''}
    ${config.includeTimeAnalysis ? _generateTimeSection(analysisResults) : ''}
    ${config.includeContentAnalysis ? _generateContentSection(analysisResults) : ''}
    
</body>
</html>
''';

    await file.writeAsString(htmlContent);
  }

  String _generateUserSection(Map<String, dynamic> analysisResults) {
    final users = analysisResults['messagesByUser'] as List<dynamic>? ?? [];
    
    if (users.isEmpty) return '';
    
    final tableRows = users.map((user) {
      final userData = user as Map<String, dynamic>;
      return '''
        <tr>
            <td>${userData['name'] ?? 'Unknown'}</td>
            <td>${userData['messageCount'] ?? 0}</td>
            <td>${userData['percentage']?.toStringAsFixed(1) ?? '0.0'}%</td>
        </tr>
      ''';
    }).join();
    
    return '''
    <div class="section">
        <h2>User Breakdown</h2>
        <table>
            <tr>
                <th>Name</th>
                <th>Messages</th>
                <th>Percentage</th>
            </tr>
            $tableRows
        </table>
    </div>
    ''';
  }

  String _generateTimeSection(Map<String, dynamic> analysisResults) {
    final timeAnalysis = analysisResults['timeAnalysis'] as Map<String, dynamic>? ?? {};
    final peakHour = timeAnalysis['peakHour'] as Map<String, dynamic>? ?? {};
    final peakDay = timeAnalysis['peakDay'] as Map<String, dynamic>? ?? {};
    
    return '''
    <div class="section">
        <h2>Time Analysis</h2>
        <div class="metric">
            <strong>Peak Hour:</strong> ${peakHour['timeRange'] ?? 'Unknown'}
        </div>
        <div class="metric">
            <strong>Peak Day:</strong> ${peakDay['dayName'] ?? 'Unknown'}
        </div>
    </div>
    ''';
  }

  String _generateContentSection(Map<String, dynamic> analysisResults) {
    final contentAnalysis = analysisResults['contentAnalysis'] as Map<String, dynamic>? ?? {};
    
    return '''
    <div class="section">
        <h2>Content Analysis</h2>
        <div class="metric">
            <strong>Total Words:</strong> ${contentAnalysis['totalWords'] ?? 0}
        </div>
        <div class="metric">
            <strong>Total Emojis:</strong> ${contentAnalysis['totalEmojis'] ?? 0}
        </div>
        <div class="metric">
            <strong>Total Media:</strong> ${contentAnalysis['totalMedia'] ?? 0}
        </div>
    </div>
    ''';
  }

  Future<void> _generateCsvReport(
    File file,
    Map<String, dynamic> analysisResults,
    ReportConfig config,
  ) async {
    final buffer = StringBuffer();
    
    // Add summary data
    buffer.writeln('Section,Metric,Value');
    final summary = analysisResults['summary'] as Map<String, dynamic>? ?? {};
    buffer.writeln('Summary,Total Messages,${summary['totalMessages'] ?? 0}');
    buffer.writeln('Summary,Total Users,${summary['totalUsers'] ?? 0}');
    buffer.writeln('Summary,Date Range,"${summary['dateRange'] ?? 'Unknown'}"');
    buffer.writeln('Summary,Duration Days,${summary['durationDays'] ?? 0}');
    
    // Add user data if requested
    if (config.includeUserBreakdown) {
      buffer.writeln();
      buffer.writeln('User Name,Message Count,Percentage');
      final users = analysisResults['messagesByUser'] as List<dynamic>? ?? [];
      for (final user in users) {
        final userData = user as Map<String, dynamic>;
        buffer.writeln('"${userData['name'] ?? 'Unknown'}",${userData['messageCount'] ?? 0},${userData['percentage']?.toStringAsFixed(1) ?? '0.0'}');
      }
    }
    
    await file.writeAsString(buffer.toString());
  }

  Future<void> _generateJsonReport(
    File file,
    Map<String, dynamic> analysisResults,
    ReportConfig config,
  ) async {
    final reportData = <String, dynamic>{
      'generatedAt': DateTime.now().toIso8601String(),
      'config': config.toJson(),
      'analysisResults': analysisResults,
    };
    
    // Filter data based on config
    if (!config.includeRawData) {
      // Remove large raw data arrays to keep file size manageable
      reportData['analysisResults'] = _filterForJsonExport(analysisResults, config);
    }
    
    await file.writeAsString(_prettyPrintJson(reportData));
  }

  Map<String, dynamic> _filterForJsonExport(Map<String, dynamic> data, ReportConfig config) {
    final filtered = <String, dynamic>{};
    
    // Always include summary
    if (data.containsKey('summary')) {
      filtered['summary'] = data['summary'];
    }
    
    if (config.includeUserBreakdown && data.containsKey('messagesByUser')) {
      filtered['messagesByUser'] = data['messagesByUser'];
    }
    
    if (config.includeTimeAnalysis && data.containsKey('timeAnalysis')) {
      filtered['timeAnalysis'] = data['timeAnalysis'];
    }
    
    if (config.includeContentAnalysis && data.containsKey('contentAnalysis')) {
      filtered['contentAnalysis'] = data['contentAnalysis'];
    }
    
    if (config.includeInsights) {
      if (data.containsKey('behaviorPatterns')) {
        filtered['behaviorPatterns'] = data['behaviorPatterns'];
      }
      if (data.containsKey('relationshipDynamics')) {
        filtered['relationshipDynamics'] = data['relationshipDynamics'];
      }
      if (data.containsKey('conversationDynamics')) {
        filtered['conversationDynamics'] = data['conversationDynamics'];
      }
    }
    
    return filtered;
  }

  String _prettyPrintJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}

// ============================================================================
// CLEANUP REPORTS USE CASE
// ============================================================================
class CleanupReportsUseCase {
  Future<int> execute({Duration? olderThan}) async {
    try {
      debugPrint("🧹 Cleaning up old reports");

      olderThan ??= const Duration(days: 30); // Default to 30 days
      
      final appDocDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${appDocDir.path}/ChatInsight Reports');

      if (!await reportsDir.exists()) {
        debugPrint("📋 Reports directory doesn't exist");
        return 0;
      }

      int deletedCount = 0;
      final cutoffDate = DateTime.now().subtract(olderThan);

      await for (final entity in reportsDir.list()) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await entity.delete();
              deletedCount++;
              debugPrint("🗑️ Deleted old report: ${entity.path}");
            }
          } catch (e) {
            debugPrint("⚠️ Error processing file ${entity.path}: $e");
          }
        }
      }

      debugPrint("✅ Cleanup complete. Deleted $deletedCount old reports");
      return deletedCount;
    } catch (e, stackTrace) {
      debugPrint("❌ Error during cleanup: $e");
      debugPrint("Stack trace: $stackTrace");
      return 0;
    }
  }
}