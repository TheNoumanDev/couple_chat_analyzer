// ============================================================================
// FILE: data/local.dart
// Complete local data source with all missing methods
// ============================================================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../shared/models.dart';
import '../shared/domain.dart';

abstract class ChatLocalDataSource {
  Future<void> initDatabase();
  Future<void> saveChat(Chat chat);
  Future<List<Chat>> getChats();
  Future<Chat?> getChatById(String id);
  Future<void> deleteChat(String id);
  Future<void> saveAnalysisResults(String chatId, Map<String, dynamic> results);
  Future<Map<String, dynamic>?> getAnalysisResults(String chatId);
  Future<void> deleteAnalysisResults(String chatId); // Added missing method
  Future<List<String>> getAnalyzedChatIds(); // Added missing method
  Future<File> generateReport(String chatId, Map<String, dynamic> results);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  late Box<Map> _chatsBox;
  late Box<Map> _analysisBox;
  bool _initialized = false;

  @override
  Future<void> initDatabase() async {
    if (_initialized) {
      debugPrint("Database already initialized");
      return;
    }
    
    debugPrint("Initializing Hive database");
    try {
      await Hive.initFlutter();
      
      final appDocDir = await getApplicationDocumentsDirectory();
      debugPrint("App documents directory: ${appDocDir.path}");
      
      _chatsBox = await Hive.openBox<Map>('chats');
      debugPrint("Opened chats box with ${_chatsBox.values.length} items");
      
      _analysisBox = await Hive.openBox<Map>('analysis_results');
      debugPrint("Opened analysis box with ${_analysisBox.values.length} items");
      
      _initialized = true;
      debugPrint("Database initialization complete");
    } catch (e) {
      debugPrint("Error initializing database: $e");
      throw Exception('Failed to initialize database: $e');
    }
  }

  @override
  Future<void> saveChat(Chat chat) async {
    debugPrint("Saving chat: ${chat.id}");
    await _ensureInitialized();
    
    try {
      final chatMap = {
        'id': chat.id,
        'title': chat.title,
        'importDate': chat.importDate.toIso8601String(),
        'users': chat.users.map((u) => {
          'id': u.id,
          'name': u.name,
          'phoneNumber': u.phoneNumber,
        }).toList(),
        'messages': chat.messages.map((m) => {
          'id': m.id,
          'senderId': m.senderId,
          'timestamp': m.timestamp.toIso8601String(),
          'type': m.type.index,
          'content': m.content,
          'isDeleted': m.isDeleted,
          'metadata': m.metadata,
        }).toList(),
        'firstMessageDate': chat.firstMessageDate.toIso8601String(),
        'lastMessageDate': chat.lastMessageDate.toIso8601String(),
      };
      
      await _chatsBox.put(chat.id, chatMap);
      debugPrint("Chat saved successfully");
    } catch (e) {
      debugPrint("Error saving chat: $e");
      throw Exception('Failed to save chat: $e');
    }
  }

  @override
  Future<List<Chat>> getChats() async {
    debugPrint("Getting all chats");
    await _ensureInitialized();
    
    try {
      final chats = _chatsBox.values.map((map) => _mapToChat(map as Map)).toList();
      debugPrint("Retrieved ${chats.length} chats");
      return chats;
    } catch (e) {
      debugPrint("Error getting chats: $e");
      return [];
    }
  }

  @override
  Future<Chat?> getChatById(String id) async {
    debugPrint("Getting chat by ID: $id");
    await _ensureInitialized();
    
    try {
      final map = _chatsBox.get(id);
      if (map == null) {
        debugPrint("Chat not found");
        return null;
      }
      
      final chat = _mapToChat(map as Map);
      debugPrint("Chat retrieved successfully");
      return chat;
    } catch (e) {
      debugPrint("Error getting chat by ID: $e");
      return null;
    }
  }

  @override
  Future<void> deleteChat(String id) async {
    debugPrint("Deleting chat: $id");
    await _ensureInitialized();
    
    try {
      await _chatsBox.delete(id);
      await _analysisBox.delete(id);
      debugPrint("Chat deleted successfully");
    } catch (e) {
      debugPrint("Error deleting chat: $e");
      throw Exception('Failed to delete chat: $e');
    }
  }

