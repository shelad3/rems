import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../updates/providers/update_provider.dart';
import 'admin_users_screen.dart';
import 'admin_properties_screen.dart';
import 'admin_plans_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_audit_screen.dart';
import '../../wallet/screens/wallet_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  late int _currentIndex = widget.initialIndex;

  final List<Widget> _screens = const [
    AdminUsersScreen(),
    AdminPropertiesScreen(),
    AdminPlansScreen(),
    AdminAnalyticsScreen(),
    AdminAuditScreen(),
    WalletScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateControllerProvider).checkAndPrompt();
    });
  }

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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.home_work_outlined), label: 'Properties'),
          BottomNavigationBarItem(icon: Icon(Icons.subscriptions_outlined), label: 'Plans'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Audit'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
        ],
      ),
    );
  }
}
