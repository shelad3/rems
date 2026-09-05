import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../updates/providers/update_provider.dart';
import 'tenant_home_screen.dart';
import 'tenant_properties_screen.dart';
import 'tenant_requests_screen.dart';
import 'tenant_messages_screen.dart';
import 'tenant_profile_screen.dart';

class TenantShell extends ConsumerStatefulWidget {
  const TenantShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends ConsumerState<TenantShell> {
  late int _currentIndex = widget.initialIndex;

  final List<Widget> _screens = const [
    TenantHomeScreen(),
    TenantPropertiesScreen(),
    TenantRequestsScreen(),
    TenantMessagesScreen(),
    TenantProfileScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Properties'),
          BottomNavigationBarItem(icon: Icon(Icons.send_outlined), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
