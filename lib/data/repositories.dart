import 'dart:io';
import '../shared/domain.dart';
import '../core/logger.dart';
import '../core/utils.dart';
import 'local.dart';
import 'parsers/chat_parser.dart';
import '../features/import/providers/unified_file_provider.dart';

// ============================================================================
// CHAT REPOSITORY IMPLEMENTATION
// ============================================================================
class ChatRepositoryImpl implements ChatRepository {
  static const String _tag = 'ChatRepository';

  final ChatLocalDataSource localDataSource;
  final UnifiedFileProvider fileProvider;
  final ChatParser chatParser;

  ChatRepositoryImpl({
    required this.localDataSource,
    required this.fileProvider,
    required this.chatParser,
  });

  @override
  Future<ChatEntity> importChat(File file) async {
    AppLogger.info('Importing file: ${file.path}', tag: _tag);

    try {
      // Check if file is a ZIP file by extension or content
      bool isZip = file.path.toLowerCase().endsWith('.zip');

      if (!isZip) {
        try {
          final headerBytes = await file.openRead(0, 4).first;
          isZip = headerBytes.length >= 4 &&
                  headerBytes[0] == 0x50 &&
                  headerBytes[1] == 0x4B &&
                  headerBytes[2] == 0x03 &&
                  headerBytes[3] == 0x04;
          AppLogger.debug('ZIP detection by content: $isZip', tag: _tag);
        } catch (e) {
          AppLogger.warning('Error checking file header: $e', tag: _tag);
        }
      }

      if (isZip) {
        AppLogger.info('File is a ZIP archive, extracting...', tag: _tag);
        final chatFile = await ZipUtils.extractWhatsAppChatFromZip(file);
        if (chatFile == null) {
          throw Exception('Could not find chat file in the ZIP archive');
        }
        AppLogger.debug('Using extracted file: ${chatFile.path}', tag: _tag);
        final chat = await chatParser.parseChat(chatFile);
        await localDataSource.saveChat(chat);
        return chat.toEntity();
      } else {
        // Regular file processing
        AppLogger.debug('Processing as regular file', tag: _tag);
        final chat = await chatParser.parseChat(file);
        await localDataSource.saveChat(chat);
        return chat.toEntity();
      }
    } catch (e) {
      AppLogger.error('Error importing chat', tag: _tag, error: e);
      throw Exception('Failed to import chat: $e');
    }
  }

  @override
  Future<List<ChatEntity>> getImportedChats() async {
    final chats = await localDataSource.getChats();
    return chats.map((chat) => chat.toEntity()).toList();
  }

  @override
  Future<ChatEntity?> getChatById(String id) async {
    final chat = await localDataSource.getChatById(id);
    return chat?.toEntity();
  }

  @override
  Future<void> deleteChat(String id) async {
    await localDataSource.deleteChat(id);
  }
}

// NOTE: AnalysisRepositoryImpl has been moved to:
// lib/features/analysis/analysis_repository.dart