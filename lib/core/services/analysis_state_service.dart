// ============================================================================
// FILE: lib/core/services/analysis_state_service.dart
// Service for tracking analysis initialization state across widget instances
// ============================================================================

/// Service that tracks which chats are currently being initialized/analyzed.
///
/// This prevents duplicate initialization when the same AnalysisPage is
/// rebuilt or navigated to multiple times.
class AnalysisStateService {
  AnalysisStateService._();

  static final AnalysisStateService _instance = AnalysisStateService._();
  static AnalysisStateService get instance => _instance;

  /// Set of chat IDs that have been initialized
  final Set<String> _initializedChats = <String>{};

  /// Flag to prevent concurrent initialization
  bool _isInitializing = false;

  /// Check if a chat is already initialized
  bool isInitialized(String chatId) => _initializedChats.contains(chatId);

  /// Check if any initialization is in progress
  bool get isInitializing => _isInitializing;

  /// Try to start initialization for a chat
  /// Returns true if initialization can proceed, false if it should be skipped
  bool tryStartInitialization(String chatId) {
    if (_initializedChats.contains(chatId) || _isInitializing) {
      return false;
    }
    _isInitializing = true;
    return true;
  }

  /// Mark a chat as initialized
  void markInitialized(String chatId) {
    _initializedChats.add(chatId);
    _isInitializing = false;
  }

  /// Mark initialization as complete (without success)
  void endInitialization() {
    _isInitializing = false;
  }

  /// Remove a chat from the initialized set (on dispose)
  void removeInitialized(String chatId) {
    _initializedChats.remove(chatId);
  }

  /// Clear all tracked state (useful for testing)
  void reset() {
    _initializedChats.clear();
    _isInitializing = false;
  }
}
