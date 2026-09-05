import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/navigation.dart';
import '../../../data/services/auth_service.dart';
import '../providers/auth_provider.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 3), _checkVerification);
  }

  Future<void> _checkVerification() async {
    if (_checking || !mounted) return;
    _checking = true;
    final verified = await ref.read(authServiceProvider).isEmailVerified();
    _checking = false;
    if (!mounted) return;
    if (verified) {
      final user = ref.read(authProvider).user;
      if (user != null && !user.isVerified) {
        await ref
            .read(authServiceProvider)
            .updateProfile({'isVerified': true});
      }
      _goToDashboard();
    } else {
      _startPolling();
    }
  }

  void _goToDashboard() {
    String role = 'tenant';
    final user = ref.read(authProvider).user;
    if (user != null) {
      role = user.role;
    }
    Navigation.pushClearingStack(context, Navigation.routeForRole(role));
  }

  Future<void> _resendEmail() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 48,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We have sent a verification link to your email address. Please check your inbox and click the link to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _resendEmail,
                  child: const Text('Resend Email'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _goToDashboard,
                child: const Text('I\'ll verify later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
