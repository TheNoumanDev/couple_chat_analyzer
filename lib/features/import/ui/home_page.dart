import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../../widgets/common.dart';
import '../../analysis/ui/analysis_page.dart';
import '../../../shared/domain.dart' as domain;
import '../import_bloc.dart';
import '../import_models.dart';
import 'import_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ImportBloc _importBloc;
  // Cache the future to prevent re-fetching on every build
  late Future<List<domain.ChatEntity>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _importBloc = ImportBloc(
      importChatUseCase: GetIt.instance.get(),
      fileProvider: GetIt.instance.get(),
    );
    _refreshChats();
  }

  void _refreshChats() {
    _chatsFuture = GetIt.instance.get<domain.ChatRepository>().getImportedChats();
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
          centerTitle: true,
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
                title: 'Import Error',
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
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: _importBloc,
                  child: const ImportPage(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Import Chat'),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return FutureBuilder<List<domain.ChatEntity>>(
      future: _chatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Welcome Text
            Text(
              'Welcome to ChatInsight',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Analyze your WhatsApp conversations and discover insights about your communication patterns.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Features Grid
            _buildFeaturesGrid(context),
            
            const SizedBox(height: 48),
            
            // Get Started Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: _importBloc,
                        child: const ImportPage(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Get Started'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Privacy Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                      'Your data stays private. All analysis is done locally on your device.',
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

  Widget _buildChatList(BuildContext context, List<domain.ChatEntity> chats) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Chats (${chats.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: _importBloc,
                        child: const ImportPage(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Import New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatCard(context, chat);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatCard(BuildContext context, domain.ChatEntity chat) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final messageCount = chat.messages.length;
    final userCount = chat.users.length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.chat_bubble,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          chat.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('$messageCount messages • $userCount participants'),
            Text(
              'Imported: ${dateFormat.format(chat.importDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
              onTap: () async {
                await Future.delayed(const Duration(milliseconds: 100));
                await _deleteChat(context, chat.id);
              },
            ),
          ],
        ),
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
  }

  Future<void> _deleteChat(BuildContext context, String chatId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GetIt.instance.get<domain.ChatRepository>().deleteChat(chatId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat deleted successfully')),
          );
          setState(() {
            _refreshChats(); // Refresh the cached future
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting chat: $e')),
          );
        }
      }
    }
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final features = [
      {
        'icon': Icons.analytics,
        'title': 'Deep Analysis',
        'description': 'Comprehensive insights into your conversations',
      },
      {
        'icon': Icons.timeline,
        'title': 'Timeline View',
        'description': 'See how your relationships evolve over time',
      },
      {
        'icon': Icons.people,
        'title': 'User Insights',
        'description': 'Understand communication patterns and behaviors',
      },
      {
        'icon': Icons.file_download,
        'title': 'Export Reports',
        'description': 'Generate and share beautiful analysis reports',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                feature['icon'] as IconData,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                feature['title'] as String,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                feature['description'] as String,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}