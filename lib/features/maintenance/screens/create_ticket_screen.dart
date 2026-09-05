import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/models/maintenance_ticket_model.dart';
import '../providers/maintenance_provider.dart';
import '../../../widgets/loading_widget.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _accessCtrl = TextEditingController();
  String _category = 'plumbing';
  String _priority = 'medium';
  final List<File> _images = [];
  bool _submitting = false;

  final _categories = [
    'plumbing', 'electrical', 'structural', 'appliance', 'pest', 'cleaning', 'other',
  ];

  final _priorities = ['low', 'medium', 'high', 'emergency'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _accessCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() {
        _images.addAll(files.map((f) => File(f.path)));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) {
        Helpers.showSnackBar(context, 'Please log in first', isError: true);
        return;
      }

      final userModel = await ref.read(authServiceProvider).getCurrentUserModel();
      final ticketId = FirebaseFirestore.instance.collection('maintenance_tickets').doc().id;

      List<String> photoUrls = [];
      for (final image in _images) {
        final url = await FirebaseService().uploadFileFromPath(
          'maintenance/${userModel?.currentPropertyId ?? ''}/$ticketId',
          'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          image.path,
        );
        photoUrls.add(url);
      }

      final ticket = MaintenanceTicketModel(
        ticketId: ticketId,
        tenantId: user.uid,
        propertyId: userModel?.currentPropertyId ?? '',
        unitId: userModel?.currentUnitId ?? '',
        priority: _priority,
        category: _category,
        description: '${_titleCtrl.text}\n${_descCtrl.text}${_accessCtrl.text.isNotEmpty ? '\nAccess: ${_accessCtrl.text}' : ''}',
        photoUrls: photoUrls,
        tenantName: userModel?.fullName,
        tenantPhone: userModel?.phone,
      );

      await ref.read(maintenanceProvider.notifier).createTicket(ticket);

      if (mounted) {
        Helpers.showSnackBar(context, 'Maintenance ticket created successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to create ticket: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: _submitting
          ? const ShimmerLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _category = v ?? 'plumbing'),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Priority', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: _priorities.map((p) => ButtonSegment(
                        value: p,
                        label: Text(p.toUpperCase(), style: const TextStyle(fontSize: 11)),
                      )).toList(),
                      selected: {_priority},
                      onSelectionChanged: (v) => setState(() => _priority = v.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.length < 5) ? 'At least 5 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 4,
                      validator: (v) => (v == null || v.length < 10) ? 'At least 10 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _accessCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Access Instructions (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add Photos'),
                        ),
                        const SizedBox(width: 12),
                        if (_images.isNotEmpty)
                          Text('${_images.length} selected', style: const TextStyle(color: AppColors.success)),
                      ],
                    ),
                    if (_images.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (_, i) => Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_images[i], width: 80, height: 80, fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 0, right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _images.removeAt(i)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: const Icon(Icons.send_outlined),
                        label: Text(_submitting ? 'Submitting...' : 'Submit Ticket'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
