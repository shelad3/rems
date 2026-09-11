import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/routes/navigation.dart';
import '../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';
import '../../../data/services/auth_service.dart';

class PhoneSignupScreen extends ConsumerStatefulWidget {
  final String? initialRole;
  const PhoneSignupScreen({super.key, this.initialRole});

  @override
  ConsumerState<PhoneSignupScreen> createState() => _PhoneSignupScreenState();
}

class _PhoneSignupScreenState extends ConsumerState<PhoneSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countyController = TextEditingController();
  final _codeController = TextEditingController();
  String _selectedRole = 'tenant';
  bool _acceptTerms = false;
  bool _sending = false;
  bool _awaitingCode = false;

  final List<String> _roles = ['tenant', 'caretaker', 'owner', 'manager'];

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null && _roles.contains(widget.initialRole)) {
      _selectedRole = widget.initialRole!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countyController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _routeAfterAuth() {
    final user = ref.read(authProvider).user;
    if (user == null) {
      Navigation.pushClearingStack(context, AppRoutes.splash);
      return;
    }
    final String route;
    final bool isAdmin = user.email == superAdminEmail || user.role == 'admin';
    if (!user.isVerified && !isAdmin && user.email.isNotEmpty) {
      route = AppRoutes.verification;
    } else {
      route = Navigation.routeForRole(user.role);
    }
    Navigation.pushClearingStack(context, route);
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      Helpers.showSnackBar(
          context, 'Please accept the terms and conditions', isError: true);
      return;
    }
    setState(() => _sending = true);
    final step =
        await ref.read(authProvider.notifier).sendPhoneCode(_phoneController.text.trim());
    if (!mounted) return;
    setState(() {
      _sending = false;
      _awaitingCode = step == PhoneAuthStep.codeSent;
    });
    if (step == PhoneAuthStep.autoSignedIn) {
      _routeAfterAuth();
      return;
    }
    if (step == PhoneAuthStep.failed) {
      final error = ref.read(authProvider).error;
      Helpers.showSnackBar(context, error ?? 'Failed to send code', isError: true);
      return;
    }
  }

  Future<void> _verifyAndFinish() async {
    final verificationId = ref.read(authProvider).pendingVerificationId;
    if (verificationId == null) {
      Helpers.showSnackBar(
          context, 'Verification expired. Request a new code.', isError: true);
      return;
    }
    if (_codeController.text.trim().isEmpty) {
      Helpers.showSnackBar(context, 'Enter the SMS code', isError: true);
      return;
    }
    setState(() => _sending = true);
    final success = await ref
        .read(authProvider.notifier)
        .verifyPhoneAndLogin(
          verificationId: verificationId,
          smsCode: _codeController.text.trim(),
          fullName: _nameController.text.trim(),
          role: _selectedRole,
          county: _countyController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (success) {
      _routeAfterAuth();
    } else {
      final error = ref.read(authProvider).error;
      Helpers.showSnackBar(context, error ?? 'Verification failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Register with Phone')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create your account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign up as a tenant, owner, manager or caretaker using your phone',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const Text('Role',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _roles.map((role) {
                    final selected = _selectedRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: selected,
                        label: Text(
                            role[0].toUpperCase() + role.substring(1)),
                        onSelected: (val) =>
                            setState(() => _selectedRole = role),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.required(v, 'Full name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+2547XXXXXXXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countyController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'County / Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _acceptTerms,
                      onChanged: (v) =>
                          setState(() => _acceptTerms = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'I accept the Terms and Conditions & Privacy Policy',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_awaitingCode) ...[
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'SMS Code',
                    prefixIcon: Icon(Icons.sms_outlined),
                    hintText: '6-digit code sent via SMS',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _verifyAndFinish,
                    child: _sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify & Create Account'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _sending
                        ? null
                        : () => setState(() => _awaitingCode = false),
                    child: const Text('Change phone number'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (authState.loading || _sending) ? null : _sendCode,
                    child: _sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send Verification Code'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, AppRoutes.login),
                    child: const Text('Sign In'),
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