import 'dart:io';
import 'package:equatable/equatable.dart';

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