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

class EditUnitScreen extends ConsumerStatefulWidget {
  final PropertyModel property;
  final UnitModel unit;
  const EditUnitScreen({super.key, required this.property, required this.unit});

  @override
  ConsumerState<EditUnitScreen> createState() => _EditUnitScreenState();
}

class _EditUnitScreenState extends ConsumerState<EditUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _unitNumberController;
  late final TextEditingController _bedroomsController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  late String _unitType;
  late bool _occupied;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _unitNumberController =
        TextEditingController(text: widget.unit.unitNumber);
    _bedroomsController =
        TextEditingController(text: widget.unit.bedrooms.toString());
    _rentController =
        TextEditingController(text: widget.unit.rentAmount.toStringAsFixed(0));
    _depositController =
        TextEditingController(text: widget.unit.depositAmount.toStringAsFixed(0));
    _unitType = widget.unit.unitType;
    _occupied = widget.unit.occupied;
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _bedroomsController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      Helpers.showSnackBar(context, 'Please log in', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(propertyRepositoryProvider).updateUnit(widget.unit.unitId, {
        'unitNumber': _unitNumberController.text.trim(),
        'unitType': _unitType,
        'bedrooms': int.tryParse(_bedroomsController.text.trim()) ?? 0,
        'rentAmount': double.tryParse(_rentController.text.trim()) ?? 0,
        'depositAmount': double.tryParse(_depositController.text.trim()) ?? 0,
        'occupied': _occupied,
        'status': _occupied ? 'occupied' : 'vacant',
      });

      if (_occupied != widget.unit.occupied) {
        final delta = _occupied ? -1 : 1;
        await ref.read(propertyRepositoryProvider).updateUnitsCount(
              widget.property.propertyId,
              widget.property.totalUnits,
              (widget.property.availableUnits + delta).clamp(0, widget.property.totalUnits),
            );
      }

      ref.read(auditLogRepositoryProvider).log(
        actorId: user.uid,
        action: 'unit_updated',
        targetType: 'unit',
        targetId: widget.unit.unitId,
        metadata: {'propertyId': widget.property.propertyId},
      );

      if (!mounted) return;
      Helpers.showSnackBar(context, 'Unit updated');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to update unit: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Unit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Unit Number *'),
              TextFormField(
                controller: _unitNumberController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. B3'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter unit number' : null,
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
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Occupied'),
                subtitle: Text(
                  _occupied
                      ? 'Unit is currently rented out'
                      : 'Unit is vacant and available',
                ),
                value: _occupied,
                onChanged: (v) => setState(() => _occupied = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
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
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }
}