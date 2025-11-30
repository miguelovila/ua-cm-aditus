import 'package:equatable/equatable.dart';

sealed class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {
  const AccountInitial();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountLoaded extends AccountState {
  final bool biometricsAvailable;
  final bool biometricEnabled;
  final String biometricTypeName;

  const AccountLoaded({
    required this.biometricsAvailable,
    required this.biometricEnabled,
    required this.biometricTypeName,
  });

  AccountLoaded copyWith({
    bool? biometricsAvailable,
    bool? biometricEnabled,
    String? biometricTypeName,
  }) {
    return AccountLoaded(
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricTypeName: biometricTypeName ?? this.biometricTypeName,
    );
  }

  @override
  List<Object?> get props => [
    biometricsAvailable,
    biometricEnabled,
    biometricTypeName,
  ];
}

class AccountBiometricToggling extends AccountState {
  const AccountBiometricToggling();
}

class AccountBiometricToggleError extends AccountState {
  final String message;

  const AccountBiometricToggleError(this.message);

  @override
  List<Object?> get props => [message];
}

class AccountLoggingOut extends AccountState {
  const AccountLoggingOut();
}

class AccountLoggedOut extends AccountState {
  const AccountLoggedOut();
}

class AccountError extends AccountState {
  final String message;

  const AccountError(this.message);

  @override
  List<Object?> get props => [message];
}
