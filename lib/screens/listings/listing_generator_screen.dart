import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/property.dart';
import '../../providers/property_provider.dart';

class ListingGeneratorScreen extends StatefulWidget {
  final Property? property;

  const ListingGeneratorScreen({super.key, this.property});

  @override
  State<ListingGeneratorScreen> createState() => _ListingGeneratorScreenState();
}

class _ListingGeneratorScreenState extends State<ListingGeneratorScreen> {
  Property? _selectedProperty;

  @override
  void initState() {
    super.initState();
    _selectedProperty = widget.property;
    if (widget.property == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PropertyProvider>().loadProperties();
      });
    }
  }

  String _generateListing(Property p) {
    return [
      'Property Listing',
      '===============',
      'Name: ${p.name}',
      'Address: ${p.address}',
      'City: ${p.city}',
      'State: ${p.state}',
      'Type: ${p.type}',
      'Status: ${p.status}',
      'Total Units: ${p.totalUnits}',
      'Notes: ${p.notes}',
    ].join('\n');
  }

  void _shareListing() {
    if (_selectedProperty == null) return;
    final text = _generateListing(_selectedProperty!);
    Share.share(text);
  }

  void _copyToClipboard() {
    if (_selectedProperty == null) return;
    final text = _generateListing(_selectedProperty!);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();
    final properties = provider.properties;

    if (_selectedProperty == null && widget.property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Generate Listing')),
        body: properties.isEmpty
            ? const Center(child: Text('No properties available'))
            : ListView.builder(
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final p = properties[index];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('${p.address}, ${p.city}, ${p.state}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() => _selectedProperty = p);
                    },
                  );
                },
              ),
      );
    }

    final p = _selectedProperty!;
    final listing = _generateListing(p);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Listing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => _selectedProperty = null),
            tooltip: 'Choose different property',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Listing for ${p.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    listing,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareListing,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Listing'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy to Clipboard'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
