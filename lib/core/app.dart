import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/import/ui/home_page.dart';

// ============================================================================
// APP CONSTANTS
// ============================================================================
class AppConstants {
  static const String appName = 'ChatInsight';
  static const String appVersion = '1.0.0';
  
  // Hive box names
  static const String chatsBoxName = 'chats';
  static const String analysisBoxName = 'analysis_results';
  
  // File types
  static const List<String> supportedFileExtensions = ['txt', 'html', 'zip'];
  static const List<String> supportedMimeTypes = ['text/plain', 'text/html'];
  
  // Default folder name for saved reports
  static const String reportsFolderName = 'ChatInsight Reports';
  
  // Analytics event names (for future use)
  static const String eventChatImported = 'chat_imported';
  static const String eventAnalysisCompleted = 'analysis_completed';
  static const String eventReportGenerated = 'report_generated';
  static const String eventReportShared = 'report_shared';
}

// ============================================================================
// APP THEME
// ============================================================================
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF25D366), // WhatsApp green
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF25D366),
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  );
}

// ============================================================================
// MAIN APP
// ============================================================================
class ChatInsightApp extends StatelessWidget {
  const ChatInsightApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}