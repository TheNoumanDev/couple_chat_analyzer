// ============================================================================
// FILE: core/di.dart
// Dependency Injection - Fixed with import prefixes to resolve conflicts
// ============================================================================
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

// Data layer imports
import '../data/local.dart';
import '../data/parsers/chat_parser.dart';
import '../data/parsers/whatsapp_text_parser.dart';
import '../data/parsers/whatsapp_html_parser.dart';
import '../data/repositories.dart';

// Domain layer imports - using prefix to avoid conflicts
import '../shared/domain.dart' as domain;

// Analysis feature imports - using prefix to avoid conflicts
import '../features/analysis/analysis_repository.dart' as analysis_repo;
import '../features/analysis/analysis_use_cases.dart';
import '../features/analysis/analyzers/message_analyzer.dart';
import '../features/analysis/analyzers/time_analyzer.dart';
import '../features/analysis/analyzers/user_analyzer.dart';
import '../features/analysis/analyzers/content_analyzer.dart';
import '../features/analysis/analyzers/enhanced/conversation_dynamics_analyzer.dart';
import '../features/analysis/analyzers/enhanced/behavior_pattern_analyzer.dart';
import '../features/analysis/analyzers/enhanced/relationship_analyzer.dart';
import '../features/analysis/analyzers/enhanced/content_intelligence_analyzer.dart';
import '../features/analysis/analyzers/enhanced/temporal_insight_analyzer.dart';
import '../features/analysis/analyzers/enhanced/linguistic_analyzer.dart';
import '../features/analysis/analyzers/enhanced/emotional_intelligence_analyzer.dart';
import '../features/analysis/analyzers/enhanced/attachment_pattern_analyzer.dart';
import '../features/analysis/analyzers/enhanced/personality_trait_analyzer.dart';

// Import feature imports
import '../features/import/import_use_cases.dart';
import '../features/import/providers/unified_file_provider.dart';

// Reports feature imports
import '../features/reports/reports_use_cases.dart';

// Services
import '../features/analysis/services/stats_aggregator.dart';
import '../features/ai_insights/ai_insights.dart';

