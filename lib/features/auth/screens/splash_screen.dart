import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/routes/navigation.dart';
import '../../../data/services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 1));
    _checkAuth();
  }

  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _routeToDashboard();
    } else {
      _navigateTo(AppRoutes.welcome);
    }
  }

  Future<void> _routeToDashboard() async {
    final userModel = await ref.read(authServiceProvider).getCurrentUserModel();
    if (!mounted) return;
    if (userModel == null) {
      _navigateTo(AppRoutes.welcome);
      return;
    }
    String route;
    switch (userModel.role) {
      case 'tenant':
        route = AppRoutes.tenantHome;
        break;
      case 'caretaker':
        route = AppRoutes.caretakerHome;
        break;
      case 'owner':
      case 'manager':
        route = AppRoutes.ownerHome;
        break;
      case 'admin':
        route = AppRoutes.adminHome;
        break;
      default:
        route = AppRoutes.welcome;
    }
    _navigateTo(route);
  }

  void _navigateTo(String route) {
    Navigation.pushClearingStack(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.home_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'REMS',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Real Estate Management',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
