abstract class AccountRepository {
  Future<bool> areBiometricsAvailable();
  Future<String> getBiometricTypeName();
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> authenticateWithBiometrics({required String reason});
  Future<void> logout();
}
