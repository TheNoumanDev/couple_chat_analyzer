import 'package:equatable/equatable.dart';

abstract class AnalysisState extends Equatable {
  const AnalysisState();

  @override
  List<Object?> get props => [];
}

class AnalysisInitial extends AnalysisState {}

class AnalysisLoading extends AnalysisState {}

class AnalysisSuccess extends AnalysisState {
  final String chatId;
  final Map<String, dynamic> results;

  const AnalysisSuccess(this.chatId, this.results);

  @override
  List<Object?> get props => [chatId, results];
}

class AnalysisError extends AnalysisState {
  final String message;

  const AnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}
