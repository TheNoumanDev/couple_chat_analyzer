// lib/features/import/import_models.dart
// Consolidated: import_events.dart + import_states.dart

import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../shared/domain.dart';

// ============================================================================
// IMPORT EVENTS
// ============================================================================
abstract class ImportEvent extends Equatable {
  const ImportEvent();

  @override
  List<Object?> get props => [];
}

class PickFileEvent extends ImportEvent {}

class ImportFileEvent extends ImportEvent {
  final File file;

  const ImportFileEvent(this.file);

  @override
  List<Object?> get props => [file];
}

class FileSharedEvent extends ImportEvent {
  final File file;

  const FileSharedEvent(this.file);

  @override
  List<Object?> get props => [file];
}

class RetryImportEvent extends ImportEvent {
  final File file;

  const RetryImportEvent(this.file);

  @override
  List<Object?> get props => [file];
}

class ClearErrorEvent extends ImportEvent {}

// ============================================================================
// IMPORT STATES
// ============================================================================
abstract class ImportState extends Equatable {
  const ImportState();

  @override
  List<Object?> get props => [];
}

class ImportInitial extends ImportState {}

class ImportLoading extends ImportState {
  final String message;
  final double? progress;

  const ImportLoading({
    this.message = 'Processing...',
    this.progress,
  });

  @override
  List<Object?> get props => [message, progress];
}

class FileSelected extends ImportState {
  final File file;

  const FileSelected(this.file);

  @override
  List<Object?> get props => [file];
}

class ImportSuccess extends ImportState {
  final ChatEntity chat;

  const ImportSuccess(this.chat);

  @override
  List<Object?> get props => [chat];
}

class ImportError extends ImportState {
  final String message;
  final String? technicalDetails;
  final File? failedFile;

  const ImportError(
    this.message, {
    this.technicalDetails,
    this.failedFile,
  });

  @override
  List<Object?> get props => [message, technicalDetails, failedFile];
}