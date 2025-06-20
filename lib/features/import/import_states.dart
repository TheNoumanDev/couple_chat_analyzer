import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../shared/domain.dart';

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