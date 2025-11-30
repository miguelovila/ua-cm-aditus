import 'dart:async';
import 'package:equatable/equatable.dart';

sealed class GroupEvent extends Equatable {
  const GroupEvent();

  @override
  List<Object?> get props => [];
}

class GroupLoadRequested extends GroupEvent {
  const GroupLoadRequested();
}

class GroupRefreshRequested extends GroupEvent {
  final Completer<void>? completer;

  const GroupRefreshRequested([this.completer]);

  @override
  List<Object?> get props => [completer];
}
