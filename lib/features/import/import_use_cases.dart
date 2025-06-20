import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../shared/domain.dart';

class ImportChatUseCase {
  final ChatRepository repository;

  ImportChatUseCase(this.repository);

  Future<ChatEntity> call(File file) async {
    debugPrint("ImportChatUseCase: Starting import for file: ${file.path}");

    try {
      final chat = await repository.importChat(file);
      
      debugPrint("ImportChatUseCase: Import completed successfully");
      debugPrint("  - Messages: ${chat.messages.length}");
      debugPrint("  - Users: ${chat.users.length}");
      debugPrint("  - Date range: ${chat.firstMessageDate} to ${chat.lastMessageDate}");

      return chat;
    } catch (e, stackTrace) {
      debugPrint("ImportChatUseCase: Import failed with error: $e");
      debugPrint("Stack trace: $stackTrace");
      rethrow;
    }
  }
}
