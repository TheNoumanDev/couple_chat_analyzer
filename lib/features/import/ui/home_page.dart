import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../widgets/common.dart';
import '../../analysis/ui/analysis_page.dart';
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
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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