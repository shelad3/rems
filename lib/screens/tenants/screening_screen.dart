import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tenant.dart';
import '../../providers/tenant_provider.dart';

class ScreeningScreen extends StatefulWidget {
  const ScreeningScreen({super.key});

  @override
  State<ScreeningScreen> createState() => _ScreeningScreenState();
}

class _ScreeningScreenState extends State<ScreeningScreen> {
  final Map<int, Map<String, dynamic>> _screeningResults = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().loadTenants();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pass':
        return Colors.green;
      case 'Fail':
        return Colors.red;
      case 'In Review':
        return Colors.orange;
      case 'Pending':
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pass':
        return Icons.check_circle;
      case 'Fail':
        return Icons.cancel;
      case 'In Review':
        return Icons.rate_review;
      case 'Pending':
      default:
        return Icons.schedule;
    }
  }

  void _showScreeningSheet(BuildContext context, Tenant tenant) {
    final result = _screeningResults.putIfAbsent(
      tenant.id!,
      () => {'status': 'Pending', 'notes': ''},
    );

    String selectedStatus = result['status'] as String;
    final notesController = TextEditingController(text: result['notes'] as String);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Screen ${tenant.name}',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(tenant.email, style: Theme.of(ctx).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Text('Status', style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: selectedStatus,
                    onChanged: (v) {
                      if (v != null) {
                        setSheetState(() => selectedStatus = v);
                      }
                    },
                    child: Column(
                      children: ['Pending', 'In Review', 'Pass', 'Fail'].map(
                        (s) => RadioListTile<String>(
                          value: s,
                          title: Row(
                            children: [
                              Icon(_statusIcon(s), size: 20, color: _statusColor(s)),
                              const SizedBox(width: 8),
                              Text(s),
                            ],
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Notes', style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter screening notes...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        _screeningResults[tenant.id!] = {
                          'status': selectedStatus,
                          'notes': notesController.text,
                        };
                        debugPrint(
                          'Screening result for ${tenant.name}: '
                          'status=$selectedStatus, notes=${notesController.text}',
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Screening result saved for ${tenant.name}',
                            ),
                          ),
                        );
                        setState(() {});
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TenantProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tenant Screening')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.tenants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No tenants to screen',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Add tenants first to begin screening',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadTenants(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.tenants.length,
                    itemBuilder: (context, index) {
                      final tenant = provider.tenants[index];
                      final result = _screeningResults[tenant.id];
                      final status = result != null
                          ? result['status'] as String
                          : 'Pending';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(tenant.name.isNotEmpty
                                ? tenant.name[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(tenant.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tenant.email),
                              Text('${tenant.phone}  |  ID: ${tenant.idNumber}'),
                            ],
                          ),
                          trailing: Chip(
                            avatar: Icon(_statusIcon(status),
                                size: 16, color: _statusColor(status)),
                            label: Text(
                              status,
                              style: TextStyle(
                                color: _statusColor(status),
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor:
                                _statusColor(status).withValues(alpha: 0.1),
                            side: BorderSide.none,
                          ),
                          isThreeLine: true,
                          onTap: () => _showScreeningSheet(context, tenant),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
