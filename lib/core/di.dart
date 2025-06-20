// ============================================================================
// FILE: core/di.dart
// ============================================================================
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

// Data layer imports
import '../data/local.dart';
import '../data/parsers/chat_parser.dart';
import '../data/parsers/whatsapp_text_parser.dart';
import '../data/parsers/whatsapp_html_parser.dart';
import '../data/repositories.dart';

// Domain layer imports
import '../shared/domain.dart';

// Analysis feature imports
import '../features/analysis/analysis_bloc.dart';
import '../features/analysis/analysis_use_cases.dart';
import '../features/analysis/analysis_repository.dart';
import '../features/analysis/analyzers/message_analyzer.dart';
import '../features/analysis/analyzers/time_analyzer.dart';
import '../features/analysis/analyzers/user_analyzer.dart';
import '../features/analysis/analyzers/content_analyzer.dart';
import '../features/analysis/enhanced_analyzers.dart';

// Import feature imports
import '../features/import/import_bloc.dart';
import '../features/import/import_use_cases.dart';
import '../features/import/providers/file_provider.dart';

// Reports feature imports
import '../features/reports/reports_feature.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  debugPrint("Initializing dependencies");

  // Initialize local data source first
  final chatLocalDataSource = ChatLocalDataSourceImpl();
  await chatLocalDataSource.initDatabase();
  getIt.registerLazySingleton<ChatLocalDataSource>(() => chatLocalDataSource);

  // Data sources and providers
  final fileProvider = FileProviderImpl();
  fileProvider.init();
  getIt.registerLazySingleton<FileProvider>(() => fileProvider);

  // Parsers
  getIt.registerFactory<WhatsAppTextParser>(() => WhatsAppTextParserImpl());
  getIt.registerFactory<WhatsAppHtmlParser>(() => WhatsAppHtmlParserImpl());
  getIt.registerFactory<ChatParser>(() => ChatParserImpl(
        textParser: getIt<WhatsAppTextParser>(),
        htmlParser: getIt<WhatsAppHtmlParser>(),
      ));

  // Repositories
  getIt.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(
        localDataSource: getIt<ChatLocalDataSource>(),
        fileProvider: getIt<FileProvider>(),
        chatParser: getIt<ChatParser>(),
      ));

  getIt.registerLazySingleton<AnalysisRepository>(() => AnalysisRepositoryImpl(
        localDataSource: getIt<ChatLocalDataSource>(),
      ));

  // Core Analyzers
  getIt.registerFactory(() => MessageAnalyzer());
  getIt.registerFactory(() => TimeAnalyzer());
  getIt.registerFactory(() => UserAnalyzer());
  getIt.registerFactory(() => ContentAnalyzer());

  // Enhanced Analyzers (from existing enhanced_analyzers.dart)
  getIt.registerFactory(() => ConversationDynamicsAnalyzer());
  getIt.registerFactory(() => BehaviorPatternAnalyzer());
  getIt.registerFactory(() => RelationshipAnalyzer());
  getIt.registerFactory(() => ContentIntelligenceAnalyzer());
  getIt.registerFactory(() => TemporalInsightAnalyzer());

  // Use Cases
  getIt.registerFactory(() => ImportChatUseCase(getIt<ChatRepository>()));
  
  getIt.registerFactory(() => AnalyzeChatUseCase(
    chatRepository: getIt<ChatRepository>(),
    analysisRepository: getIt<AnalysisRepository>(),
    messageAnalyzer: getIt<MessageAnalyzer>(),
    timeAnalyzer: getIt<TimeAnalyzer>(),
    userAnalyzer: getIt<UserAnalyzer>(),
    contentAnalyzer: getIt<ContentAnalyzer>(),
    conversationDynamicsAnalyzer: getIt<ConversationDynamicsAnalyzer>(),
    behaviorPatternAnalyzer: getIt<BehaviorPatternAnalyzer>(),
    relationshipAnalyzer: getIt<RelationshipAnalyzer>(),
    contentIntelligenceAnalyzer: getIt<ContentIntelligenceAnalyzer>(),
    temporalInsightAnalyzer: getIt<TemporalInsightAnalyzer>(),
  ));

  getIt.registerFactory(() => GenerateReportUseCase(getIt<AnalysisRepository>()));

  debugPrint("✅ Dependencies initialized successfully");
}