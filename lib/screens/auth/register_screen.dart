import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firestore = FirestoreService.instance;
  String _role = 'tenant';
  bool _obscurePassword = true;

  List<Map<String, dynamic>> _owners = [];
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _units = [];
  String? _selectedOwnerId;
  String? _selectedPropertyId;
  String? _selectedUnitId;
  bool _linkingLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadLinkingData() async {
    if (_linkingLoaded) return;

    try {
      final ownersSnap = await _firestore.db.collection('owners').get();
      _owners = ownersSnap.docs.map((d) {
            final map = <String, dynamic>{'id': d.id};
            final data = d.data() as Map<String, dynamic>?;
            if (data != null) map.addAll(data);
            return map;
          }).toList();
    } catch (_) {}

    try {
      final propsSnap = await _firestore.propertiesRef.get();
      _properties = propsSnap.docs.map((d) {
            final map = <String, dynamic>{'id': d.id};
            final data = d.data() as Map<String, dynamic>?;
            if (data != null) map.addAll(data);
            return map;
          }).toList();
    } catch (_) {}

    try {
      final unitsSnap = await _firestore.unitsRef.get();
      _units = unitsSnap.docs.map((d) {
            final map = <String, dynamic>{'id': d.id};
            final data = d.data() as Map<String, dynamic>?;
            if (data != null) map.addAll(data);
            return map;
          }).toList();
    } catch (_) {}

    _linkingLoaded = true;
  }

  Future<void> _register(AuthProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    int? ownerId;
    int? tenantId;

    if (_selectedOwnerId != null) {
      final match = _owners.firstWhere(
          (o) => o['id'] == _selectedOwnerId,
          orElse: () => <String, dynamic>{});
      if (match.isNotEmpty) {
        // Use the mapped SQLite ID if available (from oldOwnerId)
        ownerId = match['oldOwnerId'] as int?;
        if (ownerId == null) {
          ownerId = int.tryParse(match['id'] as String);
        }
      }
    }

    final ok = await provider.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      _role,
      phone: _phoneController.text.trim(),
      ownerId: ownerId,
      tenantId: tenantId,
    );
    if (ok && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.home_work_outlined, size: 48),
                  ),
                  const SizedBox(height: 8),
                  Text('Join REMS',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your phone';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                    labelText: 'I am a...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'landlord',
                        child: Text('Landlord / Property Manager')),
                    DropdownMenuItem(
                        value: 'owner', child: Text('Property Owner')),
                    DropdownMenuItem(
                        value: 'tenant', child: Text('Tenant / Renter')),
                    DropdownMenuItem(
                        value: 'caretaker', child: Text('Caretaker')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _role = v!;
                      _selectedOwnerId = null;
                      _selectedPropertyId = null;
                      _selectedUnitId = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                FutureBuilder(
                  future: _loadLinkingData(),
                  builder: (context, _) {
                    if (_role == 'landlord' || _role == 'caretaker') {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedOwnerId,
                            decoration: InputDecoration(
                              labelText: _role == 'caretaker'
                                  ? 'Manage for which Owner?'
                                  : 'Work with which Owner?',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            isExpanded: true,
                            hint: const Text('Select an owner (optional)'),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('None (skip)')),
                              ..._owners.map((o) => DropdownMenuItem(
                                  value: o['id'] as String,
                                  child: Text(o['name'] as String? ?? ''))),
                            ],
                            onChanged: (v) => setState(() {
                              _selectedOwnerId = v;
                              _selectedPropertyId = null;
                            }),
                          ),
                          if (_role == 'caretaker') ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedPropertyId,
                              decoration: const InputDecoration(
                                labelText: 'Manage which Property?',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.business),
                              ),
                              isExpanded: true,
                              hint: const Text('Select property (optional)'),
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('None (skip)')),
                                ..._properties.map((p) => DropdownMenuItem(
                                    value: p['id'] as String,
                                    child: Text(p['name'] as String? ?? ''))),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedPropertyId = v),
                            ),
                          ],
                        ],
                      );
                    }

                    if (_role == 'tenant') {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedPropertyId,
                            decoration: const InputDecoration(
                              labelText: 'Interested in which Property?',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            isExpanded: true,
                            hint: const Text('Select property (optional)'),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('Browse later')),
                              ..._properties.map((p) => DropdownMenuItem(
                                  value: p['id'] as String,
                                  child: Text(p['name'] as String? ?? ''))),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _selectedPropertyId = v;
                                _selectedUnitId = null;
                              });
                            },
                          ),
                          if (_selectedPropertyId != null) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedUnitId,
                              decoration: const InputDecoration(
                                labelText: 'Preferred Unit?',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.door_front_door),
                              ),
                              isExpanded: true,
                              hint: const Text('Select unit (optional)'),
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('Browse later')),
                                ..._units
                                    .where((u) =>
                                        u['propertyId'] == _selectedPropertyId &&
                                        u['status'] == 'vacant')
                                    .map((u) => DropdownMenuItem(
                                        value: u['id'] as String,
                                        child: Text(
                                            'Unit ${u['unitNumber']} - \$${(u['rentAmount'] as num?)?.toDouble() ?? 0}/mo'))),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedUnitId = v),
                            ),
                          ],
                        ],
                      );
                    }

                    if (_role == 'owner') {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 20, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'An owner profile will be created for you.',
                                style: TextStyle(
                                    fontSize: 13, color: colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
                if (authProvider.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    authProvider.error!,
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _register(authProvider),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Create Account',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In'),
                    ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
