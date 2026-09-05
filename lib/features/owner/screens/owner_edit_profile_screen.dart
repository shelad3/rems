import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../widgets/loading_widget.dart';

class OwnerEditProfileScreen extends ConsumerStatefulWidget {
  const OwnerEditProfileScreen({super.key});

  @override
  ConsumerState<OwnerEditProfileScreen> createState() => _OwnerEditProfileScreenState();
}

class _OwnerEditProfileScreenState extends ConsumerState<OwnerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _businessRegCtrl;
  late TextEditingController _countyCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _companyCtrl = TextEditingController();
    _businessRegCtrl = TextEditingController();
    _countyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _businessRegCtrl.dispose();
    _countyCtrl.dispose();
    super.dispose();
  }

  void _populate(UserModel user) {
    _nameCtrl.text = user.fullName;
    _phoneCtrl.text = user.phone;
    _companyCtrl.text = user.companyName ?? '';
    _businessRegCtrl.text = user.businessRegistration ?? '';
    _countyCtrl.text = user.county ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authServiceProvider).updateProfile({
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'companyName': _companyCtrl.text.trim(),
        'businessRegistration': _businessRegCtrl.text.trim(),
        'county': _countyCtrl.text.trim(),
      });
      ref.invalidate(currentUserProvider);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (context.mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), actions: [
        _saving
            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : TextButton(onPressed: _save, child: const Text('Save')),
      ]),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_nameCtrl.text.isEmpty) _populate(user);
          });
          return _buildForm();
        },
        loading: () => const ShimmerLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildField(label: 'Full Name', controller: _nameCtrl, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            _buildField(label: 'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            _buildField(label: 'Company Name', controller: _companyCtrl),
            _buildField(label: 'Business Registration', controller: _businessRegCtrl),
            _buildField(label: 'County', controller: _countyCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
