import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utangku_app/providers/debt_provider.dart';
import 'package:utangku_app/screens/lock/lock_screen.dart';
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
  bool _biometricAvailable = false;
  String _biometricLabel = 'Biometric';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _permissionGranted = await NotificationService().isEnabled();
    _biometricAvailable = await _authService.isBiometricAvailable();
    if (_biometricAvailable) {
      _biometricLabel = await _authService.getBiometricLabel();
    }
    if (mounted) setState(() {});
  }

  Future<void> _setupPin() async {
    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (ctx) => LockScreen(
          mode: LockScreenMode.setup,
          onPinEntered: (enteredPin) {
            Navigator.pop(ctx, enteredPin);
          },
        ),
      ),
    );

    if (pin == null) return;

    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => LockScreen(
          mode: LockScreenMode.confirm,
          initialPin: pin,
          onSuccess: () => Navigator.pop(ctx, true),
        ),
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN berhasil disimpan!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
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

    if (confirm == true) {
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
                  subtitle: 'Aktif — ${_authService.hasPin ? "Ya" : "Tidak"}',
                  icon: Icons.lock_outline,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_biometricAvailable)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Switch(
                            value: _authService.useBiometric,
                            activeTrackColor: AppTheme.primaryOrange,
                            onChanged: (value) async {
                              await _authService.setBiometric(value);
                              setState(() {});
                            },
                          ),
                        ),
                      TextButton(
                        onPressed: _removePin,
                        child: const Text(
                          'Hapus',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_biometricAvailable && _authService.useBiometric)
                  _buildListTile(
                    title: _biometricLabel,
                    subtitle: 'Gunakan $_biometricLabel untuk buka aplikasi',
                    icon: Icons.fingerprint,
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
                _buildListTile(
                  title: _biometricLabel,
                  subtitle: _biometricAvailable
                      ? 'Aktifkan PIN terlebih dahulu'
                      : 'Tidak tersedia di perangkat ini',
                  icon: Icons.fingerprint,
                  enabled: false,
                ),
              ],

              const Divider(height: 32),

              // Data Section
              _buildSectionHeader('Data'),
              _buildInfoTile(
                title: 'Export Data (CSV/PDF)',
                subtitle: 'Belum tersedia',
                icon: Icons.download_outlined,
                trailing: const _ComingSoonChip(),
              ),
              _buildInfoTile(
                title: 'Import Data',
                subtitle: 'Belum tersedia',
                icon: Icons.upload_outlined,
                trailing: const _ComingSoonChip(),
              ),

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

class _ComingSoonChip extends StatelessWidget {
  const _ComingSoonChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Segera',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
