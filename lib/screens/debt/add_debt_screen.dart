import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utangku_app/models/debt_model.dart';
import 'package:utangku_app/models/debt_type.dart';
import 'package:utangku_app/models/payment_status.dart';
import 'package:utangku_app/providers/debt_provider.dart';
import 'package:utangku_app/utils/formatters.dart';
import 'package:utangku_app/utils/theme.dart';

class AddDebtScreen extends StatefulWidget {
  final DebtModel? existingDebt;
  final bool isUtang;

  const AddDebtScreen({
    super.key,
    this.existingDebt,
    required this.isUtang,
  });

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _dueDate;
  String _selectedCategory = 'Lainnya';

  final List<String> _categories = [
    'Pinjaman',
    'Belanja',
    'Tagihan',
    'Usaha',
    'Pribadi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingDebt != null) {
      _initializeFromExistingDebt();
    } else {
      _selectedCategory = _categories.first;
    }
  }

  void _initializeFromExistingDebt() {
    final debt = widget.existingDebt!;
    _nameController.text = debt.name;
    _amountController.text = debt.amount.toString();
    _categoryController.text = debt.category ?? '';
    _descriptionController.text = debt.description ?? '';
    _phoneController.text = debt.phoneNumber ?? '';
    _dueDate = debt.dueDate;
    _selectedCategory = debt.category ?? _categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('id', 'ID'),
      helpText: 'Pilih Tanggal Jatuh Tempo',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _saveDebt() {
    if (_formKey.currentState!.validate()) {
      try {
        // Clean the amount input
        final amountText = _amountController.text.trim().replaceAll('.', '');
        final amount = double.parse(amountText);

        final debt = DebtModel(
          id: widget.existingDebt?.id,
          name: _nameController.text.trim(),
          amount: amount,
          type: widget.isUtang ? DebtType.utang : DebtType.piutang,
          category: _selectedCategory,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          dueDate: _dueDate,
          status: widget.existingDebt?.status ?? PaymentStatus.belumLunas,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );

        final provider = Provider.of<DebtProvider>(context, listen: false);

        if (widget.existingDebt != null) {
          provider.updateDebt(debt).then((success) {
            if (success && mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data berhasil diperbarui!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            } else if (mounted && provider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage!),
                  backgroundColor: AppTheme.error,
                ),
              );
              provider.clearError();
            }
          });
        } else {
          provider.addDebt(debt).then((success) {
            if (success && mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${widget.isUtang ? "Utang" : "Piutang"} berhasil ditambahkan!',
                  ),
                  backgroundColor: AppTheme.success,
                ),
              );
            } else if (mounted && provider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage!),
                  backgroundColor: AppTheme.error,
                ),
              );
              provider.clearError();
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingDebt != null;
    final appBarColor = widget.isUtang ? AppTheme.utangColor : AppTheme.piutangColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Data' : 'Tambah ${widget.isUtang ? "Utang" : "Piutang"}'),
        backgroundColor: appBarColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              _buildSectionTitle('Nama Pihak Terkait'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Budi, Toko ABC, dll',
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Amount
              _buildSectionTitle('Nominal (Rp)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Contoh: 1000000 atau 1.000.000',
                  prefixIcon: const Icon(Icons.money),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nominal tidak boleh kosong';
                  }
                  // Remove dots (Indonesian thousand separator)
                  final cleanValue = value.trim().replaceAll('.', '');
                  final amount = double.tryParse(cleanValue);
                  if (amount == null || amount <= 0) {
                    return 'Masukkan nominal yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category
              _buildSectionTitle('Kategori'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Due Date
              _buildSectionTitle('Tanggal Jatuh Tempo'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today),
                    hintText: 'Pilih tanggal jatuh tempo',
                  ),
                  child: Text(
                    _dueDate != null
                        ? DateFormatter.formatDate(_dueDate!)
                        : 'Belum dipilih',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phone Number
              _buildSectionTitle('Nomor Telepon (WhatsApp)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Contoh: 08123456789',
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
                    if (cleaned.length < 10) {
                      return 'Nomor telepon tidak valid';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Digunakan untuk fitur tagih via WhatsApp',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 20),

              // Description
              _buildSectionTitle('Keterangan (Opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tambahkan catatan...',
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 32),

              // Preview Card
              if (_nameController.text.isNotEmpty ||
                  _amountController.text.isNotEmpty)
                _buildPreviewCard(context, appBarColor),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveDebt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appBarColor,
                  ),
                  child: Text(
                    isEditing ? 'Simpan Perubahan' : 'Simpan Data',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryOrange,
          ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, Color color) {
    final amount = _amountController.text.trim();
    final displayAmount = amount.isEmpty
        ? 'Rp 0'
        : CurrencyFormatter.format(double.tryParse(amount) ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Divider(),
          if (_nameController.text.isNotEmpty)
            Text(
              _nameController.text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          if (_nameController.text.isNotEmpty) const SizedBox(height: 4),
          Text(
            displayAmount,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (_selectedCategory.isNotEmpty) ...[
            const SizedBox(height: 4),
            Chip(
              label: Text(_selectedCategory),
              backgroundColor: color.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (_dueDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Jatuh tempo: ${DateFormatter.formatDate(_dueDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
