import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routes/app_routes.dart';
import '../../tenant/screens/tenant_properties_screen.dart';

class GuestShell extends StatefulWidget {
  const GuestShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<GuestShell> createState() => _GuestShellState();
}

class _GuestShellState extends State<GuestShell> {
  late int _currentIndex = widget.initialIndex;

  final List<Widget> _screens = const [
    TenantPropertiesScreen(),
    _GuestSignInScreen(),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.login_outlined), label: 'Sign In'),
        ],
      ),
    );
  }
}

class _GuestSignInScreen extends ConsumerWidget {
  const _GuestSignInScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_pin_circle_outlined, size: 96),
              const SizedBox(height: 24),
              const Text(
                'Create an account to unlock the full experience.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign up as a tenant to request property access, pay rent, raise maintenance tickets and chat with your landlord.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.roleSelection),
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.login),
                child: const Text('I already have an account'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.register),
                child: const Text('Register as Tenant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}