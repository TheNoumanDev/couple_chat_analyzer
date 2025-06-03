// features/import/import_ui.dart
// Consolidated: import_page.dart + home_page.dart + related widgets

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../widgets/common.dart';
import '../analysis/analysis_ui.dart';
import 'import_feature.dart';

// ============================================================================
// HOME PAGE
// ============================================================================
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ImportBloc _importBloc;

  @override
  void initState() {
    super.initState();
    _importBloc = ImportBloc(
      importChatUseCase: GetIt.instance.get(),
      fileProvider: GetIt.instance.get(),
    );
  }

  @override
  void dispose() {
    _importBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _importBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ChatInsight'),
        ),
        body: BlocConsumer<ImportBloc, ImportState>(
          listener: (context, state) async {
            if (state is ImportSuccess) {
              debugPrint("Home page received ImportSuccess state, navigating to analysis page");
              
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalysisPage(chatId: state.chat.id),
                ),
                (route) => false,
              );
            }
          },
          builder: (context, state) {
            if (state is ImportLoading) {
              return const LoadingIndicator(
                message: 'Processing chat file...',
              );
            }
            
            if (state is ImportError) {
              return ErrorView(
                message: state.message,
                onRetry: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                ),
              );
            }
            
            return _buildHomeContent(context);
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ImportPage()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Import Chat'),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return FutureBuilder(
      future: Future.value([]), // TODO: Get imported chats from repository
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        
        final chats = snapshot.data ?? [];
        
        if (chats.isEmpty) {
          return _buildEmptyState(context);
        }
        
        return _buildChatList(context, chats);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 120,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Chats Imported Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Import a WhatsApp chat to get started with detailed analysis',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImportPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Import Your First Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(BuildContext context, List chats) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.chat,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(chat.title),
            subtitle: Text('${chat.messages.length} messages'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalysisPage(chatId: chat.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================================
// IMPORT PAGE
// ============================================================================
class ImportPage extends StatelessWidget {
  const ImportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: BlocProvider.of<ImportBloc>(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import Chat'),
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
              return const LoadingIndicator(
                message: 'Processing chat file...',
              );
            }
            
            if (state is ImportError) {
              return ErrorView(
                message: state.message,
                onRetry: () => context.read<ImportBloc>().add(PickFileEvent()),
              );
            }
            
            if (state is FileSelected) {
              return _buildFileSelectedView(context, state.file);
            }
            
            return _buildImportInstructions(context);
          },
        ),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Color(0xFF25D366), // WhatsApp green
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'How to Export WhatsApp Chat',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Follow these simple steps to export your chat',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildInstructionStep(
              context,
              number: 1,
              title: 'Open WhatsApp',
              description: 'Go to the chat you want to analyze',
              icon: Icons.phone_android,
            ),
            _buildInstructionStep(
              context,
              number: 2,
              title: 'Open Menu',
              description: 'Tap the three dots in the top right corner',
              icon: Icons.more_vert,
            ),
            _buildInstructionStep(
              context,
              number: 3,
              title: 'More Options',
              description: 'Tap "More" in the menu',
              icon: Icons.more_horiz,
            ),
            _buildInstructionStep(
              context,
              number: 4,
              title: 'Export Chat',
              description: 'Choose "Export chat" (without media is faster)',
              icon: Icons.file_upload,
            ),
            _buildInstructionStep(
              context,
              number: 5,
              title: 'Share with ChatInsight',
              description: 'Choose ChatInsight from the share menu or select file manually',
              icon: Icons.share,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<ImportBloc>().add(PickFileEvent());
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Select Chat File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Supports .txt, .html, and .zip files from WhatsApp export',
                      style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildInstructionStep(
    BuildContext context, {
    required int number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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