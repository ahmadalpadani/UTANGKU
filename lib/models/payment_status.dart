enum PaymentStatus {
  lunas('LUNAS', 'Lunas', 'Pembayaran sudah selesai'),
  belumLunas('BELUM_LUNAS', 'Belum Lunas', 'Pembayaran belum dilakukan');

  final String value;
  final String label;
  final String description;

  const PaymentStatus(this.value, this.label, this.description);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.belumLunas,
    );
  }

  bool get isPaid => this == PaymentStatus.lunas;
  bool get isUnpaid => this == PaymentStatus.belumLunas;
}
