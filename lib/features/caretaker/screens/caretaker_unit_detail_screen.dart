import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/unit_model.dart';
import '../../../data/models/inspection_model.dart';
import '../../../data/models/meter_reading_model.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../data/repositories/meter_reading_repository.dart';
import '../../../data/services/auth_service.dart';

class CaretakerUnitDetailScreen extends ConsumerWidget {
  final UnitModel unit;
  final String propertyId;
  final String propertyName;

  const CaretakerUnitDetailScreen({
    super.key,
    required this.unit,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('${propertyName} - ${unit.unitNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _UnitInfoCard(unit: unit),
          const SizedBox(height: 16),
          _ActionSection(
            icon: Icons.search_outlined,
            title: 'New Inspection',
            subtitle: 'Record unit condition',
            onTap: () => _showInspectionDialog(context, ref),
          ),
          const SizedBox(height: 8),
          _ActionSection(
            icon: Icons.speed_outlined,
            title: 'Meter Reading',
            subtitle: 'Record water/electricity reading',
            onTap: () => _showMeterDialog(context, ref),
          ),
          const SizedBox(height: 24),
          const Text('Inspection History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _InspectionHistory(unitId: unit.unitId),
          ),
          const SizedBox(height: 16),
          const Text('Meter Readings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _MeterReadingsList(unitId: unit.unitId),
          ),
        ],
      ),
    );
  }

  void _showInspectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _InspectionFormDialog(unit: unit, propertyId: propertyId),
    );
  }

  void _showMeterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _MeterReadingFormDialog(unit: unit, propertyId: propertyId),
    );
  }
}

class _UnitInfoCard extends StatelessWidget {
  final UnitModel unit;
  const _UnitInfoCard({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(unit.unitNumber, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: unit.occupied ? AppColors.success.withAlpha(20) : AppColors.textSecondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unit.occupied ? 'Occupied' : 'Vacant',
                    style: TextStyle(
                      color: unit.occupied ? AppColors.success : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
    _infoRow('Type', unit.unitType),
    _infoRow('Rent', Helpers.formatCurrency(unit.rentAmount)),
            _infoRow('Bedrooms', '${unit.bedrooms}'),
        
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withAlpha(25),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _InspectionHistory extends ConsumerWidget {
  final String unitId;
  const _InspectionHistory({required this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<InspectionModel>>(
      stream: ref.read(inspectionRepositoryProvider).getInspectionsByUnit(unitId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final inspections = snapshot.data ?? [];
        if (inspections.isEmpty) {
          return const Center(child: Text('No inspections yet', style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.builder(
          itemCount: inspections.length,
          itemBuilder: (_, i) {
            final insp = inspections[i];
            return ListTile(
              leading: Icon(
                insp.condition == 'good' ? Icons.check_circle : Icons.warning,
                color: insp.condition == 'good' ? AppColors.success : AppColors.warning,
              ),
              title: Text('Condition: ${insp.condition}'),
              subtitle: Text('${insp.notes} · ${Helpers.timeAgo(insp.createdAt)}'),
            );
          },
        );
      },
    );
  }
}

class _MeterReadingsList extends ConsumerWidget {
  final String unitId;
  const _MeterReadingsList({required this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<MeterReadingModel>>(
      stream: ref.read(meterReadingRepositoryProvider).getReadingsByUnit(unitId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final readings = snapshot.data ?? [];
        if (readings.isEmpty) {
          return const Center(child: Text('No readings yet', style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.builder(
          itemCount: readings.length,
          itemBuilder: (_, i) {
            final r = readings[i];
            return ListTile(
              leading: Icon(
                r.type == 'water' ? Icons.water_drop : Icons.bolt,
                color: r.type == 'water' ? AppColors.info : AppColors.warning,
              ),
              title: Text('${r.type.toUpperCase()} · ${r.value.toStringAsFixed(1)}'),
              subtitle: Text('${r.notes} · ${Helpers.timeAgo(r.createdAt)}'),
            );
          },
        );
      },
    );
  }
}

class _InspectionFormDialog extends ConsumerStatefulWidget {
  final UnitModel unit;
  final String propertyId;

  const _InspectionFormDialog({required this.unit, required this.propertyId});

  @override
  ConsumerState<_InspectionFormDialog> createState() => _InspectionFormDialogState();
}

class _InspectionFormDialogState extends ConsumerState<_InspectionFormDialog> {
  String _condition = 'good';
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final doc = FirebaseFirestore.instance.collection('inspections').doc();
      await ref.read(inspectionRepositoryProvider).createInspection(InspectionModel(
        inspectionId: doc.id,
        propertyId: widget.propertyId,
        unitId: widget.unit.unitId,
        inspectorId: user.uid,
        condition: _condition,
        notes: _notesCtrl.text.trim(),
      ));
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Inspection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Unit: ${widget.unit.unitNumber}'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _condition,
            items: ['good', 'fair', 'poor', 'damaged'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _condition = v ?? 'good'),
            decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}

class _MeterReadingFormDialog extends ConsumerStatefulWidget {
  final UnitModel unit;
  final String propertyId;

  const _MeterReadingFormDialog({required this.unit, required this.propertyId});

  @override
  ConsumerState<_MeterReadingFormDialog> createState() => _MeterReadingFormDialogState();
}

class _MeterReadingFormDialogState extends ConsumerState<_MeterReadingFormDialog> {
  String _type = 'water';
  final _valueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  double _prevReading = 0;

  @override
  void initState() {
    super.initState();
    _loadPrevReading();
  }

  Future<void> _loadPrevReading() async {
    final prev = await ref.read(meterReadingRepositoryProvider).getLatestReading(widget.unit.unitId, _type);
    if (mounted) setState(() => _prevReading = prev);
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_valueCtrl.text.trim());
    if (value == null || value <= 0) return;
    setState(() => _saving = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final doc = FirebaseFirestore.instance.collection('meter_readings').doc();
      await ref.read(meterReadingRepositoryProvider).recordReading(MeterReadingModel(
        readingId: doc.id,
        propertyId: widget.propertyId,
        unitId: widget.unit.unitId,
        type: _type,
        value: value,
        readBy: user.uid,
        notes: _notesCtrl.text.trim(),
      ));
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Meter Reading'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Unit: ${widget.unit.unitNumber}'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            items: ['water', 'electricity'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) {
              setState(() => _type = v ?? 'water');
              _loadPrevReading();
            },
            decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Reading Value',
              border: const OutlineInputBorder(),
              hintText: _prevReading > 0 ? 'Prev: ${_prevReading.toStringAsFixed(1)}' : 'Enter reading',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}
