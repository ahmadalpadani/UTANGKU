enum DebtType {
  utang('UTANG', 'Utang', 'Hutang yang harus Anda bayar'),
  piutang('PIUTANG', 'Piutang', 'Uang yang ditagihkan kepada Anda');

  final String value;
  final String label;
  final String description;

  const DebtType(this.value, this.label, this.description);

  static DebtType fromString(String value) {
    return DebtType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DebtType.utang,
    );
  }
}
