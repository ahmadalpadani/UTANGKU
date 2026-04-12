import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utangku_app/models/debt_model.dart';
import 'package:utangku_app/models/payment_status.dart';
import 'package:utangku_app/providers/debt_provider.dart';
import 'package:utangku_app/screens/debt/add_debt_screen.dart';
import 'package:utangku_app/services/whatsapp_service.dart';
import 'package:utangku_app/utils/formatters.dart';
import 'package:utangku_app/utils/theme.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final WhatsAppService _whatsappService = WhatsAppService();
  String _filterStatus = 'SEMUA'; // SEMUA, BELUM_LUNAS, LUNAS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Utang'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'SEMUA',
                child: Text('Semua'),
              ),
              const PopupMenuItem(
                value: 'BELUM_LUNAS',
                child: Text('Belum Lunas'),
              ),
              const PopupMenuItem(
                value: 'LUNAS',
                child: Text('Lunas'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddDebtScreen(isUtang: true),
            ),
          );
        },
        backgroundColor: AppTheme.utangColor,
        child: const Icon(Icons.add),
      ),
      body: Consumer<DebtProvider>(
        builder: (context, provider, child) {
          final allDebts = provider.utangList;
          final filteredDebts = _filterDebts(allDebts);

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (filteredDebts.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              _buildFilterChips(context),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDebts.length,
                  itemBuilder: (context, index) {
                    return _buildDebtCard(context, filteredDebts[index], provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<DebtModel> _filterDebts(List<DebtModel> debts) {
    if (_filterStatus == 'SEMUA') return debts;
    return debts.where((debt) => debt.status.value == _filterStatus).toList();
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Semua', 'SEMUA'),
          const SizedBox(width: 8),
          _buildFilterChip('Belum Lunas', 'BELUM_LUNAS'),
          const SizedBox(width: 8),
          _buildFilterChip('Lunas', 'LUNAS'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppTheme.primaryOrange.withValues(alpha: 0.3),
      checkmarkColor: AppTheme.primaryOrange,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada utang',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambah utang',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, DebtModel debt, DebtProvider provider) {
    final isOverdue = debt.isOverdue;
    final isPaid = debt.status == PaymentStatus.lunas;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onLongPress: () => _showOptionsDialog(context, debt, provider),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.utangColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.arrow_downward,
                      color: AppTheme.utangColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (debt.category != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            debt.category!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(debt.status),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nominal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        debt.formattedAmount,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.utangColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (debt.dueDate != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Jatuh Tempo',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormatter.formatShortDate(debt.dueDate!),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isOverdue && !isPaid
                                    ? AppTheme.error
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
              if (isOverdue && !isPaid) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: AppTheme.error, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Sudah jatuh tempo!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!isPaid && debt.phoneNumber != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendWhatsAppReminder(debt),
                        icon: const Icon(Icons.chat),
                        label: const Text('Tagih'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.success,
                          side: const BorderSide(color: AppTheme.success),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _togglePaymentStatus(debt, provider),
                      icon: Icon(isPaid ? Icons.cancel : Icons.check_circle),
                      label: Text(isPaid ? 'Tandai Belum' : 'Tandai Lunas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isPaid ? AppTheme.utangColor : AppTheme.success,
                        side: BorderSide(
                          color: isPaid ? AppTheme.utangColor : AppTheme.success,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(PaymentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status == PaymentStatus.lunas ? AppTheme.success : AppTheme.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, DebtModel debt, DebtProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilihan Aksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Data'),
              onTap: () {
                Navigator.pop(context);
                _editDebt(debt);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.error),
              title: const Text('Hapus Data', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(debt, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editDebt(DebtModel debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDebtScreen(
          existingDebt: debt,
          isUtang: true,
        ),
      ),
    );
  }

  void _confirmDelete(DebtModel debt, DebtProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Apakah Anda yakin ingin menghapus data "${debt.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDebt(debt.id!).then((success) {
                Navigator.pop(context);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data berhasil dihapus'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _togglePaymentStatus(DebtModel debt, DebtProvider provider) {
    provider.togglePaymentStatus(debt.id!, debt.status).then((success) {
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              debt.status == PaymentStatus.belumLunas
                  ? 'Ditandai sebagai lunas!'
                  : 'Ditandai sebagai belum lunas!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    });
  }

  void _sendWhatsAppReminder(DebtModel debt) {
    try {
      _whatsappService.sendReminder(debt);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka WhatsApp: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
