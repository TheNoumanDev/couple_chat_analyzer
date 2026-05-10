// ============================================================================
// FILE: features/ai_insights/ui/widgets/api_key_setup_card.dart
// API Key setup widget for AI Insights
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/ai_insights_bloc.dart';
import '../../services/ai_insights_service.dart';

class ApiKeySetupCard extends StatefulWidget {
  const ApiKeySetupCard({super.key});

  @override
  State<ApiKeySetupCard> createState() => _ApiKeySetupCardState();
}

class _ApiKeySetupCardState extends State<ApiKeySetupCard> {
  final _apiKeyController = TextEditingController();
  bool _isObscured = true;
  bool _isValidating = false;
  LLMProviderType _selectedProvider = LLMProviderType.deepseek;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  String _getApiKeyHint() {
    switch (_selectedProvider) {
      case LLMProviderType.deepseek:
        return 'sk-xxxxxxxxxxxxxxxx';
      case LLMProviderType.openai:
        return 'sk-proj-xxxxxxxx';
    }
  }

  String _getPricingInfo() {
    switch (_selectedProvider) {
      case LLMProviderType.deepseek:
        return 'DeepSeek: ~\$0.0003 per analysis (very affordable)';
      case LLMProviderType.openai:
        return 'OpenAI: ~\$0.01 per analysis';
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key')),
      );
      return;
    }

    setState(() => _isValidating = true);

    context.read<AIInsightsBloc>().add(ConfigureAIEvent(
          apiKey: apiKey,
          providerType: _selectedProvider,
        ));

    // Wait a moment for the bloc to update
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Configure AI Provider',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Provider selection
            Text(
              'Provider',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<LLMProviderType>(
              segments: const [
                ButtonSegment(
                  value: LLMProviderType.deepseek,
                  label: Text('DeepSeek'),
                  icon: Icon(Icons.auto_awesome),
                ),
                ButtonSegment(
                  value: LLMProviderType.openai,
                  label: Text('OpenAI'),
                  icon: Icon(Icons.psychology),
                ),
              ],
              selected: {_selectedProvider},
              onSelectionChanged: (Set<LLMProviderType> selection) {
                setState(() {
                  _selectedProvider = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // API Key input
            Text(
              'API Key',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: _isObscured,
              decoration: InputDecoration(
                hintText: _getApiKeyHint(),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _isObscured = !_isObscured);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Pricing info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getPricingInfo(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValidating ? null : _saveApiKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save & Validate'),
              ),
            ),
            const SizedBox(height: 12),

            // Help text
            Center(
              child: TextButton(
                onPressed: () => _showGetApiKeyDialog(context),
                child: const Text('How to get an API key?'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGetApiKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Get API Key'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProviderInstructions(
                'DeepSeek (Recommended)',
                [
                  '1. Visit platform.deepseek.com',
                  '2. Create an account',
                  '3. Go to API Keys section',
                  '4. Create a new API key',
                  '5. Copy and paste it here',
                ],
                '\$0.14 per 1M input tokens',
              ),
              const SizedBox(height: 20),
              _buildProviderInstructions(
                'OpenAI',
                [
                  '1. Visit platform.openai.com',
                  '2. Sign in or create account',
                  '3. Go to API Keys section',
                  '4. Create a new secret key',
                  '5. Copy and paste it here',
                ],
                '\$2.50 per 1M input tokens',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderInstructions(
    String provider,
    List<String> steps,
    String pricing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(step, style: const TextStyle(fontSize: 13)),
            )),
        const SizedBox(height: 4),
        Text(
          'Pricing: $pricing',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
