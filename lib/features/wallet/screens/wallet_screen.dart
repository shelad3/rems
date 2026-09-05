import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/models/wallet_transaction_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/push_service.dart';
import '../../../data/repositories/audit_log_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider).value?.uid ?? '';
    final walletAsync = ref.watch(currentWalletProvider);
    final txnsAsync = ref.watch(walletTransactionsProvider);
    final isAdmin =
        ref.watch(authProvider).user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentWalletProvider);
          ref.invalidate(walletTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            walletAsync.when(
              data: (wallet) => _BalanceCard(wallet: wallet, isAdmin: isAdmin),
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 8),
                child: ShimmerLoading(),
              ),
              error: (e, _) => _BalanceCard(wallet: null, isAdmin: isAdmin),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              _PendingWithdrawalsSection(uid: uid),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDepositDialog(context, ref, uid),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Deposit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showWithdrawDialog(context, ref, uid),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Withdraw'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            txnsAsync.when(
              data: (txns) => txns.isEmpty
                  ? const EmptyStateWidget(
                      title: 'No transactions yet',
                      subtitle: 'Deposits and payments will appear here.',
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: txns.length,
                      itemBuilder: (_, i) =>
                          _TransactionTile(txn: txns[i]),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 8),
                child: ShimmerLoading(),
              ),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDepositDialog(
      BuildContext context, WidgetRef ref, String uid) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deposit to Wallet'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (KES)',
            prefixText: 'KES ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
                context, double.tryParse(controller.text.trim()) ?? 0),
            child: const Text('Deposit'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    final balance =
        await ref.read(walletProvider.notifier).deposit(uid: uid, amount: amount);
    if (!context.mounted) return;
    if (balance != null) {
      Helpers.showSnackBar(
        context,
        'Top-up successful. Balance: ${Helpers.formatCurrency(balance)}',
      );
    } else {
      Helpers.showSnackBar(context, 'Deposit failed', isError: true);
    }
  }

  Future<void> _showWithdrawDialog(
      BuildContext context, WidgetRef ref, String uid) async {
    final wallet = ref.read(currentWalletProvider).value;
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw to M-Pesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Available: ${Helpers.formatCurrency(wallet?.balance ?? 0)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                prefixText: 'KES ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-Pesa phone number',
                hintText: '07XX XXX XXX',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) return;
    await ref.read(walletProvider.notifier).withdraw(
          uid: uid,
          amount: amount,
          phone: phoneController.text.trim(),
        );
    if (!context.mounted) return;
    final error = ref.read(walletProvider).error;
    if (error != null) {
      Helpers.showSnackBar(context, error, isError: true);
    } else {
      Helpers.showSnackBar(
        context,
        'Withdrawal request submitted for admin approval.',
      );
    }
  }
}

class _BalanceCard extends ConsumerWidget {
  final WalletModel? wallet;
  final bool isAdmin;
  const _BalanceCard({required this.wallet, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = wallet?.balance ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wallet == null ? 'Loading wallet...' : 'Available Balance',
                style: const TextStyle(color: Colors.white70),
              ),
              Icon(
                isAdmin
                    ? Icons.admin_panel_settings
                    : Icons.account_balance_wallet,
                color: Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            wallet == null ? '—' : Helpers.formatCurrency(balance),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                label: 'Credited',
                value: Helpers.formatCurrency(wallet?.totalCredited ?? 0),
              ),
              const SizedBox(width: 24),
              _MiniStat(
                label: 'Withdrawn',
                value: Helpers.formatCurrency(wallet?.totalDebited ?? 0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransactionModel txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.isCredit;
    final color = isCredit ? AppColors.success : AppColors.error;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(20),
          child: Icon(_iconFor(txn.source), color: color, size: 20),
        ),
        title: Text(_titleFor(txn)),
        subtitle: Text(
          '${Helpers.formatDateTime(txn.createdAt)}'
          '${txn.status == 'pending' ? ' · Pending approval' : ''}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'}${txn.amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (txn.referenceId != null)
              Text(
                txn.referenceId!.length > 14
                    ? txn.referenceId!.substring(0, 14)
                    : txn.referenceId!,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String source) {
    switch (source) {
      case 'rent':
        return Icons.home_work;
      case 'premium':
        return Icons.workspace_premium;
      case 'deposit':
        return Icons.savings;
      case 'withdrawal':
        return Icons.logout;
      case 'quiz_reward':
        return Icons.emoji_events;
      case 'refund':
        return Icons.replay;
      default:
        return Icons.swap_horiz;
    }
  }

  String _titleFor(WalletTransactionModel txn) {
    if (txn.description.isNotEmpty) return txn.description;
    switch (txn.source) {
      case 'rent':
        return 'Rent payment';
      case 'premium':
        return 'Premium subscription';
      case 'deposit':
        return 'Wallet top-up';
      case 'withdrawal':
        return 'Withdrawal to M-Pesa';
      default:
        return txn.source;
    }
  }
}

class _PendingWithdrawalsSection extends ConsumerWidget {
  final String uid;
  const _PendingWithdrawalsSection({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingWithdrawalsProvider);
    return pending.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Withdrawals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...list.map((txn) => _WithdrawalTile(txn: txn)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _WithdrawalTile extends ConsumerWidget {
  final WalletTransactionModel txn;
  const _WithdrawalTile({required this.txn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.logout, size: 20),
        ),
        title: Text(txn.description.isEmpty ? 'Withdrawal' : txn.description),
        subtitle: Text(Helpers.formatDateTime(txn.createdAt)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'KES ${txn.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final ok =
                    await ref.read(walletProvider.notifier).processWithdrawal(txn.id);
                if (ok) {
                  final actor = ref.read(authServiceProvider).currentUser?.uid ?? '';
                  ref.read(auditLogRepositoryProvider).log(
                    actorId: actor,
                    action: 'withdrawal_processed',
                    targetType: 'wallet_transaction',
                    targetId: txn.id,
                    metadata: {
                      'userId': txn.userId,
                      'amount': txn.amount,
                    },
                  );
                  ref.read(pushServiceProvider).send(
                    recipientUid: txn.userId,
                    title: 'Withdrawal processed',
                    body:
                        'Your withdrawal of ${Helpers.formatCurrency(txn.amount)} has been approved and paid out.',
                    data: {'type': 'wallet'},
                  );
                }
                if (!context.mounted) return;
                Helpers.showSnackBar(
                  context,
                  ok ? 'Withdrawal approved & paid out' : 'Failed to process',
                  isError: !ok,
                );
              },
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }
}