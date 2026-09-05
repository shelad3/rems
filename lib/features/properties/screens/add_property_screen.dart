import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/audit_log_repository.dart';
import '../../../data/services/auth_service.dart';

class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _countyController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _countyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      Helpers.showSnackBar(context, 'Please log in to add a property', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final property = PropertyModel(
        propertyId: FirebaseFirestore.instance.collection('properties').doc().id,
        ownerId: user.uid,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        county: _countyController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      await ref.read(propertyRepositoryProvider).createProperty(property);
      ref.read(auditLogRepositoryProvider).log(
        actorId: user.uid,
        action: 'property_created',
        targetType: 'property',
        targetId: property.propertyId,
        metadata: {'name': property.name},
      );
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Property added successfully');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to add property: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Property Name'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Sunshine Apartments'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter property name' : null,
              ),
              const SizedBox(height: 20),
              _label('Location'),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Nairobi West'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter location' : null,
              ),
              const SizedBox(height: 20),
              _label('County'),
              TextFormField(
                controller: _countyController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Nairobi'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter county' : null,
              ),
              const SizedBox(height: 20),
              _label('Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Describe the property'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Property'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }
}