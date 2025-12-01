import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/core/api/auth_api_service.dart';
import 'package:smartphone_client_app/core/api/user_api_service.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import '../../data/models/user.dart';
import '../../data/models/login_response.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthApiService _authApiService;
  final UserApiService _userApiService;
  final SecureStorageService _storage = SecureStorageService();

  AuthBloc({
    AuthApiService? authApiService,
    UserApiService? userApiService,
  })  : _authApiService = authApiService ?? AuthApiService(),
        _userApiService = userApiService ?? UserApiService(),
        super(AuthInitial()) {
    on<AuthInitializeRequested>(_onAuthInitializeRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthForgotPinRequested>(_onAuthForgotPinRequested);
  }

  Future<void> _onAuthInitializeRequested(
    AuthInitializeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthInitializing());

    try {
      // Check if tokens exist
      final accessToken = await _storage.getAccessToken();
      final refreshToken = await _storage.getRefreshToken();

      if (accessToken == null || refreshToken == null) {
        emit(AuthUnauthenticated());
        return;
      }

      // Try to fetch current user data to verify token is valid
      try {
        final response = await _userApiService.getCurrentUser(
          accessToken: accessToken,
        );

        final user = User.fromJson(response['user'] ?? response);

        // Save user data to storage
        await _storage.saveUserData(user.toJson());

        emit(
          AuthSuccess(
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        );
      } catch (e) {
        // Token might be expired, try to refresh
        final errorMessage = e.toString();
        if (errorMessage.contains('401') || errorMessage.contains('Unauthorized')) {
          try {
            final refreshResponse = await _authApiService.refreshToken(
              refreshToken: refreshToken,
            );

            final newAccessToken = refreshResponse['access_token'] as String;
            await _storage.saveAccessToken(newAccessToken);

            // Try fetching user again with new token
            final response = await _userApiService.getCurrentUser(
              accessToken: newAccessToken,
            );

            final user = User.fromJson(response['user'] ?? response);

            // Save user data to storage
            await _storage.saveUserData(user.toJson());

            emit(
              AuthSuccess(
                user: user,
                accessToken: newAccessToken,
                refreshToken: refreshToken,
              ),
            );
          } catch (_) {
            // Refresh failed, clear tokens and show login
            await _storage.clearTokens();
            emit(AuthUnauthenticated());
          }
        } else {
          // Other API error, clear tokens
          await _storage.clearTokens();
          emit(AuthUnauthenticated());
        }
      }
    } catch (e) {
      // Any other error, clear tokens and show login
      await _storage.clearTokens();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final responseData = await _authApiService.login(
        email: event.email,
        password: event.password,
      );

      final loginResponse = LoginResponse.fromJson(responseData);

      // Save tokens and user data to secure storage
      await _storage.saveAccessToken(loginResponse.tokens.accessToken);
      await _storage.saveRefreshToken(loginResponse.tokens.refreshToken);
      await _storage.saveUserData(loginResponse.user.toJson());

      emit(
        AuthSuccess(
          user: loginResponse.user,
          accessToken: loginResponse.tokens.accessToken,
          refreshToken: loginResponse.tokens.refreshToken,
        ),
      );
    } catch (e) {
      emit(
        AuthFailure(message: e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Clear tokens and user data on logout, but keep PIN, device, and keys
    await _storage.clearTokens();
    await _storage.clearUserData();
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthForgotPinRequested(
    AuthForgotPinRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Clear PIN and tokens, but keep device ID and cryptographic keys
    await _storage.clearTokens();
    await _storage.clearPin();
    emit(AuthUnauthenticated());
  }
}
