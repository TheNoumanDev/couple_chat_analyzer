import '../../../shared/domain.dart';

abstract class BaseAnalyzer {
  Future<Map<String, dynamic>> analyze(ChatEntity chat);
}