  @override
  Future<void> saveAnalysisResults(String chatId, Map<String, dynamic> results) async {
    debugPrint("Saving analysis results for chat: $chatId");
    await _ensureInitialized();
    
    try {
      await _analysisBox.put(chatId, results);
      debugPrint("Analysis results saved successfully");
    } catch (e) {
      debugPrint("Error saving analysis results: $e");
      throw Exception('Failed to save analysis results: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getAnalysisResults(String chatId) async {
    debugPrint("Getting analysis results for chat: $chatId");
    await _ensureInitialized();
    
    try {
      final map = _analysisBox.get(chatId);
      if (map == null) {
        debugPrint("Analysis results not found");
        return null;
      }
      
      debugPrint("Analysis results retrieved successfully");
      return Map<String, dynamic>.from(map as Map);
    } catch (e) {
      debugPrint("Error getting analysis results: $e");
      return null;
    }
  }

  @override
  Future<void> deleteAnalysisResults(String chatId) async {
    debugPrint("Deleting analysis results for chat: $chatId");
    await _ensureInitialized();
    
    try {
      await _analysisBox.delete(chatId);
      debugPrint("Analysis results deleted successfully");
    } catch (e) {
      debugPrint("Error deleting analysis results: $e");
      throw Exception('Failed to delete analysis results: $e');
    }
  }

  @override
  Future<List<String>> getAnalyzedChatIds() async {
    debugPrint("Getting all analyzed chat IDs");
    await _ensureInitialized();
    
    try {
      final chatIds = _analysisBox.keys.cast<String>().toList();
      debugPrint("Retrieved ${chatIds.length} analyzed chat IDs");
      return chatIds;
    } catch (e) {
      debugPrint("Error getting analyzed chat IDs: $e");
      return [];
    }
  }

  @override
  Future<File> generateReport(String chatId, Map<String, dynamic> results) async {
    // Implementation moved to repositories.dart for PDF generation
    throw UnimplementedError('Report generation implemented in repositories.dart');
  }

  Chat _mapToChat(Map map) {
    try {
      return Chat(
        id: map['id'],
        title: map['title'],
        importDate: DateTime.parse(map['importDate']),
        users: (map['users'] as List).map((u) => User(
          id: u['id'],
          name: u['name'],
          phoneNumber: u['phoneNumber'],
        )).toList(),
        messages: (map['messages'] as List).map((m) => Message(
          id: m['id'],
          senderId: m['senderId'],
          timestamp: DateTime.parse(m['timestamp']),
          type: MessageType.values[m['type']],
          content: m['content'],
          isDeleted: m['isDeleted'],
          metadata: m['metadata'],
        )).toList(),
        firstMessageDate: DateTime.parse(map['firstMessageDate']),
        lastMessageDate: DateTime.parse(map['lastMessageDate']),
      );
    } catch (e) {
      debugPrint("Error mapping to chat: $e");
      throw Exception('Failed to map data to Chat: $e');
    }
  }
  
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      debugPrint("Database not initialized, initializing now");
      await initDatabase();
    }
  }

  // ========================================================================
  // ADDITIONAL HELPER METHODS
  // ========================================================================

  /// Clear all analysis results
  Future<void> clearAllAnalysisResults() async {
    debugPrint("Clearing all analysis results");
    await _ensureInitialized();
    
    try {
      await _analysisBox.clear();
      debugPrint("All analysis results cleared successfully");
    } catch (e) {
      debugPrint("Error clearing all analysis results: $e");
      throw Exception('Failed to clear all analysis results: $e');
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    await _ensureInitialized();
    
    try {
      return {
        'totalChats': _chatsBox.length,
        'totalAnalysisResults': _analysisBox.length,
        'databaseSize': await _calculateDatabaseSize(),
        'lastModified': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint("Error getting database stats: $e");
      return {
        'totalChats': 0,
        'totalAnalysisResults': 0,
        'databaseSize': '0 B',
        'lastModified': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Calculate approximate database size
  Future<String> _calculateDatabaseSize() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final hivePath = '${appDocDir.path}';
      final hiveDir = Directory(hivePath);
      
      int totalSize = 0;
      await for (final entity in hiveDir.list(recursive: true)) {
        if (entity is File && entity.path.contains('hive')) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return _formatBytes(totalSize);
    } catch (e) {
      debugPrint("Error calculating database size: $e");
      return '0 B';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if a chat exists
  Future<bool> chatExists(String chatId) async {
    await _ensureInitialized();
    return _chatsBox.containsKey(chatId);
  }

  /// Check if analysis results exist
  Future<bool> analysisResultsExist(String chatId) async {
    await _ensureInitialized();
    return _analysisBox.containsKey(chatId);
  }

  /// Get chat metadata only (without messages for performance)
  Future<Map<String, dynamic>?> getChatMetadata(String chatId) async {
    debugPrint("Getting chat metadata for: $chatId");
    await _ensureInitialized();
    
    try {
      final map = _chatsBox.get(chatId);
      if (map == null) {
        debugPrint("Chat metadata not found");
        return null;
      }

      final chatMap = map as Map;
      return {
        'id': chatMap['id'],
        'title': chatMap['title'],
        'importDate': chatMap['importDate'],
        'userCount': (chatMap['users'] as List).length,
        'messageCount': (chatMap['messages'] as List).length,
        'firstMessageDate': chatMap['firstMessageDate'],
        'lastMessageDate': chatMap['lastMessageDate'],
      };
    } catch (e) {
      debugPrint("Error getting chat metadata: $e");
      return null;
    }
  }

  /// Backup database to file
  Future<File?> backupDatabase() async {
    try {
      debugPrint("Creating database backup");
      await _ensureInitialized();

      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocDir.path}/backups');
      await backupDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${backupDir.path}/chatinsight_backup_$timestamp.json');

      final backup = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'chats': _chatsBox.toMap(),
        'analysisResults': _analysisBox.toMap(),
      };

      await backupFile.writeAsString(_prettyPrintJson(backup));
      debugPrint("Database backup created: ${backupFile.path}");
      
      return backupFile;
    } catch (e) {
      debugPrint("Error creating database backup: $e");
      return null;
    }
  }

  String _prettyPrintJson(Map<String, dynamic> data) {
    // Simple JSON formatting since we can't import dart:convert in this context
    return data.toString();
  }
}