import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/common.dart';
import '../../analysis/ui/analysis_page.dart';
import '../import_bloc.dart';
import '../import_models.dart';

class ImportPage extends StatelessWidget {
  const ImportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Chat'),
        centerTitle: true,
      ),
      body: BlocConsumer<ImportBloc, ImportState>(
        listener: (context, state) async {
          if (state is ImportSuccess) {
            try {
              debugPrint("Import page received ImportSuccess state with chat ID: ${state.chat.id}");
              debugPrint("Chat has ${state.chat.messages.length} messages and ${state.chat.users.length} users");
              
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) {
                    debugPrint("Building AnalysisPage route with chatId: ${state.chat.id}");
                    return AnalysisPage(chatId: state.chat.id);
                  },
                ),
              );
              debugPrint("Navigation to AnalysisPage completed");
            } catch (e) {
              debugPrint("ERROR during navigation: $e");
            }
          }
        },
        builder: (context, state) {
          if (state is ImportLoading) {
            return LoadingIndicator(
              message: state.message,
            );
          }
          
          if (state is ImportError) {
            return ErrorView(
              title: 'Import Error',
              message: state.message,
              technicalDetails: state.technicalDetails,
              onRetry: () => context.read<ImportBloc>().add(PickFileEvent()),
            );
          }
          
          if (state is FileSelected) {
            return _buildFileSelectedView(context, state.file);
          }
          
          return _buildImportInstructions(context);
        },
      ),
    );
  }

  Widget _buildImportInstructions(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Instruction Steps
            _buildInstructionStep(
              context,
              1,
              'Export your chat',
              'Open WhatsApp and export your chat as a text file',
              Icons.chat,
            ),
            
            const SizedBox(height: 24),
            
            _buildInstructionStep(
              context,
              2,
              'Choose the file',
              'Select the exported chat file from your device',
              Icons.file_upload,
            ),
            
            const SizedBox(height: 24),
            
            _buildInstructionStep(
              context,
              3,
              'Analyze',
              'Get insights about your conversation patterns',
              Icons.analytics,
            ),
            
            const SizedBox(height: 48),
            
            // File Picker Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<ImportBloc>().add(PickFileEvent());
                },
                icon: const Icon(Icons.file_upload),
                label: const Text('Choose Chat File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Supported formats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Supported Formats',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Text files (.txt)\n• HTML files (.html)\n• ZIP archives (.zip)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(
    BuildContext context,
    int number,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelectedView(BuildContext context, File file) {
    final fileName = file.path.split('/').last;
    final fileSize = file.lengthSync();
    final fileSizeKB = (fileSize / 1024).round();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'File Selected Successfully',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${fileSizeKB} KB',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<ImportBloc>().add(ImportFileEvent(file));
                },
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Analyze Chat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<ImportBloc>().add(PickFileEvent());
                },
                icon: const Icon(Icons.file_upload),
                label: const Text('Choose Another File'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your chat data is processed locally and never sent to external servers',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}