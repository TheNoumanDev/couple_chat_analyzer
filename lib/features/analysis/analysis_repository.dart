// ============================================================================
// FILE: features/analysis/analysis_repository.dart
// ============================================================================
import 'dart:io';
import '../../data/local.dart';
import '../../shared/domain.dart';

abstract class AnalysisRepository {
  Future<Map<String, dynamic>?> getAnalysisResults(String chatId);
  Future<void> saveAnalysisResults(String chatId, Map<String, dynamic> results);
  Future<void> deleteAnalysisResults(String chatId);
  Future<File> generateReport(String chatId, Map<String, dynamic> results);
}

class AnalysisRepositoryImpl implements AnalysisRepository {
  final ChatLocalDataSource localDataSource;

  AnalysisRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Map<String, dynamic>?> getAnalysisResults(String chatId) async {
    return await localDataSource.getAnalysisResults(chatId);
  }

  @override
  Future<void> saveAnalysisResults(String chatId, Map<String, dynamic> results) async {
    await localDataSource.saveAnalysisResults(chatId, results);
  }

  @override
  Future<void> deleteAnalysisResults(String chatId) async {
    await localDataSource.deleteAnalysisResults(chatId);
  }

  @override
  Future<File> generateReport(String chatId, Map<String, dynamic> results) async {
    return await localDataSource.generateReport(chatId, results);
  }
}