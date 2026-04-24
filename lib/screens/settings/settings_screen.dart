import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utangku_app/providers/debt_provider.dart';
import 'package:utangku_app/services/auth_service.dart';
import 'package:utangku_app/services/notification_service.dart';
import 'package:utangku_app/utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _permissionGranted = await NotificationService().isEnabled();
    if (mounted) setState(() {});
  }

  Future<void> _setupPin() async {
    // Step 1: Get first PIN
    final firstPin = await _showPinDialog(
      title: 'Buat PIN Baru',
      subtitle: 'Masukkan PIN 6 digit untuk mengamankan aplikasi',
      isConfirm: false,
    );

    if (firstPin == null || !mounted) return;

    // Step 2: Confirm PIN
    final confirmPin = await _showPinDialog(
      title: 'Konfirmasi PIN',
      subtitle: 'Masukkan PIN yang sama untuk konfirmasi',
      isConfirm: true,
      initialPin: firstPin,
    );

    if (confirmPin == null || !mounted) return;

    // Step 3: Save PIN
    final saved = await _authService.setPin(confirmPin);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? 'PIN berhasil disimpan!' : 'Gagal menyimpan PIN'),
          backgroundColor: saved ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }

  Future<String?> _showPinDialog({
    required String title,
    required String subtitle,
    required bool isConfirm,
    String? initialPin,
  }) async {
    String enteredPin = '';
    String errorMessage = '';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.primaryOrange,
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 24),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: isFilled ? 16 : 14,
                    height: isFilled ? 16 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? Colors.white : Colors.white.withValues(alpha: 0.3),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  );
                }),
              ),
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              // Keypad
              _buildDialogKeypad(ctx, (key) {
                if (enteredPin.length < 6) {
                  setDialogState(() {
                    enteredPin += key;
                    errorMessage = '';
                  });
                  if (enteredPin.length == 6) {
                    _handlePinEntry(ctx, enteredPin, isConfirm, initialPin);
                  }
                }
              }, () {
                if (enteredPin.isNotEmpty) {
                  setDialogState(() {
                    enteredPin = enteredPin.substring(0, enteredPin.length - 1);
                    errorMessage = '';
                  });
                }
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePinEntry(BuildContext ctx, String pin, bool isConfirm, String? initialPin) {
    if (isConfirm) {
      if (pin == initialPin) {
        Navigator.pop(ctx, pin);
      } else {
        setState(() {});
        Navigator.pop(ctx, null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN tidak cocok. Silakan ulangi.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } else {
      Navigator.pop(ctx, pin);
    }
  }

  Widget _buildDialogKeypad(BuildContext ctx, Function(String) onKeyTap, VoidCallback onBackspace) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 56, height: 48);
            }
            return InkWell(
              onTap: () => key == '⌫' ? onBackspace() : onKeyTap(key),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 56,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: key == '⌫'
                    ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 20)
                    : Text(
                        key,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
                      ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Future<void> _removePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus PIN?'),
        content: const Text(
          'Keamanan aplikasi akan berkurang. Anda yakin ingin menghapus PIN?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.removePin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN berhasil dihapus'),
            backgroundColor: AppTheme.warning,
          ),
        );
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Consumer<DebtProvider>(
        builder: (context, provider, child) {
          return ListView(
            children: [
              const SizedBox(height: 8),

              // Notification Section
              _buildSectionHeader('Notifikasi'),
              _buildListTile(
                title: 'Test Notifikasi',
                subtitle: 'Kirim notifikasi percobaan',
                icon: Icons.notifications_active_outlined,
                trailing: OutlinedButton(
                  onPressed: () async {
                    await NotificationService().showTestNotification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifikasi test dikirim!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryOrange,
                    side: const BorderSide(color: AppTheme.primaryOrange),
                  ),
                  child: const Text('Kirim'),
                ),
              ),
              _buildSwitchTile(
                title: 'Aktifkan Notifikasi',
                subtitle: 'Terima pengingat jatuh tempo',
                icon: Icons.notifications_outlined,
                value: provider.notificationsEnabled,
                onChanged: (value) async {
                  if (value && !_permissionGranted) {
                    final granted = await NotificationService().requestPermission();
                    if (!granted) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Izin notifikasi ditolak. Aktifkan di Pengaturan HP.'),
                        ),
                      );
                      return;
                    }
                    if (mounted) setState(() => _permissionGranted = true);
                  }
                  if (!value) {
                    await NotificationService().cancelAllNotifications();
                  }
                  await provider.setNotificationsEnabled(value);
                },
              ),
              if (provider.notificationsEnabled) ...[
                _buildSwitchTile(
                  title: 'Pengingat Jatuh Tempo',
                  subtitle: 'Notifikasi 1 hari sebelum jatuh tempo',
                  icon: Icons.schedule_outlined,
                  value: provider.dueDateReminders,
                  onChanged: (value) => provider.setDueDateReminders(value),
                ),
                _buildSwitchTile(
                  title: 'Peringatan Terlambat',
                  subtitle: 'Notifikasi saat jatuh tempo terlewat',
                  icon: Icons.warning_amber_outlined,
                  value: provider.overdueAlerts,
                  onChanged: (value) => provider.setOverdueAlerts(value),
                ),
              ],

              const Divider(height: 32),

              // Security Section
              _buildSectionHeader('Keamanan'),
              if (_authService.hasPin) ...[
                _buildListTile(
                  title: 'Kunci Aplikasi (PIN)',
                  subtitle: 'Aktif — Ya',
                  icon: Icons.lock_outline,
                  trailing: TextButton(
                    onPressed: _removePin,
                    child: const Text(
                      'Hapus',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                ),
              ] else ...[
                _buildListTile(
                  title: 'Kunci Aplikasi (PIN)',
                  subtitle: 'Amankan aplikasi dengan PIN 6 digit',
                  icon: Icons.lock_outline,
                  trailing: OutlinedButton(
                    onPressed: _setupPin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryOrange,
                      side: const BorderSide(color: AppTheme.primaryOrange),
                    ),
                    child: const Text('Aktifkan'),
                  ),
                ),
              ],

              const Divider(height: 32),

              // App Info Section
              _buildSectionHeader('Tentang Aplikasi'),
              _buildInfoTile(
                title: 'UtangKU',
                subtitle: 'Versi 1.0.0',
                icon: Icons.info_outline,
              ),
              _buildInfoTile(
                title: 'Total Transaksi',
                subtitle: '${provider.totalCount} transaksi',
                icon: Icons.receipt_long_outlined,
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryOrange,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryOrange),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        activeTrackColor: AppTheme.primaryOrange,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? Colors.grey[600] : Colors.grey[400],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? null : Colors.grey[400],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? null : Colors.grey[400],
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing,
    );
  }
}
