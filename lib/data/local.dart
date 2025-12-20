// ============================================================================
// FILE: data/local.dart
// In-Memory Storage - No Hive, No Blocking!
// ============================================================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../shared/models.dart';

abstract class ChatLocalDataSource {
  Future<void> saveChat(Chat chat);
  Future<List<Chat>> getChats();
  Future<Chat?> getChatById(String id);
  Future<void> deleteChat(String id);
  Future<void> saveAnalysisResults(String chatId, Map<String, dynamic> results);
  Future<Map<String, dynamic>?> getAnalysisResults(String chatId);
  Future<void> deleteAnalysisResults(String chatId);
  Future<List<String>> getAnalyzedChatIds();
  Future<File> generateReport(String chatId, Map<String, dynamic> results);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  // In-memory storage - No Hive!
  final Map<String, Chat> _chatsInMemory = {};
  final Map<String, Map<String, dynamic>> _analysisInMemory = {};

  ChatLocalDataSourceImpl() {
    debugPrint("✅ ChatLocalDataSource: Using in-memory storage (no Hive)");
  }

  @override
  Future<void> saveChat(Chat chat) async {
    debugPrint("💾 Saving chat in memory: ${chat.id} (${chat.messages.length} messages)");
    _chatsInMemory[chat.id] = chat;
    debugPrint("✅ Chat saved in memory successfully");
  }

  @override
  Future<List<Chat>> getChats() async {
    debugPrint("📋 Getting all chats from memory");
    final chats = _chatsInMemory.values.toList();
    debugPrint("✅ Retrieved ${chats.length} chats from memory");
    return chats;
  }

  @override
  Future<Chat?> getChatById(String id) async {
    debugPrint("🔍 Getting chat by ID from memory: $id");
    final chat = _chatsInMemory[id];
    if (chat == null) {
      debugPrint("⚠️ Chat not found in memory");
      return null;
    }
    debugPrint("✅ Chat retrieved from memory successfully");
    return chat;
  }

  @override
  Future<void> deleteChat(String id) async {
    debugPrint("🗑️ Deleting chat from memory: $id");
    _chatsInMemory.remove(id);
    _analysisInMemory.remove(id);
    debugPrint("✅ Chat deleted from memory successfully");
  }

  @override
  Future<void> saveAnalysisResults(String chatId, Map<String, dynamic> results) async {
    debugPrint("💾 Saving analysis results in memory for chat: $chatId");
    _analysisInMemory[chatId] = results;
    debugPrint("✅ Analysis results saved in memory successfully");
  }

  @override
  Future<Map<String, dynamic>?> getAnalysisResults(String chatId) async {
    debugPrint("📖 Getting analysis results from memory for chat: $chatId");
    final results = _analysisInMemory[chatId];
    if (results == null) {
      debugPrint("⚠️ Analysis results not found in memory");
      return null;
    }
    debugPrint("✅ Analysis results retrieved from memory");
    return results;
  }

  @override
  Future<void> deleteAnalysisResults(String chatId) async {
    debugPrint("🗑️ Deleting analysis results from memory: $chatId");
    _analysisInMemory.remove(chatId);
    debugPrint("✅ Analysis results deleted from memory");
  }

  @override
  Future<List<String>> getAnalyzedChatIds() async {
    debugPrint("📋 Getting analyzed chat IDs from memory");
    final ids = _analysisInMemory.keys.toList();
    debugPrint("✅ Retrieved ${ids.length} analyzed chat IDs from memory");
    return ids;
  }

  @override
  Future<File> generateReport(String chatId, Map<String, dynamic> results) async {
    throw UnimplementedError('Report generation handled by AnalysisRepository.generateReport');
  }
}
