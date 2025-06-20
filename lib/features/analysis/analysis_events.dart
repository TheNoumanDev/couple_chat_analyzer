import 'package:equatable/equatable.dart';

abstract class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzeChatEvent extends AnalysisEvent {
  final String chatId;

  const AnalyzeChatEvent(this.chatId);

  @override
  List<Object?> get props => [chatId];
}