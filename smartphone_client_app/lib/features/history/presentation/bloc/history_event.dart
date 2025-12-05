import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistoryRequested extends HistoryEvent {
  const LoadHistoryRequested();
}

class RefreshHistoryRequested extends HistoryEvent {
  const RefreshHistoryRequested();
}

class LoadMoreHistoryRequested extends HistoryEvent {
  const LoadMoreHistoryRequested();
}
