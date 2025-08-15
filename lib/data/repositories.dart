import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../shared/domain.dart';
import '../shared/models.dart';
import '../core/utils.dart';
import 'local.dart';
import 'parsers/chat_parser.dart';
import '../features/import/providers/unified_file_provider.dart';

// ============================================================================
// CHAT REPOSITORY IMPLEMENTATION
// ============================================================================
class ChatRepositoryImpl implements ChatRepository {
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
  Future<Map<String, dynamic>?> getAnalysisResults(String chatId) async {
    return await localDataSource.getAnalysisResults(chatId);
  }

  @override
  Future<void> saveAnalysisResults(String chatId, Map<String, dynamic> results) async {
    await localDataSource.saveAnalysisResults(chatId, results);
  }

  @override
  Future<void> deleteAnalysisResults(String chatId) async {
    // Implementation handled by local data source
    await localDataSource.deleteChat(chatId);
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
            _tableCell(summary['totalUsers']?.toString() ?? '0'),
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
    final participants = (results['messagesByUser'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
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
        pw.Text('Peak Activity', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Peak Hour: ${timeAnalysis['peakHour']?['timeRange'] ?? 'Unknown'}'),
        pw.Text('Peak Day: ${timeAnalysis['peakDay']?['dayName'] ?? 'Unknown'}'),
      ],
    );
  }
  
  pw.Widget _buildContentAnalysis(Map<String, dynamic> results) {
    final contentAnalysis = results['contentAnalysis'] ?? {};
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Content Overview', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Total Words: ${contentAnalysis['totalWords'] ?? 0}'),
        pw.Text('Total Emojis: ${contentAnalysis['totalEmojis'] ?? 0}'),
        pw.Text('Total Media: ${contentAnalysis['totalMedia'] ?? 0}'),
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