import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utangku_app/utils/constants.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  SharedPreferences? _prefs;

  bool _isInitialized = false;
  bool _hasPin = false;
  bool _useBiometric = false;
  bool _isLocked = true;
  bool _hasUnlockedOnce = false; // true once user has entered correct PIN in this session

  // Getters
  bool get hasPin => _hasPin;
  bool get useBiometric => _useBiometric;
  bool get isLocked => _isLocked;
  bool get hasUnlockedOnce => _hasUnlockedOnce;

  /// Simple hash for web storage (not cryptographically secure — for demo only)
  String _hashPin(String pin) {
    // Base64 encode to avoid plain-text storage
    return base64Encode(utf8.encode(pin));
  }

  /// Initialize auth state from storage
  Future<void> init() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      _hasPin = _prefs!.getBool(AppConstants.keyHasPin) ?? false;
      _useBiometric = false; // Biometric not available on web
      _hasUnlockedOnce = _hasPin; // Existing PIN requires verification on restart
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      _hasPin = _prefs!.getBool(AppConstants.keyHasPin) ?? false;
      _useBiometric = _prefs!.getBool(AppConstants.keyUseBiometric) ?? false;
      _hasUnlockedOnce = _hasPin; // Existing PIN requires verification on restart
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Check if biometric is available on device
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Set up PIN (works on both web and native)
  Future<bool> setPin(String pin) async {
    try {
      if (kIsWeb) {
        // Web: store hashed PIN in shared_preferences (localStorage)
        final hashedPin = _hashPin(pin);
        await _prefs!.setString(AppConstants.keyPinCode, hashedPin);
        await _prefs!.setBool(AppConstants.keyHasPin, true);
      } else {
        // Native: store PIN securely in keychain
        await _secureStorage.write(key: AppConstants.keyPinCode, value: pin);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.keyHasPin, true);
      }
      _hasPin = true;
      _hasUnlockedOnce = false; // Don't lock user immediately after they just set PIN
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('setPin error: $e');
      return false;
    }
  }

  /// Verify PIN (works on both web and native)
  Future<bool> verifyPin(String pin) async {
    try {
      String? stored;
      if (kIsWeb) {
        stored = _prefs!.getString(AppConstants.keyPinCode);
        if (stored == _hashPin(pin)) {
          _unlock();
          notifyListeners();
          return true;
        }
      } else {
        stored = await _secureStorage.read(key: AppConstants.keyPinCode);
        if (stored == pin) {
          _unlock();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('verifyPin error: $e');
      return false;
    }
  }

  /// Remove PIN (works on both web and native)
  Future<void> removePin() async {
    try {
      if (kIsWeb) {
        await _prefs!.remove(AppConstants.keyPinCode);
        await _prefs!.setBool(AppConstants.keyHasPin, false);
      } else {
        await _secureStorage.delete(key: AppConstants.keyPinCode);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.keyHasPin, false);
        await prefs.setBool(AppConstants.keyUseBiometric, false);
      }
      _hasPin = false;
      _useBiometric = false;
      notifyListeners();
    } catch (e) {
      debugPrint('removePin error: $e');
    }
  }

  /// Enable/disable biometric (native only)
  Future<void> setBiometric(bool value) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyUseBiometric, value);
      _useBiometric = value;
      notifyListeners();
    } catch (e) {
      debugPrint('setBiometric error: $e');
    }
  }

  /// Authenticate with biometric (native only)
  Future<bool> authenticateWithBiometric() async {
    if (kIsWeb) return false;
    if (!_useBiometric || !_hasPin) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas Anda untuk membuka UtangKU',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _unlock();
        notifyListeners();
      }
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('biometric auth error: $e');
      return false;
    }
  }

  /// Lock the app
  void lock() {
    if (_hasPin) {
      _isLocked = true;
    }
  }

  /// Unlock the app
  void _unlock() {
    _isLocked = false;
    _hasUnlockedOnce = true;
    notifyListeners();
  }

  /// Get biometric label (Face ID / Fingerprint)
  Future<String> getBiometricLabel() async {
    if (kIsWeb) return 'Biometric';
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }
}
