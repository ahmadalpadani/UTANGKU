class AppConstants {
  // App Info
  static const String appName = 'UtangKU';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'utangku.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String tableDebts = 'debts';

  // Debt Types
  static const String debtTypeUtang = 'UTANG';
  static const String debtTypePiutang = 'PIUTANG';

  // Payment Status
  static const String statusLunas = 'LUNAS';
  static const String statusBelumLunas = 'BELUM_LUNAS';

  // WhatsApp Message Template
  static const String defaultReminderMessage =
      'Halo {name}, ini adalah pengingat pembayaran utang sebesar Rp {amount} yang jatuh tempo pada {due_date}. Mohon segera diproses ya. Terima kasih! 🙏\n\n_Dikirim melalui aplikasi UtangKU_';

  // Storage Keys
  static const String keyHasPin = 'has_pin';
  static const String keyPinCode = 'pin_code';
  static const String keyUseBiometric = 'use_biometric';
  static const String keyAutoLockTimeout = 'auto_lock_timeout';
}
