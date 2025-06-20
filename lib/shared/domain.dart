// shared/domain.dart
// Consolidated: All entities + repository interfaces

import 'dart:io';
export '../features/analysis/analysis_repository.dart';

// ============================================================================
// ENTITIES
// ============================================================================

// Message Entity
enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  sticker,
  contact,
  location,
  unknown
}

class MessageEntity {
  final String id;
  final String senderId;
  final DateTime timestamp;
  final MessageType type;
  final String content;
  final bool isDeleted;
  final Map<String, dynamic> metadata;

  MessageEntity({
    required this.id,
    required this.senderId,
    required this.timestamp,
    required this.type,
    required this.content,
    this.isDeleted = false,
    this.metadata = const {},
  });
}

// User Entity
class UserEntity {
  final String id;
  final String name;
  final String? phoneNumber;

  UserEntity({
    required this.id,
    required this.name,
    this.phoneNumber,
  });
}

// Chat Entity
class ChatEntity {
  final String id;
  final String title;
  final DateTime importDate;
  final List<UserEntity> users;
  final List<MessageEntity> messages;
  final DateTime firstMessageDate;
  final DateTime lastMessageDate;

  ChatEntity({
    required this.id,
    required this.title,
    required this.importDate,
    required this.users,
    required this.messages,
    required this.firstMessageDate,
    required this.lastMessageDate,
  });
}

// ============================================================================
// REPOSITORY INTERFACES
// ============================================================================

// Chat Repository Interface
abstract class ChatRepository {
  Future<ChatEntity> importChat(File file);
  Future<List<ChatEntity>> getImportedChats();
  Future<ChatEntity?> getChatById(String id);
  Future<void> deleteChat(String id);
}

// Analysis Repository Interface
abstract class AnalysisRepository {
  Future<Map<String, dynamic>> getAnalysisResults(String chatId);
  Future<void> saveAnalysisResults(String chatId, Map<String, dynamic> results);
  Future<File> generateReport(String chatId, Map<String, dynamic> results);
}