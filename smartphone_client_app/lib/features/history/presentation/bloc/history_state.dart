import 'package:equatable/equatable.dart';
import '../../data/models/access_log.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<AccessLog> logs;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;

  const HistoryLoaded({
    required this.logs,
    required this.total,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [logs, total, hasMore, isLoadingMore];

  HistoryLoaded copyWith({
    List<AccessLog>? logs,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return HistoryLoaded(
      logs: logs ?? this.logs,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
}
