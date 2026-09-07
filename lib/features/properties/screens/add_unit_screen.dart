import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/unit_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/audit_log_repository.dart';
import '../../../data/services/auth_service.dart';

const _unitTypes = [
  'bedsitter',
  'studio',
  '1 bedroom',
  '2 bedroom',
  '3 bedroom',
  'furnished',
];

class AddUnitScreen extends ConsumerStatefulWidget {
  final PropertyModel property;
  const AddUnitScreen({super.key, required this.property});

  @override
  ConsumerState<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends ConsumerState<AddUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitsCountController = TextEditingController(text: '1');
  final _previewController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  String _unitType = 'bedsitter';
  bool _saving = false;

  @override
  void dispose() {
    _unitsCountController.dispose();
    _previewController.dispose();
    _bedroomsController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      Helpers.showSnackBar(context, 'Please log in to add a unit', isError: true);
      return;
    }

    final count = int.tryParse(_unitsCountController.text.trim()) ?? 1;
    final rent = double.tryParse(_rentController.text.trim()) ?? 0;
    final deposit = double.tryParse(_depositController.text.trim()) ?? 0;

    setState(() => _saving = true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      final prefix = _previewController.text.trim();
      var created = 0;
      for (int i = 0; i < count; i++) {
        final unitId = FirebaseFirestore.instance.collection('units').doc().id;
        final unitNumber = count == 1
            ? prefix
            : prefix.isEmpty
                ? '${widget.property.totalUnits + i + 1}'
                : '${prefix}${widget.property.totalUnits + i + 1}';
        await repo.createUnit(
          UnitModel(
            unitId: unitId,
            propertyId: widget.property.propertyId,
            unitNumber: unitNumber,
            unitType: _unitType,
            bedrooms: int.tryParse(_bedroomsController.text.trim()) ?? 0,
            rentAmount: rent,
            depositAmount: deposit,
          ),
        );
        created++;
      }
      await repo.updateUnitsCount(
        widget.property.propertyId,
        widget.property.totalUnits + created,
        widget.property.availableUnits + created,
      );
      ref.read(auditLogRepositoryProvider).log(
        actorId: user.uid,
        action: 'units_created',
        targetType: 'property',
        targetId: widget.property.propertyId,
        metadata: {
          'count': created,
          'propertyId': widget.property.propertyId,
        },
      );
      if (!mounted) return;
      Helpers.showSnackBar(
        context,
        created == 1 ? 'Unit added successfully' : '$created units added',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to add units: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Units')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Property'),
              Text(
                widget.property.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              _label('Number of Units *'),
              TextFormField(
                controller: _unitsCountController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(hintText: 'e.g. 5 (adds 5 units)'),
                validator: (v) {
                  final value = int.tryParse((v ?? '').trim());
                  if (value == null || value <= 0) {
                    return 'Enter a valid number of units';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _label('Unit Number ${_isMultiple ? '(prefix + auto number)' : ' *'}'),
              TextFormField(
                controller: _previewController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: _isMultiple ? 'e.g. B, 1 (gives B1, B2...B5)' : 'e.g. B3',
                ),
                validator: (v) {
                  if (_isMultiple) return null;
                  return (v == null || v.trim().isEmpty) ? 'Enter unit number' : null;
                },
              ),
              const SizedBox(height: 20),
              _label('Unit Type'),
              DropdownButtonFormField<String>(
                initialValue: _unitType,
                decoration: const InputDecoration(),
                items: _unitTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _unitType = v ?? 'bedsitter'),
              ),
              const SizedBox(height: 20),
              _label('Bedrooms (optional)'),
              TextFormField(
                controller: _bedroomsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 1'),
              ),
              const SizedBox(height: 20),
              _label('Monthly Rent (KES) *'),
              TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 25000'),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null || value <= 0) return 'Enter a valid rent amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _label('Deposit (KES, optional)'),
              TextFormField(
                controller: _depositController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 25000'),
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
                      : Text(_isMultiple ? 'Add Units' : 'Add Unit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isMultiple {
    final count = int.tryParse(_unitsCountController.text.trim()) ?? 1;
    return count > 1;
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }
}