// features/reports/reports_feature.dart
// Consolidated: report_bloc.dart + report_event.dart + report_state.dart + generate_report_usecase.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../shared/domain.dart';

// ============================================================================
// REPORT EVENTS
// ============================================================================
abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class GenerateReportEvent extends ReportEvent {
  final String chatId;
  final Map<String, dynamic> results;

  const GenerateReportEvent(this.chatId, this.results);

  @override
  List<Object?> get props => [chatId, results];
}

// ============================================================================
// REPORT STATES
// ============================================================================
abstract class ReportState extends Equatable {
  const ReportState();
  
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportGenerating extends ReportState {}

class ReportGenerated extends ReportState {
  final File reportFile;

  const ReportGenerated(this.reportFile);

  @override
  List<Object?> get props => [reportFile];
}

class ReportError extends ReportState {
  final String message;

  const ReportError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// GENERATE REPORT USE CASE
// ============================================================================
class GenerateReportUseCase {
  final AnalysisRepository repository;

  GenerateReportUseCase(this.repository);

  Future<File> call(String chatId, Map<String, dynamic> results) async {
    return await repository.generateReport(chatId, results);
  }
}

// ============================================================================
// REPORT BLOC
// ============================================================================
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final GenerateReportUseCase generateReportUseCase;

  ReportBloc({
    required this.generateReportUseCase,
  }) : super(ReportInitial()) {
    on<GenerateReportEvent>(_onGenerateReport);
  }

  Future<void> _onGenerateReport(GenerateReportEvent event, Emitter<ReportState> emit) async {
    emit(ReportGenerating());
    try {
      final file = await generateReportUseCase(event.chatId, event.results);
      emit(ReportGenerated(file));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }
}