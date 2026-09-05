import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/routes/navigation.dart';
import '../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';
import '../../../data/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _phoneLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    if (success) {
      _routeAfterAuth();
    } else {
      final error = ref.read(authProvider).error;
      Helpers.showSnackBar(context, error ?? 'Login failed', isError: true);
    }
  }

  void _routeAfterAuth() {
    final user = ref.read(authProvider).user;
    if (user == null) {
      Navigation.pushClearingStack(context, AppRoutes.splash);
      return;
    }
    final String route;
    final bool isAdmin = user.email == superAdminEmail || user.role == 'admin';
    if (!user.isVerified && !isAdmin) {
      route = AppRoutes.verification;
    } else {
      route = Navigation.routeForRole(user.role);
    }
    Navigation.pushClearingStack(context, route);
  }

  Future<void> _signInWithGoogle() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (success) {
      _routeAfterAuth();
    } else {
      final error = ref.read(authProvider).error;
      Helpers.showSnackBar(context, error ?? 'Google sign-in failed', isError: true);
    }
  }

  Future<void> _signInWithPhone() async {
    final phone = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Phone Sign In'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+2547XXXXXXXX',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Send Code'),
            ),
          ],
        );
      },
    );
    if (phone == null || phone.isEmpty) return;
    if (!mounted) return;
    setState(() => _phoneLoading = true);
    final sent = await ref.read(authProvider.notifier).signInWithPhone(phone);
    if (!mounted) return;
    setState(() => _phoneLoading = false);
    if (!sent) {
      final error = ref.read(authProvider).error;
      Helpers.showSnackBar(context, error ?? 'Failed to send code', isError: true);
      return;
    }

    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Code'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'SMS code'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty) return;
    if (!mounted) return;

    setState(() => _phoneLoading = true);
    final success = await ref.read(authProvider.notifier).verifySmsCode(code);
    if (!mounted) return;
    setState(() => _phoneLoading = false);
    if (success) {
      _routeAfterAuth();
    } else {
      final error = ref.read(authProvider).error;
      Helpers.showSnackBar(context, error ?? 'Verification failed', isError: true);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (Validators.email(email) != null) {
      Helpers.showSnackBar(context, 'Enter a valid email first', isError: true);
      return;
    }
    final sent = await ref.read(authProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    if (sent) {
      Helpers.showSnackBar(context, 'Password reset link sent if email exists');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to your account',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: Validators.password,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.loading ? null : _login,
                  child: authState.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: authState.loading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Continue with Google'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (authState.loading || _phoneLoading) ? null : _signInWithPhone,
                  icon: _phoneLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.phone_outlined),
                  label: const Text('Continue with Phone'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.roleSelection),
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
