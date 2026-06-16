import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inspection_provider.dart';

class InspectionDetailScreen extends StatefulWidget {
  final int inspectionId;
  const InspectionDetailScreen({super.key, required this.inspectionId});

  @override
  State<InspectionDetailScreen> createState() =>
      _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<InspectionProvider>()
          .loadInspectionItems(widget.inspectionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InspectionProvider>();
    final inspection = provider.inspections
        .where((i) => i.id == widget.inspectionId)
        .firstOrNull;

    if (inspection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection')),
        body: const Center(child: Text('Inspection not found')),
      );
    }

    final typeColor = inspection.type == 'Move-in'
        ? Colors.green
        : inspection.type == 'Move-out'
            ? Colors.orange
            : Colors.blue;

    return Scaffold(
      appBar: AppBar(title: Text(inspection.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(inspection.type,
                            style: TextStyle(
                                fontSize: 12, color: typeColor)),
                        backgroundColor: typeColor.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(inspection.overallCondition,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: _conditionColor(inspection.overallCondition)
                            .withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _row('Date',
                      DateFormat.yMMMd().format(inspection.inspectionDate)),
                  if (inspection.notes.isNotEmpty)
                    _row('Notes', inspection.notes),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Room-by-Room Results',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (provider.inspectionItems.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No room data recorded'),
            ))
          else
            ...provider.inspectionItems.map((item) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _conditionColor(item.condition)
                          .withValues(alpha: 0.1),
                      child: Icon(Icons.check,
                          color: _conditionColor(item.condition), size: 18),
                    ),
                    title: Text(item.roomName),
                    subtitle: Text('${item.category} \u2022 ${item.condition}'),
                    trailing: item.photoPath != null
                        ? Icon(Icons.image, size: 18, color: Colors.blue)
                        : null,
                    onTap: item.photoPath != null
                        ? () => _showPhoto(context, item.photoPath!)
                        : null,
                  ),
                )),
        ],
      ),
    );
  }

  void _showPhoto(BuildContext context, String path) {
    final file = File(path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo file not found')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _conditionColor(String condition) {
    switch (condition) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Fair':
        return Colors.orange;
      case 'Poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
