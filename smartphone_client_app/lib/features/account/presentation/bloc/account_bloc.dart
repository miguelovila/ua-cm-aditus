import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/toggle_biometric_usecase.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _repository;
  final ToggleBiometricUseCase _toggleBiometricUseCase;
  final LogoutUseCase _logoutUseCase;

  AccountBloc({AccountRepository? repository})
    : _repository = repository ?? AccountRepositoryImpl(),
      _toggleBiometricUseCase = ToggleBiometricUseCase(
        repository ?? AccountRepositoryImpl(),
      ),
      _logoutUseCase = LogoutUseCase(repository ?? AccountRepositoryImpl()),
      super(const AccountInitial()) {
    on<AccountInitializeRequested>(_onInitializeRequested);
    on<AccountBiometricToggled>(_onBiometricToggled);
    on<AccountLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onInitializeRequested(
    AccountInitializeRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountLoading());
    try {
      final biometricsAvailable = await _repository.areBiometricsAvailable();
      final biometricTypeName = biometricsAvailable
          ? await _repository.getBiometricTypeName()
          : '';
      final biometricEnabled = biometricsAvailable
          ? await _repository.isBiometricEnabled()
          : false;

      emit(
        AccountLoaded(
          biometricsAvailable: biometricsAvailable,
          biometricEnabled: biometricEnabled,
          biometricTypeName: biometricTypeName,
        ),
      );
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onBiometricToggled(
    AccountBiometricToggled event,
    Emitter<AccountState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AccountLoaded) return;

    emit(const AccountBiometricToggling());
    try {
      await _toggleBiometricUseCase(event.enabled);

      emit(currentState.copyWith(biometricEnabled: event.enabled));
    } catch (e) {
      emit(AccountBiometricToggleError(e.toString()));
      // Restore previous state
      emit(currentState);
    }
  }

  Future<void> _onLogoutRequested(
    AccountLogoutRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountLoggingOut());
    try {
      await _logoutUseCase();
      emit(const AccountLoggedOut());
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }
}
