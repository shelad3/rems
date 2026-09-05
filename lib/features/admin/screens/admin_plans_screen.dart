import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/subscription_plan_model.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../data/repositories/audit_log_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/empty_state.dart';

class AdminPlansScreen extends ConsumerWidget {
  const AdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Plan',
            onPressed: () => _openPlanForm(context, ref),
          ),
        ],
      ),
      body: StreamBuilder<List<SubscriptionPlanModel>>(
        stream: ref.watch(subscriptionRepositoryProvider).streamPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final plans = snapshot.data ?? [];
          if (plans.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.subscriptions_outlined,
              title: 'No plans created',
              subtitle: 'Add your first subscription plan',
              actionLabel: 'Add Plan',
              onAction: () => _openPlanForm(context, ref),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                plan: plans[i],
                onEdit: () => _openPlanForm(context, ref, plan: plans[i]),
                onDelete: () => _deletePlan(context, ref, plans[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _deletePlan(BuildContext context, WidgetRef ref, SubscriptionPlanModel plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan?'),
        content: Text('Are you sure you want to delete "${plan.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(subscriptionRepositoryProvider).deletePlan(plan.planId);
              final actor = ref.read(authServiceProvider).currentUser?.uid ?? '';
              ref.read(auditLogRepositoryProvider).log(
                actorId: actor,
                action: 'plan_deleted',
                targetType: 'plan',
                targetId: plan.planId,
                metadata: {'name': plan.name},
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _openPlanForm(BuildContext context, WidgetRef ref, {SubscriptionPlanModel? plan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _PlanForm(plan: plan),
      ),
    );
  }
}

class _PlanForm extends ConsumerStatefulWidget {
  final SubscriptionPlanModel? plan;
  const _PlanForm({this.plan});

  @override
  ConsumerState<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends ConsumerState<_PlanForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _featuresController;
  bool _isPremium = false;
  bool _isRecommended = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _priceController = TextEditingController(text: widget.plan?.price.toString() ?? '');
    _featuresController = TextEditingController(text: widget.plan?.features.join(', ') ?? '');
    _isPremium = widget.plan?.isPremium ?? false;
    _isRecommended = widget.plan?.isRecommended ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  void _logAudit(String action, String targetId, String name) {
    final actor = ref.read(authServiceProvider).currentUser?.uid ?? '';
    ref.read(auditLogRepositoryProvider).log(
          actorId: actor,
          action: action,
          targetType: 'plan',
          targetId: targetId,
          metadata: {'name': name},
        );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    if (name.isEmpty || price == null) {
      Helpers.showSnackBar(context, 'Enter a plan name and price', isError: true);
      return;
    }
    final features = _featuresController.text
        .split(',')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();

    setState(() => _saving = true);
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      if (widget.plan != null) {
        await repo.updatePlan(widget.plan!.planId, {
          'name': name,
          'price': price,
          'features': features,
          'isPremium': _isPremium,
          'isRecommended': _isRecommended,
        });
        _logAudit('plan_updated', widget.plan!.planId, name);
      } else {
        final newPlan = SubscriptionPlanModel(
          planId: FirebaseFirestore.instance.collection('subscriptions').doc().id,
          name: name,
          price: price,
          features: features,
          isPremium: _isPremium,
          isRecommended: _isRecommended,
        );
        await repo.createPlan(newPlan);
        _logAudit('plan_created', newPlan.planId, name);
      }
      if (mounted) {
        Helpers.showSnackBar(context, 'Plan saved');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to save plan: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.plan == null ? 'Add Plan' : 'Edit Plan',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Plan name', hintText: 'e.g. Premium'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Price (KES / month)', hintText: 'e.g. 2500'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _featuresController,
          decoration: const InputDecoration(
            labelText: 'Features (comma separated)',
            hintText: 'Unlimited properties, PDF exports',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Premium tier', style: TextStyle(fontSize: 14)),
                value: _isPremium,
                onChanged: (v) => setState(() => _isPremium = v),
              ),
            ),
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recommended', style: TextStyle(fontSize: 14)),
                value: _isRecommended,
                onChanged: (v) => setState(() => _isRecommended = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
                : const Text('Save Plan'),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlanCard({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        decoration: plan.isPremium
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.premiumBadge, width: 2),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(plan.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (plan.isPremium) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.workspace_premium, color: AppColors.premiumBadge, size: 20),
                  ],
                  if (plan.isRecommended) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('RECOMMENDED',
                          style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: onEdit,
                        tooltip: 'Edit plan',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: onDelete,
                        tooltip: 'Delete plan',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('KES ${plan.price.toStringAsFixed(0)}/${plan.billingPeriod}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.warning)),
              const SizedBox(height: 12),
              ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18,
                        color: plan.isPremium ? AppColors.success : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(f, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}