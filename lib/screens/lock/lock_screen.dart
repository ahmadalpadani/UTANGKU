import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utangku_app/services/auth_service.dart';
import 'package:utangku_app/utils/theme.dart';

enum LockScreenMode { verify, setup, confirm }

class LockScreen extends StatefulWidget {
  final LockScreenMode mode;
  final String? initialPin;
  final VoidCallback? onSuccess;
  final void Function(String pin)? onPinEntered; // used by setup mode to pass PIN to parent

  const LockScreen({
    super.key,
    required this.mode,
    this.initialPin,
    this.onSuccess,
    this.onPinEntered,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AuthService _authService = AuthService();
  String _enteredPin = '';
  bool _isLoading = false;
  String _errorMessage = '';
  String _biometricLabel = 'Biometric';
  bool _biometricAvailable = false;

  String get _title {
    switch (widget.mode) {
      case LockScreenMode.verify:
        return 'Masukkan PIN';
      case LockScreenMode.setup:
        return 'Buat PIN Baru';
      case LockScreenMode.confirm:
        return 'Konfirmasi PIN';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case LockScreenMode.verify:
        return 'Masukkan PIN untuk membuka aplikasi';
      case LockScreenMode.setup:
        return 'Buat PIN 6 digit untuk mengamankan aplikasi';
      case LockScreenMode.confirm:
        return 'Masukkan PIN yang sama untuk konfirmasi';
    }
  }

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    _biometricAvailable = await _authService.isBiometricAvailable();
    if (_biometricAvailable) {
      _biometricLabel = await _authService.getBiometricLabel();
    }
    if (mounted && _biometricAvailable && widget.mode == LockScreenMode.verify) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_authService.useBiometric) {
      setState(() => _isLoading = true);
      final success = await _authService.authenticateWithBiometric();
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          widget.onSuccess?.call();
        }
      }
    }
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    if (_enteredPin.length >= 6) return;

    setState(() {
      _enteredPin += key;
      _errorMessage = '';
    });

    if (_enteredPin.length == 6) {
      _handlePinComplete();
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = '';
    });
  }

  Future<void> _handlePinComplete() async {
    setState(() => _isLoading = true);

    switch (widget.mode) {
      case LockScreenMode.verify:
        final success = await _authService.verifyPin(_enteredPin);
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (success) {
          widget.onSuccess?.call();
        } else {
          setState(() {
            _enteredPin = '';
            _errorMessage = 'PIN salah. Coba lagi.';
          });
        }
        break;

      case LockScreenMode.setup:
        widget.onPinEntered?.call(_enteredPin);
        // Close setup screen after passing PIN to confirm screen
        Navigator.pop(context);
        break;

      case LockScreenMode.confirm:
        if (_enteredPin == widget.initialPin) {
          final saved = await _authService.setPin(_enteredPin);
          if (!mounted) return;
          setState(() => _isLoading = false);
          if (saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN berhasil disimpan!'),
                backgroundColor: AppTheme.success,
              ),
            );
            widget.onSuccess?.call();
          } else {
            setState(() {
              _enteredPin = '';
              _errorMessage = 'Gagal menyimpan PIN. Coba lagi.';
            });
          }
        } else {
          if (!mounted) return;
          setState(() {
            _enteredPin = '';
            _errorMessage = 'PIN tidak cocok. Ulangi dari awal.';
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryOrange,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Logo / Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // PIN dots
            _buildPinDots(),

            // Error message
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const Spacer(flex: 2),

            // Keypad
            _buildKeypad(),

            const SizedBox(height: 32),

            // Biometric button
            if (_biometricAvailable &&
                widget.mode == LockScreenMode.verify &&
                _authService.useBiometric)
              TextButton.icon(
                onPressed: _tryBiometric,
                icon: const Icon(Icons.fingerprint, color: Colors.white),
                label: Text(
                  'Gunakan $_biometricLabel',
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isFilled ? 16 : 14,
          height: isFilled ? 16 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 72, height: 72);
              }
              if (key == 'back') {
                return _buildKey(
                  child: const Icon(Icons.backspace_outlined, color: Colors.white),
                  onTap: _onBackspace,
                );
              }
              return _buildKey(
                child: Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => _onKeyTap(key),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : child,
      ),
    );
  }
}
