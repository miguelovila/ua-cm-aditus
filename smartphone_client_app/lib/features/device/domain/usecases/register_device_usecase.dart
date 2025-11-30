import '../../../../core/security/crypto_service.dart';
import '../../data/repositories/device_repository.dart';

class RegisterDeviceUseCase {
  final DeviceRepository _repository;
  final CryptoService _cryptoService;

  RegisterDeviceUseCase(this._repository, {CryptoService? cryptoService})
    : _cryptoService = cryptoService ?? CryptoService();

  Future<int> call(String deviceName) async {
    // Generate keypair
    final keyData = await _cryptoService.generateKeyPair();
    final publicKey = keyData['publicKeyPEM'] as String;

    // Register device with public key
    return await _repository.registerDevice(
      deviceName: deviceName,
      publicKey: publicKey,
    );
  }
}
