import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vendor_provider.dart';
import 'add_edit_vendor_screen.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().loadVendors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddEditVendorScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.vendors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.handyman_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No vendors yet',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddEditVendorScreen()),
                        ),
                        child: const Text('Add a Vendor'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadVendors(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.vendors.length,
                    itemBuilder: (_, i) {
                      final vendor = provider.vendors[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _categoryColor(vendor.category)
                                .withValues(alpha: 0.1),
                            child: Icon(Icons.handyman,
                                color: _categoryColor(vendor.category)),
                          ),
                          title: Text(vendor.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${vendor.category} \u2022 ${vendor.phone}',
                              style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!vendor.isActive)
                                const Chip(
                                  label: Text('Inactive',
                                      style: TextStyle(fontSize: 10)),
                                  backgroundColor: Colors.orange,
                                  side: BorderSide.none,
                                  visualDensity: VisualDensity.compact,
                                ),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddEditVendorScreen(
                                            vendor: vendor),
                                      ),
                                    );
                                  } else if (v == 'delete') {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title:
                                            const Text('Delete Vendor'),
                                        content: Text(
                                            'Delete ${vendor.name}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child:
                                                const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true && context.mounted) {
                                      await context
                                          .read<VendorProvider>()
                                          .deleteVendor(vendor.id!);
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Row(children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ])),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        Icon(Icons.delete,
                                            size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style: TextStyle(
                                                color: Colors.red)),
                                      ])),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Plumber':
        return Colors.blue;
      case 'Electrician':
        return Colors.orange;
      case 'Carpenter':
        return Colors.brown;
      case 'Painter':
        return Colors.purple;
      case 'Cleaner':
        return Colors.teal;
      case 'Gardener':
        return Colors.green;
      case 'Security':
        return Colors.red;
      case 'HVAC':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