// Config
import 'config/api_config.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  debugPrint("🔧 Initializing dependencies...");

  try {
    // ========================================================================
    // DATA LAYER
    // ========================================================================
    
    // Initialize local data source (in-memory, no database)
    final chatLocalDataSource = ChatLocalDataSourceImpl();
    getIt.registerLazySingleton<ChatLocalDataSource>(() => chatLocalDataSource);

    // File providers - Fix: use init() instead of initialize()
    final fileProvider = UnifiedFileProvider();
    fileProvider.init(); // Use init() method that exists
    getIt.registerLazySingleton<UnifiedFileProvider>(() => fileProvider);

    // Parsers
    getIt.registerFactory<WhatsAppTextParserImpl>(() => WhatsAppTextParserImpl());
    getIt.registerFactory<WhatsAppHtmlParserImpl>(() => WhatsAppHtmlParserImpl());
    getIt.registerFactory<ChatParser>(() => ChatParserImpl(
          textParser: getIt<WhatsAppTextParserImpl>(),
          htmlParser: getIt<WhatsAppHtmlParserImpl>(),
        ));

    // Repositories - using prefixed imports to avoid conflicts
    getIt.registerLazySingleton<domain.ChatRepository>(() => ChatRepositoryImpl(
          localDataSource: getIt<ChatLocalDataSource>(),
          fileProvider: getIt<UnifiedFileProvider>(),
          chatParser: getIt<ChatParser>(),
        ));

    getIt.registerLazySingleton<analysis_repo.AnalysisRepository>(() => analysis_repo.AnalysisRepositoryImpl(
          localDataSource: getIt<ChatLocalDataSource>(),
        ));

    // ========================================================================
    // ANALYSIS LAYER
    // ========================================================================
    
    // Core Analyzers
    getIt.registerFactory<MessageAnalyzer>(() => MessageAnalyzer());
    getIt.registerFactory<TimeAnalyzer>(() => TimeAnalyzer());
    getIt.registerFactory<UserAnalyzer>(() => UserAnalyzer());
    getIt.registerFactory<ContentAnalyzer>(() => ContentAnalyzer());

    // Enhanced Analyzers
    getIt.registerFactory<ConversationDynamicsAnalyzer>(() => ConversationDynamicsAnalyzer());
    getIt.registerFactory<BehaviorPatternAnalyzer>(() => BehaviorPatternAnalyzer());
    getIt.registerFactory<RelationshipAnalyzer>(() => RelationshipAnalyzer());
    getIt.registerFactory<ContentIntelligenceAnalyzer>(() => ContentIntelligenceAnalyzer());
    getIt.registerFactory<TemporalInsightAnalyzer>(() => TemporalInsightAnalyzer());

    // New Enhanced Analyzers (Phase 1 - LLM prep)
    getIt.registerFactory<LinguisticAnalyzer>(() => LinguisticAnalyzer());
    getIt.registerFactory<EmotionalIntelligenceAnalyzer>(() => EmotionalIntelligenceAnalyzer());
    getIt.registerFactory<AttachmentPatternAnalyzer>(() => AttachmentPatternAnalyzer());
    getIt.registerFactory<PersonalityTraitAnalyzer>(() => PersonalityTraitAnalyzer());

    // ========================================================================
    // SERVICES
    // ========================================================================

    // Stats Aggregator for LLM preparation
    getIt.registerLazySingleton<StatsAggregator>(() => StatsAggregator());

    // AI Insights Service - auto-configured with API key
    final aiInsightsService = AIInsightsService(
      statsAggregator: getIt<StatsAggregator>(),
    );
    // Auto-configure with DeepSeek API key if available
    if (ApiConfig.isDeepSeekConfigured) {
      aiInsightsService.configure(
        apiKey: ApiConfig.deepseekApiKey,
        providerType: LLMProviderType.deepseek,
      );
      debugPrint("🤖 AI Insights configured with DeepSeek API");
    }
    getIt.registerLazySingleton<AIInsightsService>(() => aiInsightsService);

    // ========================================================================
    // USE CASES
    // ========================================================================
    
    // Import use cases
    getIt.registerFactory<ImportChatUseCase>(() => ImportChatUseCase(
          getIt<domain.ChatRepository>(),
        ));

    getIt.registerFactory<GetChatsUseCase>(() => GetChatsUseCase(
          getIt<domain.ChatRepository>(),
        ));

    getIt.registerFactory<DeleteChatUseCase>(() => DeleteChatUseCase(
          getIt<domain.ChatRepository>(),
        ));

    // Analysis use cases - Include all analyzers with correct types
    getIt.registerFactory<AnalyzeChatUseCase>(() => AnalyzeChatUseCase(
          chatRepository: getIt<domain.ChatRepository>(),
          analysisRepository: getIt<analysis_repo.AnalysisRepository>(),
          messageAnalyzer: getIt<MessageAnalyzer>(),
          timeAnalyzer: getIt<TimeAnalyzer>(),
          userAnalyzer: getIt<UserAnalyzer>(),
          contentAnalyzer: getIt<ContentAnalyzer>(),
          conversationDynamicsAnalyzer: getIt<ConversationDynamicsAnalyzer>(),
          behaviorPatternAnalyzer: getIt<BehaviorPatternAnalyzer>(),
          relationshipAnalyzer: getIt<RelationshipAnalyzer>(),
          contentIntelligenceAnalyzer: getIt<ContentIntelligenceAnalyzer>(),
          temporalInsightAnalyzer: getIt<TemporalInsightAnalyzer>(),
          // Phase 1 LLM-prep analyzers
          linguisticAnalyzer: getIt<LinguisticAnalyzer>(),
          emotionalIntelligenceAnalyzer: getIt<EmotionalIntelligenceAnalyzer>(),
          attachmentPatternAnalyzer: getIt<AttachmentPatternAnalyzer>(),
          personalityTraitAnalyzer: getIt<PersonalityTraitAnalyzer>(),
        ));

    // Reports use cases
    getIt.registerFactory<GenerateReportUseCase>(() => GenerateReportUseCase(
          analysisRepository: getIt<analysis_repo.AnalysisRepository>(),
        ));

    getIt.registerFactory<ShareReportUseCase>(() => ShareReportUseCase());
    getIt.registerFactory<DeleteReportUseCase>(() => DeleteReportUseCase());
    getIt.registerFactory<GetReportHistoryUseCase>(() => GetReportHistoryUseCase());

    debugPrint("✅ Dependencies initialized successfully");
    _logRegisteredServices();
    
  } catch (e, stackTrace) {
    debugPrint("❌ Error initializing dependencies: $e");
    debugPrint("Stack trace: $stackTrace");
    rethrow;
  }
}

// ============================================================================
// HELPER METHODS
// ============================================================================

/// Log all registered services for debugging
void _logRegisteredServices() {
  debugPrint("📋 Registered services:");
  debugPrint("  - ChatLocalDataSource: ${getIt.isRegistered<ChatLocalDataSource>()}");
  debugPrint("  - UnifiedFileProvider: ${getIt.isRegistered<UnifiedFileProvider>()}");
  debugPrint("  - ChatRepository: ${getIt.isRegistered<domain.ChatRepository>()}");
  debugPrint("  - AnalysisRepository: ${getIt.isRegistered<analysis_repo.AnalysisRepository>()}");
  debugPrint("  - Core Analyzers: 4 registered");
  debugPrint("  - Enhanced Analyzers: 9 registered (5 base + 4 LLM-prep)");
  debugPrint("  - Use Cases: 8 registered");
}

/// Clean up dependencies (useful for testing)
Future<void> cleanupDependencies() async {
  debugPrint("🧹 Cleaning up dependencies...");
  
  try {
    // Dispose file provider if needed
    if (getIt.isRegistered<UnifiedFileProvider>()) {
      final fileProvider = getIt<UnifiedFileProvider>();
      fileProvider.dispose();
    }
    
    // Reset GetIt
    await getIt.reset();
    debugPrint("✅ Dependencies cleaned up successfully");
  } catch (e) {
    debugPrint("⚠️ Error during cleanup: $e");
  }
}