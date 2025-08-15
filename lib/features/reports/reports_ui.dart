import 'package:chatreport/features/reports/reports_models.dart' as models;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'reports_bloc.dart';

class ReportGenerationDialog extends StatelessWidget {
  const ReportGenerationDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state is models.ReportsSuccess) {
          Navigator.of(context).pop();
          _showReportGeneratedDialog(context, (state as models.ReportsSuccess).reportFile.path);
        } else if (state is ReportsError) {
          Navigator.of(context).pop();
          _showErrorDialog(context, state.message);
        }
      },
      child: AlertDialog(
        title: const Text('Generating Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<ReportsBloc, ReportsState>(
              builder: (context, state) {
                if (state is ReportsLoading) {
                  return const CircularProgressIndicator();
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 16),
            const Text('Please wait while we generate your analysis report...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showReportGeneratedDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Report Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your analysis report has been generated successfully!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis Report.pdf',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Ready to share',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Share.shareXFiles([XFile(filePath)]);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Failed to generate report:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red[800],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Could implement retry logic here
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class ReportOptionsDialog extends StatefulWidget {
  final Function(ReportOptions) onGenerate;

  const ReportOptionsDialog({
    Key? key,
    required this.onGenerate,
  }) : super(key: key);

  @override
  State<ReportOptionsDialog> createState() => _ReportOptionsDialogState();
}

class _ReportOptionsDialogState extends State<ReportOptionsDialog> {
  bool includeCharts = true;
  bool includeDetailedAnalysis = true;
  bool includeUserBreakdown = true;
  bool includeTimeAnalysis = true;
  bool includeContentAnalysis = true;
  bool includeInsights = false; // Advanced insights might be large
  models.ReportFormat selectedFormat = models.ReportFormat.pdf;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Options'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose what to include in your report:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Report Sections
            _buildCheckboxTile(
              'Charts and Visualizations',
              includeCharts,
              (value) => setState(() => includeCharts = value),
              'Include pie charts, bar charts, and activity graphs',
            ),
            _buildCheckboxTile(
              'Detailed Analysis',
              includeDetailedAnalysis,
              (value) => setState(() => includeDetailedAnalysis = value),
              'Complete analysis with statistics and metrics',
            ),
            _buildCheckboxTile(
              'User Breakdown',
              includeUserBreakdown,
              (value) => setState(() => includeUserBreakdown = value),
              'Individual user statistics and rankings',
            ),
            _buildCheckboxTile(
              'Time Analysis',
              includeTimeAnalysis,
              (value) => setState(() => includeTimeAnalysis = value),
              'Hourly, daily, and monthly activity patterns',
            ),
            _buildCheckboxTile(
              'Content Analysis',
              includeContentAnalysis,
              (value) => setState(() => includeContentAnalysis = value),
              'Word count, emojis, and shared content analysis',
            ),
            _buildCheckboxTile(
              'Advanced Insights',
              includeInsights,
              (value) => setState(() => includeInsights = value),
              'Relationship dynamics and behavioral patterns',
            ),
            
            const SizedBox(height: 20),
            
            // Format Selection
            Text(
              'Report Format:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: RadioListTile<models.ReportFormat>(
                    title: Text('PDF'),
                    subtitle: Text('Recommended'),
                    value: models.ReportFormat.pdf,
                    groupValue: selectedFormat,
                    onChanged: (value) => setState(() => selectedFormat = value!),
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<models.ReportFormat>(
                    title: Text('HTML'),
                    subtitle: Text('Web page'),
                    value: models.ReportFormat.html,
                    groupValue: selectedFormat,
                    onChanged: (value) => setState(() => selectedFormat = value!),
                    dense: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Estimated size info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estimated size: ${_calculateEstimatedSize()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _generateReport,
          child: const Text('Generate Report'),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    Function(bool) onChanged,
    String subtitle,
  ) {
    return CheckboxListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? false),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  String _calculateEstimatedSize() {
    int sizeKB = 50; // Base size
    
    if (includeCharts) sizeKB += 200;
    if (includeDetailedAnalysis) sizeKB += 100;
    if (includeUserBreakdown) sizeKB += 50;
    if (includeTimeAnalysis) sizeKB += 150;
    if (includeContentAnalysis) sizeKB += 100;
    if (includeInsights) sizeKB += 200;
    
    if (selectedFormat == models.ReportFormat.html) {
      sizeKB = (sizeKB * 0.7).round(); // HTML is typically smaller
    }
    
    if (sizeKB < 1024) {
      return '${sizeKB}KB';
    } else {
      return '${(sizeKB / 1024).toStringAsFixed(1)}MB';
    }
  }

  void _generateReport() {
    final options = ReportOptions(
      includeCharts: includeCharts,
      includeDetailedAnalysis: includeDetailedAnalysis,
      includeUserBreakdown: includeUserBreakdown,
      includeTimeAnalysis: includeTimeAnalysis,
      includeContentAnalysis: includeContentAnalysis,
      includeInsights: includeInsights,
      format: selectedFormat,
    );
    
    Navigator.of(context).pop();
    widget.onGenerate(options);
  }
}

// Report configuration classes
class ReportOptions {
  final bool includeCharts;
  final bool includeDetailedAnalysis;
  final bool includeUserBreakdown;
  final bool includeTimeAnalysis;
  final bool includeContentAnalysis;
  final bool includeInsights;
  final models.ReportFormat format;

  ReportOptions({
    required this.includeCharts,
    required this.includeDetailedAnalysis,
    required this.includeUserBreakdown,
    required this.includeTimeAnalysis,
    required this.includeContentAnalysis,
    required this.includeInsights,
    required this.format,
  });
}

/* Removed duplicate ReportFormat enum. Use models.ReportFormat instead. */