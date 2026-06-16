import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vendor.dart';
import '../../providers/vendor_provider.dart';

class AddEditVendorScreen extends StatefulWidget {
  final Vendor? vendor;
  const AddEditVendorScreen({super.key, this.vendor});

  @override
  State<AddEditVendorScreen> createState() => _AddEditVendorScreenState();
}

class _AddEditVendorScreenState extends State<AddEditVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  String _category = 'General';
  bool _isActive = true;

  static const _categories = [
    'General', 'Plumber', 'Electrician', 'Carpenter', 'Painter',
    'Cleaner', 'Gardener', 'Security', 'HVAC', 'Locksmith',
    'Pest Control', 'Roofer', 'Handyman', 'Other',
  ];

  bool get _isEditing => widget.vendor != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final v = widget.vendor!;
      _nameCtrl.text = v.name;
      _contactCtrl.text = v.contactPerson;
      _emailCtrl.text = v.email;
      _phoneCtrl.text = v.phone;
      _addressCtrl.text = v.address;
      _notesCtrl.text = v.notes;
      _rateCtrl.text = v.hourlyRate?.toString() ?? '';
      _category = v.category;
      _isActive = v.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vendor = Vendor(
      id: widget.vendor?.id,
      name: _nameCtrl.text.trim(),
      contactPerson: _contactCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      category: _category,
      address: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      hourlyRate: double.tryParse(_rateCtrl.text),
      isActive: _isActive,
    );

    final provider = context.read<VendorProvider>();
    if (_isEditing) {
      await provider.updateVendor(vendor);
    } else {
      await provider.addVendor(vendor);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Vendor updated' : 'Vendor added'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vendor' : 'Add Vendor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Company/Vendor Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactCtrl,
              decoration: const InputDecoration(
                labelText: 'Contact Person',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rateCtrl,
              decoration: const InputDecoration(
                labelText: 'Hourly Rate (KSH)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Inactive vendors are hidden from assignments'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Update Vendor' : 'Add Vendor'),
            ),
          ],
        ),
      ),
    );
  }
}
