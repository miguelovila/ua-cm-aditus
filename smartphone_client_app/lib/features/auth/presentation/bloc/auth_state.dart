part of 'auth_bloc.dart';

@immutable
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthInitializing extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  final String accessToken;
  final String refreshToken;

  const AuthSuccess({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object> get props => [user, accessToken, refreshToken];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object> get props => [message];
}
