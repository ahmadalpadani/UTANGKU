import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utangku_app/providers/debt_provider.dart';
import 'package:utangku_app/screens/debt/add_debt_screen.dart';
import 'package:utangku_app/screens/debt/debt_list_screen.dart';
import 'package:utangku_app/screens/piutang/piutang_list_screen.dart';
import 'package:utangku_app/screens/settings/settings_screen.dart';
import 'package:utangku_app/utils/formatters.dart';
import 'package:utangku_app/utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DebtListScreen(),
    const PiutangListScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryOrange,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_circle_down),
            label: 'Utang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_circle_up),
            label: 'Piutang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UtangKU'),
        elevation: 0,
      ),
      body: Consumer<DebtProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    'Ringkasan Keuangan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Total Utang',
                          provider.totalUnpaidUtang,
                          AppTheme.utangColor,
                          Icons.arrow_downward,
                          false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Total Piutang',
                          provider.totalUnpaidPiutang,
                          AppTheme.piutangColor,
                          Icons.arrow_upward,
                          true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Balance Card
                  _buildBalanceCard(context, provider),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Aksi Cepat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          'Tambah Utang',
                          Icons.add_circle_outline,
                          AppTheme.utangColor,
                          () => _showAddDebtDialog(context, true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          context,
                          'Tambah Piutang',
                          Icons.add_circle_outline,
                          AppTheme.piutangColor,
                          () => _showAddDebtDialog(context, false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Transactions
                  Text(
                    'Transaksi Terbaru',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  if (provider.allDebts.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildRecentList(context, provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon,
    bool isPositive,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyFormatter.format(amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, DebtProvider provider) {
    final balance = provider.totalUnpaidPiutang - provider.totalUnpaidUtang;
    final isPositive = balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [AppTheme.piutangColor, AppTheme.piutangColor.withValues(alpha: 0.8)]
              : [AppTheme.utangColor, AppTheme.utangColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Bersih',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance.abs()),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? 'Anda di posisi surplus' : 'Anda di posisi defisit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol tambah untuk memulai',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList(BuildContext context, DebtProvider provider) {
    final recentDebts = provider.allDebts.take(5).toList();

    return Card(
      child: Column(
        children: recentDebts.map((debt) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: debt.type.value == 'UTANG'
                  ? AppTheme.utangColor.withValues(alpha: 0.1)
                  : AppTheme.piutangColor.withValues(alpha: 0.1),
              child: Icon(
                debt.type.value == 'UTANG' ? Icons.arrow_downward : Icons.arrow_upward,
                color: debt.type.value == 'UTANG'
                    ? AppTheme.utangColor
                    : AppTheme.piutangColor,
                size: 20,
              ),
            ),
            title: Text(debt.name),
            subtitle: Text(CurrencyFormatter.format(debt.amount)),
            trailing: _buildStatusChip(debt.status.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status == 'LUNAS' ? AppTheme.success : AppTheme.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == 'LUNAS' ? 'Lunas' : 'Belum',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context, bool isUtang) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDebtScreen(isUtang: isUtang),
      ),
    );
  }
}
