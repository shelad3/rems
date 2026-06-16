import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/property_provider.dart';
import 'listing_generator_screen.dart';

class ListingListScreen extends StatefulWidget {
  const ListingListScreen({super.key});

  @override
  State<ListingListScreen> createState() => _ListingListScreenState();
}

class _ListingListScreenState extends State<ListingListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Listings')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.properties.isEmpty
              ? const Center(child: Text('No properties available'))
              : ListView.builder(
                  itemCount: provider.properties.length,
                  itemBuilder: (context, index) {
                    final property = provider.properties[index];
                    return ListTile(
                      title: Text(property.name),
                      subtitle: Text('${property.address}, ${property.city}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ListingGeneratorScreen(
                                property: property),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ListingGeneratorScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
