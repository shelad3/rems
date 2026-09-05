import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/helpers.dart';
import '../data/models/unit_model.dart';

class UnitCard extends StatelessWidget {
  final UnitModel unit;
  final VoidCallback? onTap;

  const UnitCard({super.key, required this.unit, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  unit.occupied ? Icons.people_outline : Icons.home_outlined,
                  color: _statusColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit ${unit.unitNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${unit.unitType} · ${unit.bedrooms} bedroom${unit.bedrooms > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          Helpers.formatCurrency(unit.rentAmount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('/mo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unit.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (unit.status) {
      case 'occupied':
        return AppColors.primary;
      case 'vacant':
        return AppColors.success;
      case 'maintenance':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}
