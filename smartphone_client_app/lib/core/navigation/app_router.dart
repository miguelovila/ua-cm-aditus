import 'package:flutter/material.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import 'package:smartphone_client_app/features/auth/presentation/login_screen.dart';
import 'package:smartphone_client_app/features/auth/presentation/pin_setup_screen.dart';
import 'package:smartphone_client_app/features/auth/presentation/pin_verification_screen.dart';
import 'package:smartphone_client_app/features/device/presentation/device_registration_screen.dart';

class AppRouter {
  static final _storage = SecureStorageService();

  /// Determines the initial route based on authentication and onboarding state
  static Future<Widget> determineInitialRoute() async {
    // Check if user has valid authentication tokens
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();

    final hasValidTokens = accessToken != null && refreshToken != null;

    if (!hasValidTokens) {
      // No tokens = user needs to login
      return const LoginScreen();
    }

    // User has tokens, check onboarding status
    final pinHash = await _storage.getPinHash();
    final deviceId = await _storage.getDeviceId();

    if (pinHash == null) {
      // Has tokens but no PIN -> continue onboarding from PIN setup
      return const PinSetupScreen();
    }

    if (deviceId == null) {
      // Has tokens and PIN but no device -> continue from device registration
      return const DeviceRegistrationScreen();
    }

    // Fully onboarded user -> show PIN verification
    return const PinVerificationScreen();
  }

  /// Returns true if the user has completed the full onboarding process
  static Future<bool> hasCompletedOnboarding() async {
    return await _storage.hasCompletedOnboarding();
  }

  /// Returns true if the user has valid authentication tokens
  static Future<bool> hasValidTokens() async {
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Clears all authentication and onboarding data
  static Future<void> clearAuthData() async {
    await _storage.clearAll();
  }
}
