import 'dart:io';
import '../../shared/models.dart';
import 'whatsapp_text_parser.dart';
import 'whatsapp_html_parser.dart';

abstract class ChatParser {
  Future<Chat> parseChat(File file);
}

class ChatParserImpl implements ChatParser {
  final WhatsAppTextParser textParser;
  final WhatsAppHtmlParser htmlParser;

  ChatParserImpl({
    required this.textParser,
    required this.htmlParser,
  });

  @override
  Future<Chat> parseChat(File file) async {
    // Read a sample to determine file type
    final sample = await file.openRead(0, 1024).join();

    if (sample.contains("<html") || sample.contains("<!DOCTYPE") || sample.contains("WhatsApp Chat")) {
      return htmlParser.parse(file);
    } else {
      return textParser.parse(file);
    }
  }
}