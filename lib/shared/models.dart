import 'domain.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

// Message Model
class Message {
  final String id;
  final String senderId;
  final DateTime timestamp;
  final MessageType type;
  final String content;
  final bool isDeleted;
  final Map<String, dynamic> metadata;

  Message({
    required this.id,
    required this.senderId,
    required this.timestamp,
    required this.type,
    required this.content,
    this.isDeleted = false,
    this.metadata = const {},
  });

  factory Message.fromEntity(MessageEntity entity) {
    return Message(
      id: entity.id,
      senderId: entity.senderId,
      timestamp: entity.timestamp,
      type: entity.type,
      content: entity.content,
      isDeleted: entity.isDeleted,
      metadata: entity.metadata,
    );
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      senderId: senderId,
      timestamp: timestamp,
      type: type,
      content: content,
      isDeleted: isDeleted,
      metadata: metadata,
    );
  }
}

// User Model
class User {
  final String id;
  final String name;
  final String? phoneNumber;

  User({
    required this.id,
    required this.name,
    this.phoneNumber,
  });

  factory User.fromEntity(UserEntity entity) {
    return User(
      id: entity.id,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
    );
  }
}

// Chat Model
class Chat {
  final String id;
  final String title;
  final DateTime importDate;
  final List<User> users;
  final List<Message> messages;
  final DateTime firstMessageDate;
  final DateTime lastMessageDate;

  Chat({
    required this.id,
    required this.title,
    required this.importDate,
    required this.users,
    required this.messages,
    required this.firstMessageDate,
    required this.lastMessageDate,
  });

  factory Chat.fromEntity(ChatEntity entity) {
    return Chat(
      id: entity.id,
      title: entity.title,
      importDate: entity.importDate,
      users: entity.users.map((u) => User.fromEntity(u)).toList(),
      messages: entity.messages.map((m) => Message.fromEntity(m)).toList(),
      firstMessageDate: entity.firstMessageDate,
      lastMessageDate: entity.lastMessageDate,
    );
  }

  ChatEntity toEntity() {
    return ChatEntity(
      id: id,
      title: title,
      importDate: importDate,
      users: users.map((u) => u.toEntity()).toList(),
      messages: messages.map((m) => m.toEntity()).toList(),
      firstMessageDate: firstMessageDate,
      lastMessageDate: lastMessageDate,
    );
  }
}

// ============================================================================
// ANALYSIS RESULT MODEL
// ============================================================================

class AnalysisResult {
  final String chatId;
  final DateTime analysisDate;
  final Map<String, dynamic> results;

  AnalysisResult({
    required this.chatId,
    required this.analysisDate,
    required this.results,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      chatId: json['chatId'],
      analysisDate: DateTime.parse(json['analysisDate']),
      results: json['results'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'analysisDate': analysisDate.toIso8601String(),
      'results': results,
    };
  }
}