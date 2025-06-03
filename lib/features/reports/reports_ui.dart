// features/reports/reports_ui.dart
// Consolidated: report_page.dart + report widgets

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/common.dart';
import 'reports_feature.dart';

// ============================================================================
// REPORT PAGE
// ============================================================================
class ReportPage extends StatelessWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Report'),
      ),
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          if (state is ReportGenerating) {
            return const LoadingIndicator(
              message: 'Generating report...',
            );
          }
          
          if (state is ReportError) {
            return ErrorView(
              message: state.message,
              onRetry: () => Navigator.pop(context),
            );
          }
          
          if (state is ReportGenerated) {
            return _buildReportSuccess(context, state.reportFile);
          }
          
          return const LoadingIndicator(
            message: 'Preparing report...',
          );
        },
      ),
    );
  }

  Widget _buildReportSuccess(BuildContext context, File reportFile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Report Generated!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Your WhatsApp chat analysis report is ready. You can share it or save it for later.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Share.shareXFiles(
                  [XFile(reportFile.path)],
                  subject: 'WhatsApp Chat Analysis Report',
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Report'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Analysis'),
            ),
          ],
        ),
      ),
    );
  }
}