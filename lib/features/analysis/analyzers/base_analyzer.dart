import 'package:chatreport/features/analysis/analysis_models.dart';

import '../../../shared/domain.dart';

abstract class BaseAnalyzer {
  Future<dynamic> analyze(ChatEntity chat);
}

// For enhanced analyzers that return AnalysisResult
abstract class EnhancedAnalyzer extends BaseAnalyzer {
  @override
  Future<AnalysisResult> analyze(ChatEntity chat);
}

// For basic analyzers that return Map<String, dynamic>
abstract class BasicAnalyzer extends BaseAnalyzer {
  @override
  Future<Map<String, dynamic>> analyze(ChatEntity chat);
}