import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/pointycastle.dart';
import 'secure_storage_service.dart';

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _storage = SecureStorageService();
  static const int _keySize = 2048;
  static const int _publicExponent = 65537;

  Future<Map<String, dynamic>> generateKeyPair() async {
    _log('Starting RSA-$_keySize key pair generation...');

    try {
      final secureRandom = _getSecureRandom();
      final keyParams = RSAKeyGeneratorParameters(
        BigInt.from(_publicExponent),
        _keySize,
        64,
      );

      final keyGenerator = RSAKeyGenerator()
        ..init(ParametersWithRandom(keyParams, secureRandom));

      _log('Generating prime numbers and key pair...');
      final pair = keyGenerator.generateKeyPair();
      final privateKey = pair.privateKey as RSAPrivateKey;
      final publicKey = pair.publicKey as RSAPublicKey;

      final privateKeyPEM = _encodePrivateKeyToPEM(privateKey);
      final publicKeyPEM = _encodePublicKeyToPEM(publicKey);

      _log('Key pair generation completed successfully.');

      await saveKeyPair(privateKeyPEM, publicKeyPEM);
      return {
        'privateKeyPEM': privateKeyPEM,
        'publicKeyPEM': publicKeyPEM,
        'keyPair': pair,
      };
    } catch (e) {
      _log('Error during key pair generation: $e');
      rethrow;
    }
  }

  String _encodePublicKeyToPEM(RSAPublicKey publicKey) {
    // Create ASN.1 structure for the public key
    // ASN.1 (Abstract Syntax Notation One) is a standard for representing data
    final algorithmSeq = ASN1Sequence();

    // Algorithm identifier: RSA encryption
    final algorithmAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([
        0x6,
        0x9,
        0x2a,
        0x86,
        0x48,
        0x86,
        0xf7,
        0xd,
        0x1,
        0x1,
        0x1,
      ]),
    );

    final paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    // Public key structure: modulus (n) and exponent (e)
    final publicKeySeq = ASN1Sequence();
    publicKeySeq.add(ASN1Integer(publicKey.modulus!));
    publicKeySeq.add(ASN1Integer(publicKey.exponent!));

    final publicKeySeqBytes = publicKeySeq.encode();
    final publicKeySeqBitString = ASN1BitString(
      stringValues: publicKeySeqBytes,
    );

    // Top level sequence
    final topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqBitString);

    // Encode to bytes and then to base64
    final encodedBytes = topLevelSeq.encode();
    final dataBase64 = base64.encode(encodedBytes);

    // Format as PEM with line breaks every 64 characters
    return _formatPEM(dataBase64, 'PUBLIC KEY');
  }

  String _encodePrivateKeyToPEM(RSAPrivateKey privateKey) {
    final topLevelSeq = ASN1Sequence();

    // Version
    topLevelSeq.add(ASN1Integer(BigInt.from(0)));

    // All the private key components
    topLevelSeq.add(ASN1Integer(privateKey.modulus!));
    topLevelSeq.add(ASN1Integer(privateKey.exponent!));
    topLevelSeq.add(ASN1Integer(privateKey.privateExponent!));
    topLevelSeq.add(ASN1Integer(privateKey.p!));
    topLevelSeq.add(ASN1Integer(privateKey.q!));

    // These are computed for efficiency (Chinese Remainder Theorem)
    // exponent1 = d mod (p-1)
    // exponent2 = d mod (q-1)
    // coefficient = (inverse of q) mod p
    topLevelSeq.add(
      ASN1Integer(privateKey.privateExponent! % (privateKey.p! - BigInt.one)),
    );
    topLevelSeq.add(
      ASN1Integer(privateKey.privateExponent! % (privateKey.q! - BigInt.one)),
    );
    topLevelSeq.add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));

    final encodedBytes = topLevelSeq.encode();
    final dataBase64 = base64.encode(encodedBytes);

    return _formatPEM(dataBase64, 'RSA PRIVATE KEY');
  }

  String _formatPEM(String base64Data, String type) {
    final lines = <String>[];

    // Add header
    lines.add('-----BEGIN $type-----');

    // Split base64 data into 64-character lines (PEM standard)
    for (int i = 0; i < base64Data.length; i += 64) {
      final end = (i + 64 < base64Data.length) ? i + 64 : base64Data.length;
      lines.add(base64Data.substring(i, end));
    }

    // Add footer
    lines.add('-----END $type-----');

    return lines.join('\n');
  }

  SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();

    final random = Random.secure();
    final seeds = <int>[];

    // More seed data = better randomness
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(256));
    }

    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    return secureRandom;
  }

  Future<void> saveKeyPair(String privateKeyPEM, String publicKeyPEM) async {
    _log('Saving key pair to secure storage');
    await _storage.savePrivateKey(privateKeyPEM);
    await _storage.savePublicKey(publicKeyPEM);
    _log('Key pair saved successfully');
  }

  Future<String?> getPrivateKeyPEM() async {
    return await _storage.getPrivateKey();
  }

  Future<String?> getPublicKeyPEM() async {
    return await _storage.getPublicKey();
  }

  Future<bool> hasStoredKeys() async {
    final privateKey = await getPrivateKeyPEM();
    final publicKey = await getPublicKeyPEM();
    return privateKey != null && publicKey != null;
  }

  Future<void> deleteKeys() async {
    _log('Deleting stored keys');
    await _storage.clearAll();
    _log('Keys deleted successfully');
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[CryptoService] $message');
    }
  }
}
