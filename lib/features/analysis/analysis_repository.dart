// ============================================================================
// FILE: features/analysis/analysis_repository.dart
// Analysis Repository - Handles analysis data persistence and retrieval
// ============================================================================
import 'dart:io';
// Removed unused import: import 'package:chatreport/shared/models.dart' as shared_models;
import 'package:flutter/foundation.dart';
import '../../shared/domain.dart';
import '../../data/local.dart';
import 'analysis_models.dart' as analysis_models;


abstract class AnalysisRepository {
  Future<analysis_models.ChatAnalysisResult?> getAnalysisResults(String chatId);
  Future<void> saveAnalysisResults(String chatId, analysis_models.ChatAnalysisResult results);
  Future<void> deleteAnalysisResults(String chatId);
  Future<List<String>> getAnalyzedChatIds();
  Future<bool> hasAnalysisResults(String chatId);
  Future<File> generateReport(String chatId, analysis_models.ChatAnalysisResult results);
  Future<void> clearAllAnalysisResults();
}

class AnalysisRepositoryImpl implements AnalysisRepository {
  final ChatLocalDataSource _localDataSource;

  AnalysisRepositoryImpl({
    required ChatLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<analysis_models.ChatAnalysisResult?> getAnalysisResults(String chatId) async {
    try {
      debugPrint("📖 Getting analysis results for chat: $chatId");
      
      final data = await _localDataSource.getAnalysisResults(chatId);
      if (data == null) {
        debugPrint("📖 No analysis results found for chat: $chatId");
        return null;
      }

      // Convert stored data back to ChatAnalysisResult
      final result = analysis_models.ChatAnalysisResult.fromJson(data);
      debugPrint("📖 Successfully retrieved analysis results for chat: $chatId");
      
      return result;
    } catch (e, stackTrace) {
      debugPrint("❌ Error getting analysis results: $e");
      debugPrint("Stack trace: $stackTrace");
      return null;
    }
  }

  @override
  Future<void> saveAnalysisResults(String chatId, analysis_models.ChatAnalysisResult results) async {
    try {
      debugPrint("💾 Saving analysis results for chat: $chatId");
      
      // Convert to JSON format for storage
      final data = results.toJson();
      
      await _localDataSource.saveAnalysisResults(chatId, data);
      debugPrint("💾 Successfully saved analysis results for chat: $chatId");
      
    } catch (e, stackTrace) {
      debugPrint("❌ Error saving analysis results: $e");
      debugPrint("Stack trace: $stackTrace");
      throw Exception('Failed to save analysis results: $e');
    }
  }

  @override
  Future<void> deleteAnalysisResults(String chatId) async {
    try {
      debugPrint("🗑️ Deleting analysis results for chat: $chatId");
      
      await _localDataSource.deleteAnalysisResults(chatId);
      debugPrint("🗑️ Successfully deleted analysis results for chat: $chatId");
      
    } catch (e, stackTrace) {
      debugPrint("❌ Error deleting analysis results: $e");
      debugPrint("Stack trace: $stackTrace");
      throw Exception('Failed to delete analysis results: $e');
    }
  }

  @override
  Future<List<String>> getAnalyzedChatIds() async {
    try {
      debugPrint("📋 Getting list of analyzed chat IDs");
      
      // This would need to be implemented in the local data source
      // For now, we'll return an empty list
      // TODO: Implement getAnalyzedChatIds in ChatLocalDataSource
      
      debugPrint("📋 Retrieved 0 analyzed chat IDs"); // Placeholder
      return [];
      
    } catch (e, stackTrace) {
      debugPrint("❌ Error getting analyzed chat IDs: $e");
      debugPrint("Stack trace: $stackTrace");
      return [];
    }
  }

  @override
  Future<bool> hasAnalysisResults(String chatId) async {
    try {
      debugPrint("🔍 Checking if analysis results exist for chat: $chatId");
      
      final results = await getAnalysisResults(chatId);
      final hasResults = results != null;
      
      debugPrint("🔍 Chat $chatId has analysis results: $hasResults");
      return hasResults;
      
    } catch (e, stackTrace) {
      debugPrint("❌ Error checking analysis results existence: $e");
      debugPrint("Stack trace: $stackTrace");
      return false;
    }
  }

  @override
  Future<File> generateReport(String chatId, analysis_models.ChatAnalysisResult results) async {
    try {
      debugPrint("📄 Generating report for chat: $chatId");
      
      // Delegate to local data source for report generation
      final reportFile = await _localDataSource.generateReport(chatId, results.toJson());
      
      debugPrint("📄 Successfully generated report: ${reportFile.path}");
      return reportFile;
      
    } catch (e, stackTrace) {
      debugPrint("❌ Error generating report: $e");
      debugPrint("Stack trace: $stackTrace");
      throw Exception('Failed to generate report: $e');
    }
  }

  @override
  Future<void> clearAllAnalysisResults() async {
    try {
      debugPrint("🧹 Clearing all analysis results");
      
      // Get all analyzed chat IDs and delete their results
      final chatIds = await getAnalyzedChatIds();
      
      for (final chatId in chatIds) {
        await deleteAnalysisResults(chatId);
      }
      
      debugPrint("🧹 Successfully cleared all analysis results");
      
    } catch (e, stackTrace) {
      debugPrint("❌ Error clearing all analysis results: $e");
      debugPrint("Stack trace: $stackTrace");
      throw Exception('Failed to clear all analysis results: $e');
    }
  }

  // ========================================================================
  // HELPER METHODS
  // ========================================================================

  /// Check if analysis results are still valid (not too old)
  Future<bool> areResultsValid(String chatId, {Duration maxAge = const Duration(days: 7)}) async {
    try {
      final results = await getAnalysisResults(chatId);
      if (results == null) return false;

      final age = DateTime.now().difference(results.generatedAt);
      return age <= maxAge;
      
    } catch (e) {
      debugPrint("Error checking results validity: $e");
      return false;
    }
  }

  /// Get analysis results summary (without full data)
  Future<AnalysisResultSummary?> getAnalysisResultsSummary(String chatId) async {
    try {
      final results = await getAnalysisResults(chatId);
      if (results == null) return null;

      return AnalysisResultSummary(
        chatId: chatId,
        generatedAt: results.generatedAt,
        analyzersUsed: results.results.keys.toList(),
        totalResults: results.results.length,
        hasErrors: results.results.values.any((result) => result.data.containsKey('error')),
      );
      
    } catch (e) {
      debugPrint("Error getting analysis summary: $e");
      return null;
    }
  }

  /// Update specific analysis result (for incremental updates)
  @override
  Future<void> updateAnalysisResult(String chatId, String analyzerType, analysis_models.AnalysisResult result) async {
    try {
      debugPrint("🔄 Updating analysis result for $analyzerType in chat: $chatId");
      
      // Get existing results
      var existingResults = await getAnalysisResults(chatId);
      
      if (existingResults == null) {
        // Create new results if none exist
        existingResults = analysis_models.ChatAnalysisResult(
          chatId: chatId,
          results: {},
          generatedAt: DateTime.now(),
        );
      }

      // Update the specific analyzer result directly
      existingResults.results[analyzerType] = result;

      existingResults = analysis_models.ChatAnalysisResult(
        chatId: chatId,
        results: existingResults.results,
        generatedAt: DateTime.now(), // Update timestamp
      );

      // Save updated results
      await saveAnalysisResults(chatId, existingResults);
      
      debugPrint("🔄 Successfully updated analysis result for $analyzerType");
      
    } catch (e, stackTrace) {
      debugPrint("❌ Error updating analysis result: $e");
      debugPrint("Stack trace: $stackTrace");
      throw Exception('Failed to update analysis result: $e');
    }
  }

  /// Get analysis statistics
  Future<AnalysisStatistics> getAnalysisStatistics() async {
    try {
      debugPrint("📊 Getting analysis statistics");
      
      final analyzedChatIds = await getAnalyzedChatIds();
      int totalAnalyses = analyzedChatIds.length;
      int successfulAnalyses = 0;
      int failedAnalyses = 0;
      DateTime? lastAnalysis;

      for (final chatId in analyzedChatIds) {
        final summary = await getAnalysisResultsSummary(chatId);
        if (summary != null) {
          if (summary.hasErrors) {
            failedAnalyses++;
          } else {
            successfulAnalyses++;
          }

          if (lastAnalysis == null || summary.generatedAt.isAfter(lastAnalysis)) {
            lastAnalysis = summary.generatedAt;
          }
        }
      }

      final statistics = AnalysisStatistics(
        totalAnalyses: totalAnalyses,
        successfulAnalyses: successfulAnalyses,
        failedAnalyses: failedAnalyses,
        lastAnalysisDate: lastAnalysis,
      );

      debugPrint("📊 Analysis statistics: $totalAnalyses total, $successfulAnalyses successful");
      return statistics;
      
    } catch (e, stackTrace) {
      debugPrint("❌ Error getting analysis statistics: $e");
      debugPrint("Stack trace: $stackTrace");
      
      return AnalysisStatistics(
        totalAnalyses: 0,
        successfulAnalyses: 0,
        failedAnalyses: 0,
        lastAnalysisDate: null,
      );
    }
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

class AnalysisResultSummary {
  final String chatId;
  final DateTime generatedAt;
  final List<String> analyzersUsed;
  final int totalResults;
  final bool hasErrors;

  AnalysisResultSummary({
    required this.chatId,
    required this.generatedAt,
    required this.analyzersUsed,
    required this.totalResults,
    required this.hasErrors,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'generatedAt': generatedAt.toIso8601String(),
      'analyzersUsed': analyzersUsed,
      'totalResults': totalResults,
      'hasErrors': hasErrors,
    };
  }

  factory AnalysisResultSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisResultSummary(
      chatId: json['chatId'],
      generatedAt: DateTime.parse(json['generatedAt']),
      analyzersUsed: List<String>.from(json['analyzersUsed']),
      totalResults: json['totalResults'],
      hasErrors: json['hasErrors'],
    );
  }
}

class AnalysisStatistics {
  final int totalAnalyses;
  final int successfulAnalyses;
  final int failedAnalyses;
  final DateTime? lastAnalysisDate;

  AnalysisStatistics({
    required this.totalAnalyses,
    required this.successfulAnalyses,
    required this.failedAnalyses,
    this.lastAnalysisDate,
  });

  double get successRate {
    if (totalAnalyses == 0) return 0.0;
    return successfulAnalyses / totalAnalyses;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAnalyses': totalAnalyses,
      'successfulAnalyses': successfulAnalyses,
      'failedAnalyses': failedAnalyses,
      'lastAnalysisDate': lastAnalysisDate?.toIso8601String(),
    };
  }

  factory AnalysisStatistics.fromJson(Map<String, dynamic> json) {
    return AnalysisStatistics(
      totalAnalyses: json['totalAnalyses'],
      successfulAnalyses: json['successfulAnalyses'],
      failedAnalyses: json['failedAnalyses'],
      lastAnalysisDate: json['lastAnalysisDate'] != null 
          ? DateTime.parse(json['lastAnalysisDate'])
          : null,
    );
  }
}