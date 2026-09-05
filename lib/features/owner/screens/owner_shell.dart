import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../updates/providers/update_provider.dart';
import 'owner_overview_screen.dart';
import 'owner_properties_screen.dart';
import 'owner_finance_screen.dart';
import 'owner_reports_screen.dart';
import 'owner_profile_screen.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  late int _currentIndex = widget.initialIndex;

  final List<Widget> _screens = const [
    OwnerOverviewScreen(),
    OwnerPropertiesScreen(),
    OwnerFinanceScreen(),
    OwnerReportsScreen(),
    OwnerProfileScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.business_outlined), label: 'Properties'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Finance'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
