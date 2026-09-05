import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/owner_analytics_provider.dart';

class PropertySelector extends ConsumerWidget {
  const PropertySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final selectedId = ref.watch(selectedPropertyProvider);

    return propertiesAsync.when(
      data: (properties) {
        if (properties.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedId ?? properties.first.propertyId,
              isDense: true,
              items: properties.map((p) => DropdownMenuItem(
                value: p.propertyId,
                child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              )).toList(),
              onChanged: (id) => ref.read(selectedPropertyProvider.notifier).state = id,
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 120,
        height: 36,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
