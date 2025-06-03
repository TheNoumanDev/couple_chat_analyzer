// data/local.dart
// Consolidated: chat_local_data_source.dart

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
  Future<void> saveAnalysisResult(AnalysisResult result);
  Future<AnalysisResult?> getAnalysisResult(String chatId);
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
      // Initialize Hive
      await Hive.initFlutter();
      
      final appDocDir = await getApplicationDocumentsDirectory();
      debugPrint("App documents directory: ${appDocDir.path}");
      
      // Open boxes
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
  Future<void> saveAnalysisResult(AnalysisResult result) async {
    debugPrint("Saving analysis result for chat: ${result.chatId}");
    await _ensureInitialized();
    
    try {
      await _analysisBox.put(result.chatId, result.toJson());
      debugPrint("Analysis result saved successfully");
    } catch (e) {
      debugPrint("Error saving analysis result: $e");
      throw Exception('Failed to save analysis result: $e');
    }
  }

  @override
  Future<AnalysisResult?> getAnalysisResult(String chatId) async {
    debugPrint("Getting analysis result for chat: $chatId");
    await _ensureInitialized();
    
    try {
      final map = _analysisBox.get(chatId);
      if (map == null) {
        debugPrint("Analysis result not found");
        return null;
      }
      
      final result = AnalysisResult.fromJson(map as Map<String, dynamic>);
      debugPrint("Analysis result retrieved successfully");
      return result;
    } catch (e) {
      debugPrint("Error getting analysis result: $e");
      return null;
    }
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
}