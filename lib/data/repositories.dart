// data/repositories.dart
// Consolidated: chat_repository_impl.dart + analysis_repository_impl.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../shared/domain.dart';
import '../shared/models.dart';
import '../core/utils.dart';
import 'local.dart';
import 'parsers.dart';
import '../features/import/import_feature.dart';

// ============================================================================
// CHAT REPOSITORY IMPLEMENTATION
// ============================================================================
class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource localDataSource;
  final FileProvider fileProvider;
  final ChatParser chatParser;

  ChatRepositoryImpl({
    required this.localDataSource,
    required this.fileProvider,
    required this.chatParser,
  });

  @override
  Future<ChatEntity> importChat(File file) async {
    debugPrint("Importing file: ${file.path}");
    
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
          debugPrint("ZIP detection by content: $isZip");
        } catch (e) {
          debugPrint("Error checking file header: $e");
        }
      }
      
      if (isZip) {
        debugPrint("File is a ZIP archive, extracting...");
        final chatFile = await ZipUtils.extractWhatsAppChatFromZip(file);
        if (chatFile == null) {
          throw Exception('Could not find chat file in the ZIP archive');
        }
        debugPrint("Using extracted file: ${chatFile.path}");
        final chat = await chatParser.parseChat(chatFile);
        await localDataSource.saveChat(chat);
        return chat.toEntity();
      } else {
        // Regular file processing
        debugPrint("Processing as regular file");
        final chat = await chatParser.parseChat(file);
        await localDataSource.saveChat(chat);
        return chat.toEntity();
      }
    } catch (e) {
      debugPrint("Error importing chat: $e");
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

// ============================================================================
// ANALYSIS REPOSITORY IMPLEMENTATION
// ============================================================================
class AnalysisRepositoryImpl implements AnalysisRepository {
  final ChatLocalDataSource localDataSource;

  AnalysisRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Map<String, dynamic>> getAnalysisResults(String chatId) async {
    final result = await localDataSource.getAnalysisResult(chatId);
    if (result != null) {
      return result.results;
    }
    return {};
  }

  @override
  Future<void> saveAnalysisResults(String chatId, Map<String, dynamic> results) async {
    final analysisResult = AnalysisResult(
      chatId: chatId,
      analysisDate: DateTime.now(),
      results: results,
    );
    await localDataSource.saveAnalysisResult(analysisResult);
  }

  @override
  Future<File> generateReport(String chatId, Map<String, dynamic> results) async {
    final chat = await localDataSource.getChatById(chatId);
    
    if (chat == null) {
      throw Exception('Chat not found');
    }
    
    final pdf = pw.Document();
    
    // Add title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Chat Analysis Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text(chat.title, style: pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 10),
                pw.Text('Generated on ${DateTime.now().toString().split('.')[0]}'),
              ],
            ),
          );
        },
      ),
    );
    
    // Add summary page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                _buildSummaryTable(results),
                pw.SizedBox(height: 30),
                pw.Text('Participants', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                _buildParticipantsTable(results),
              ],
            ),
          );
        },
      ),
    );
    
    // Add time analysis
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Time Analysis', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                _buildTimeAnalysis(results),
              ],
            ),
          );
        },
      ),
    );
    
    // Add content analysis
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Content Analysis', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                _buildContentAnalysis(results),
              ],
            ),
          );
        },
      ),
    );
    
    // Save to file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/chat_analysis_${chatId}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  pw.Widget _buildSummaryTable(Map<String, dynamic> results) {
    final summary = results['summary'] ?? {};
    
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            _tableCellHeader('Metric'),
            _tableCellHeader('Value'),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell('Total Messages'),
            _tableCell(summary['totalMessages']?.toString() ?? '0'),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell('Date Range'),
            _tableCell(summary['dateRange'] ?? 'N/A'),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell('Total Participants'),
            _tableCell(summary['totalParticipants']?.toString() ?? '0'),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell('Total Media'),
            _tableCell(summary['totalMedia']?.toString() ?? '0'),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell('Average Messages per Day'),
            _tableCell(summary['avgMessagesPerDay']?.toString() ?? '0'),
          ],
        ),
      ],
    );
  }
  
  pw.Widget _buildParticipantsTable(Map<String, dynamic> results) {
    final participants = (results['participants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            _tableCellHeader('Name'),
            _tableCellHeader('Messages'),
            _tableCellHeader('Percentage'),
          ],
        ),
        ...participants.map((participant) {
          return pw.TableRow(
            children: [
              _tableCell(participant['name'] ?? ''),
              _tableCell(participant['messageCount']?.toString() ?? '0'),
              _tableCell('${participant['percentage']?.toString() ?? '0'}%'),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  pw.Widget _buildTimeAnalysis(Map<String, dynamic> results) {
    final timeAnalysis = results['timeAnalysis'] ?? {};
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Messages by Day of Week', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        _buildDayOfWeekTable(timeAnalysis['dayOfWeek'] ?? {}),
        pw.SizedBox(height: 20),
        pw.Text('Messages by Hour', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        _buildHourTable(timeAnalysis['hourOfDay'] ?? {}),
      ],
    );
  }
  
  pw.Widget _buildDayOfWeekTable(Map<String, dynamic> dayData) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            _tableCellHeader('Day'),
            _tableCellHeader('Count'),
          ],
        ),
        ...days.map((day) {
          return pw.TableRow(
            children: [
              _tableCell(day),
              _tableCell(dayData[day]?.toString() ?? '0'),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  pw.Widget _buildHourTable(Map<String, dynamic> hourData) {
    final hours = List.generate(24, (i) => i.toString().padLeft(2, '0'));
    
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            _tableCellHeader('Hour'),
            _tableCellHeader('Count'),
          ],
        ),
        ...hours.map((hour) {
          return pw.TableRow(
            children: [
              _tableCell('$hour:00'),
              _tableCell(hourData[hour]?.toString() ?? '0'),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  pw.Widget _buildContentAnalysis(Map<String, dynamic> results) {
    final contentAnalysis = results['contentAnalysis'] ?? {};
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Top Words', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        _buildTopWordsTable(contentAnalysis['topWords'] ?? []),
        pw.SizedBox(height: 20),
        pw.Text('Emoji Usage', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        _buildEmojiTable(contentAnalysis['topEmojis'] ?? []),
      ],
    );
  }
  
  pw.Widget _buildTopWordsTable(List<dynamic> topWords) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            _tableCellHeader('Word'),
            _tableCellHeader('Count'),
          ],
        ),
        ...topWords.take(20).map((word) {
          return pw.TableRow(
            children: [
              _tableCell(word['word'] ?? ''),
              _tableCell(word['count']?.toString() ?? '0'),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  pw.Widget _buildEmojiTable(List<dynamic> topEmojis) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          children: [
            _tableCellHeader('Emoji'),
            _tableCellHeader('Count'),
          ],
        ),
        ...topEmojis.take(20).map((emoji) {
          return pw.TableRow(
            children: [
              _tableCell(emoji['emoji'] ?? ''),
              _tableCell(emoji['count']?.toString() ?? '0'),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  pw.Widget _tableCellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
  
  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}