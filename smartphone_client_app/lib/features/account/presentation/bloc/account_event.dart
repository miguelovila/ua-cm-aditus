import 'package:equatable/equatable.dart';

sealed class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class AccountInitializeRequested extends AccountEvent {
  const AccountInitializeRequested();
}

class AccountBiometricToggled extends AccountEvent {
  final bool enabled;

  const AccountBiometricToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class AccountLogoutRequested extends AccountEvent {
  const AccountLogoutRequested();
}
