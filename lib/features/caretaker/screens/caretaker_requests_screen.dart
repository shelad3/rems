import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/access_request_model.dart';
import '../../../widgets/request_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';


class CaretakerRequestsScreen extends ConsumerWidget {
  const CaretakerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Requests'),
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<AccessRequestModel>>(
      stream: ref.watch(requestRepositoryProvider).getAllPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.check_circle_outline,
            title: 'No pending requests',
            subtitle: 'All requests have been handled',
          );
        }
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (_, i) => RequestCard(
            request: requests[i],
            onTap: () => _showRequestDetail(context, requests[i], ref),
            onApprove: () => _handleApprove(context, requests[i], ref),
            onReject: () => _handleReject(context, requests[i], ref),
          ),
        );
      },
    );
  }

  void _showRequestDetail(BuildContext context, AccessRequestModel request, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.tenantName ?? 'Tenant', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _DetailRow(label: 'Phone', value: request.tenantPhone ?? 'N/A'),
            _DetailRow(label: 'Email', value: request.tenantEmail ?? 'N/A'),
            _DetailRow(label: 'Move-in Date', value: request.desiredMoveInDate ?? 'Not specified'),
            _DetailRow(label: 'Requested', value: Helpers.timeAgo(request.requestedAt)),
            if (request.notes != null) _DetailRow(label: 'Notes', value: request.notes!),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, AccessRequestModel request, WidgetRef ref) async {
    await ref.read(requestRepositoryProvider).updateRequest(request.requestId, {
      'status': 'approved',
      'reviewedBy': ref.read(authServiceProvider).currentUser?.uid,
      'reviewedAt': Timestamp.now(),
    });
    if (context.mounted) {
      Helpers.showSnackBar(context, 'Request approved');
    }
  }

  Future<void> _handleReject(BuildContext context, AccessRequestModel request, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(context, text.isEmpty ? 'Rejected' : text);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null) {
      await ref.read(requestRepositoryProvider).updateRequest(request.requestId, {
        'status': 'rejected',
        'reviewedBy': ref.read(authServiceProvider).currentUser?.uid,
        'reviewedAt': Timestamp.now(),
        'notes': reason,
      });
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Request rejected');
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
