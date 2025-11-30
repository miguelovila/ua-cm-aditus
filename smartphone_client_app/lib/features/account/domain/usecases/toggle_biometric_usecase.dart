import '../../data/repositories/account_repository.dart';

class ToggleBiometricUseCase {
  final AccountRepository _repository;

  ToggleBiometricUseCase(this._repository);

  Future<void> call(bool enable) async {
    if (enable) {
      // Authenticate before enabling
      final authenticated = await _repository.authenticateWithBiometrics(
        reason: 'Authenticate to enable biometric login',
      );

      if (!authenticated) {
        throw Exception('Biometric authentication failed');
      }
    }

    await _repository.setBiometricEnabled(enable);
  }
}
