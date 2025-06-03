// core/di.dart
// Consolidated: dependency_injection.dart

import 'package:chatreport/features/analysis/enhanced_analyzers.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import '../data/local.dart';
import '../data/parsers.dart';
import '../data/repositories.dart';
import '../shared/domain.dart';
import '../features/import/import_feature.dart';
import '../features/analysis/analysis_feature.dart';
import '../features/reports/reports_feature.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  debugPrint("Initializing dependencies");

  // Initialize local data source first
  final chatLocalDataSource = ChatLocalDataSourceImpl();
  await chatLocalDataSource.initDatabase();
  getIt.registerLazySingleton<ChatLocalDataSource>(() => chatLocalDataSource);

  // Data sources
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

  // Analyzers
  getIt.registerFactory(() => MessageAnalyzer());
  getIt.registerFactory(() => TimeAnalyzer());
  getIt.registerFactory(() => UserAnalyzer());
  getIt.registerFactory(() => ContentAnalyzer());
  // Add these new analyzer registrations
  getIt.registerFactory(() => ConversationDynamicsAnalyzer());
  getIt.registerFactory(() => BehaviorPatternAnalyzer());
  getIt.registerFactory(() => RelationshipAnalyzer());
  getIt.registerFactory(() => ContentIntelligenceAnalyzer());
  getIt.registerFactory(() => TemporalInsightAnalyzer());

  // Use cases
  getIt.registerLazySingleton(() => ImportChatUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => AnalyzeChatUseCase(
        chatRepository: getIt<ChatRepository>(),
        analysisRepository: getIt<AnalysisRepository>(),
        messageAnalyzer: getIt<MessageAnalyzer>(),
        timeAnalyzer: getIt<TimeAnalyzer>(),
        userAnalyzer: getIt<UserAnalyzer>(),
        contentAnalyzer: getIt<ContentAnalyzer>(),
        // Add the enhanced analyzers
        conversationDynamicsAnalyzer: getIt<ConversationDynamicsAnalyzer>(),
        behaviorPatternAnalyzer: getIt<BehaviorPatternAnalyzer>(),
        relationshipAnalyzer: getIt<RelationshipAnalyzer>(),
        contentIntelligenceAnalyzer: getIt<ContentIntelligenceAnalyzer>(),
        temporalInsightAnalyzer: getIt<TemporalInsightAnalyzer>(),
      ));
  getIt.registerLazySingleton(
      () => GenerateReportUseCase(getIt<AnalysisRepository>()));

  debugPrint("Dependencies initialized successfully");
}
