import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/unit_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/audit_log_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firebase_service.dart';

const _propertyTypes = [
  'apartment',
  'multiplex',
  'hostel',
  'mixed-use',
  'commercial',
  'townhouse',
  'bedsitter block',
  'other',
];

const _availableAmenities = [
  'water',
  'electricity',
  'parking',
  'security',
  'gym',
  'swimming pool',
  'laundry',
  'WiFi',
  'furnished',
  'elevator',
  'borehole',
  'garbage collection',
];

class AddPropertyScreen extends ConsumerStatefulWidget {
  final PropertyModel? property;

  const AddPropertyScreen({super.key, this.property});

  bool get isEdit => property != null;

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _countyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitCountController = TextEditingController();
  final _defaultRentController = TextEditingController();
  final _defaultDepositController = TextEditingController();
  final _startingRentController = TextEditingController();

  String _propertyType = 'apartment';
  final Set<String> _amenities = {};
  XFile? _coverImage;
  bool _uploadingImage = false;
  String? _coverImageUrl;

  String? _ownerId;
  String? _caretakerId;

  bool _saving = false;

  bool get _isAdmin =>
      ref.read(currentUserProvider).valueOrNull?.role == 'admin';

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    if (p != null) {
      _nameController.text = p.name;
      _locationController.text = p.location;
      _countyController.text = p.county;
      _descriptionController.text = p.description;
      _propertyType = p.propertyType.isEmpty ? 'apartment' : p.propertyType;
      _amenities.addAll(p.amenities);
      _coverImageUrl = p.coverImageUrl;
      _ownerId = p.ownerId;
      _caretakerId = p.caretakerId;
      if (p.startingRent > 0) {
        _startingRentController.text = p.startingRent.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _countyController.dispose();
    _descriptionController.dispose();
    _unitCountController.dispose();
    _defaultRentController.dispose();
    _defaultDepositController.dispose();
    _startingRentController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() {
      _coverImage = picked;
      _coverImageUrl = null;
    });
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
      final propertyId = widget.property?.propertyId ??
          FirebaseFirestore.instance.collection('properties').doc().id;

      String? coverUrl = _coverImageUrl;
      if (_coverImage != null) {
        setState(() => _uploadingImage = true);
        final bytes = await _coverImage!.readAsBytes();
        coverUrl = await ref
            .read(firebaseServiceProvider)
            .uploadFile('properties/$propertyId', 'cover.jpg', bytes);
      }

      final startingRent =
          double.tryParse(_startingRentController.text.trim()) ?? 0;

      final String? ownerId;
      final String? managerId;
      if (_isAdmin && _ownerId != null) {
        ownerId = _ownerId;
      } else if (user.role == 'owner') {
        ownerId = user.uid;
      } else {
        ownerId = null;
      }
      if (user.role == 'manager') {
        managerId = user.uid;
      } else {
        managerId = null;
      }

      if (widget.isEdit) {
        await ref.read(propertyRepositoryProvider).updateProperty(propertyId, {
          'name': _nameController.text.trim(),
          'location': _locationController.text.trim(),
          'county': _countyController.text.trim(),
          'description': _descriptionController.text.trim(),
          'propertyType': _propertyType,
          'amenities': _amenities.toList(),
          if (_isAdmin) 'ownerId': _ownerId,
          if (widget.property?.caretakerId != _caretakerId)
            'caretakerId': _caretakerId,
          'coverImageUrl': coverUrl,
          'startingRent': startingRent,
        });
        ref.read(auditLogRepositoryProvider).log(
          actorId: user.uid,
          action: 'property_updated',
          targetType: 'property',
          targetId: propertyId,
          metadata: {
            'name': _nameController.text.trim(),
            'ownerId': ownerId,
            'caretakerId': _caretakerId ?? '',
          },
        );
        if (!mounted) return;
        Helpers.showSnackBar(context, 'Property updated');
        Navigator.of(context).pop(true);
        return;
      }

      final property = PropertyModel(
        propertyId: propertyId,
        ownerId: ownerId,
        managerId: managerId,
        caretakerId: _caretakerId,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        county: _countyController.text.trim(),
        description: _descriptionController.text.trim(),
        propertyType: _propertyType,
        amenities: _amenities.toList(),
        coverImageUrl: coverUrl,
        startingRent: startingRent,
        createdBy: user.uid,
        createdByRole: (_isAdmin && _ownerId != null) ? 'owner' : user.role,
      );

      await ref.read(propertyRepositoryProvider).createProperty(property);
      ref.read(auditLogRepositoryProvider).log(
        actorId: user.uid,
        action: 'property_created',
        targetType: 'property',
        targetId: property.propertyId,
        metadata: {
          'name': property.name,
          'ownerId': ownerId,
          'caretakerId': _caretakerId ?? '',
        },
      );

      await _createUnits(propertyId);

      if (!mounted) return;
      Helpers.showSnackBar(context, 'Property added successfully');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Failed to save property: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createUnits(String propertyId) async {
    final count = int.tryParse(_unitCountController.text.trim()) ?? 0;
    if (count <= 0) return;
    final rent = double.tryParse(_defaultRentController.text.trim()) ?? 0;
    final deposit =
        double.tryParse(_defaultDepositController.text.trim()) ?? rent;

    final repo = ref.read(propertyRepositoryProvider);
    for (int i = 1; i <= count; i++) {
      final unitId = FirebaseFirestore.instance.collection('units').doc().id;
      await repo.createUnit(
        UnitModel(
          unitId: unitId,
          propertyId: propertyId,
          unitNumber: '$i',
          unitType: _propertyType == 'bedsitter block' || _propertyType == 'apartment'
              ? 'bedsitter'
              : _propertyType,
          bedrooms: _propertyType.contains('bedroom')
              ? int.tryParse(_propertyType.split(' ').first) ?? 0
              : 0,
          rentAmount: rent,
          depositAmount: deposit,
        ),
      );
    }
    await repo.updateUnitsCount(propertyId, count, count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Property' : 'Add Property')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOwnerCaretakerSection(),
              const SizedBox(height: 8),
              _label('Cover Photo (optional)'),
              GestureDetector(
                onTap: _saving ? null : _pickCoverImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    image: _coverImage == null && _coverImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_coverImageUrl!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: _coverImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_coverImage!.path),
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _uploadingImage
                          ? const Center(child: CircularProgressIndicator())
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _coverImageUrl != null
                                        ? Icons.check_circle
                                        : Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _coverImageUrl != null
                                        ? 'Photo selected'
                                        : 'Tap to add a photo',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 20),
              _label('Property Name'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Sunshine Apartments'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter property name' : null,
              ),
              const SizedBox(height: 20),
              _label('Location'),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Nairobi West'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter location' : null,
              ),
              const SizedBox(height: 20),
              _label('County'),
              TextFormField(
                controller: _countyController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Nairobi'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter county' : null,
              ),
              const SizedBox(height: 20),
              _label('Description (optional)'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Describe the property'),
              ),
              const SizedBox(height: 20),
              _label('Property Type'),
              DropdownButtonFormField<String>(
                initialValue: _propertyType,
                decoration: const InputDecoration(),
                items: _propertyTypes
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(_titleCase(t))))
                    .toList(),
                onChanged: (v) => setState(() => _propertyType = v ?? 'apartment'),
              ),
              const SizedBox(height: 20),
              _label('Amenities (optional)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAmenities.map((a) {
                  final selected = _amenities.contains(a);
                  return FilterChip(
                    label: Text(a),
                    selected: selected,
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _amenities.add(a);
                      } else {
                        _amenities.remove(a);
                      }
                    }),
                  );
                }).toList(),
              ),
              if (!widget.isEdit) ...[
                const SizedBox(height: 28),
                _label('Add Units Now (optional)'),
                TextFormField(
                  controller: _unitCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'Number of units, e.g. 12 (0 = add later)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _defaultRentController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Rent / unit (KES)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _defaultDepositController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Deposit / unit (KES)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Units get auto-numbered 1..N. You can add, edit or delete '
                  'units later from the property.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
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
                      : Text(widget.isEdit ? 'Save Changes' : 'Add Property'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerCaretakerSection() {
    if (!_isAdmin && widget.property == null) {
      return const SizedBox.shrink();
    }
    final caretakersAsync =
        ref.watch(_caretakerListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isAdmin) ...[
          _label('Owner'),
          FutureBuilder<List<UserModel>>(
            future: ref.read(userRepositoryProvider).getAllUsers(),
            builder: (context, snapshot) {
              final owners = (snapshot.data ?? const <UserModel>[])
                  .where((u) => u.role == 'owner' || u.role == 'manager')
                  .toList();
              return DropdownButtonFormField<String>(
                initialValue: _ownerId,
                decoration: const InputDecoration(hintText: 'Select owner'),
                items: owners
                    .map((u) => DropdownMenuItem(
                        value: u.uid,
                        child: Text(
                            '${u.fullName} (${u.role})')))
                    .toList(),
                onChanged: (v) => setState(() => _ownerId = v),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
        _label('Caretaker (optional)'),
        caretakersAsync.when(
          data: (caretakers) => DropdownButtonFormField<String>(
            initialValue: _caretakerId,
            decoration: const InputDecoration(
                hintText: 'Employ a caretaker for this property'),
            items: [
              const DropdownMenuItem<String>(
                  value: null, child: Text('None')),
              ...caretakers
                  .map((u) => DropdownMenuItem(
                        value: u.uid,
                        child: Text(u.fullName),
                      ))
                  .toList(),
            ],
            onChanged: (v) => setState(() => _caretakerId = v),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Could not load caretakers'),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(text,
          style:
              const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }

  String _titleCase(String s) {
    return s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}

final _caretakerListProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).getUsersByRole('caretaker');
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});