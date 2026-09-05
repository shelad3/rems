import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/audit_log_model.dart';
import '../../../data/repositories/audit_log_repository.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';

class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _exportLogs(context, ref),
          ),
        ],
      ),
      body: StreamBuilder<List<AuditLogModel>>(
        stream: ref.read(auditLogRepositoryProvider).streamLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history,
              title: 'No audit logs yet',
              subtitle: 'System activities will be recorded here',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _AuditLogTile(log: logs[i]),
          );
        },
      ),
    );
  }

  Future<void> _exportLogs(BuildContext context, WidgetRef ref) async {
    try {
      final logs = await ref.read(auditLogRepositoryProvider).getLogs(limit: 200);
      if (logs.isEmpty) {
        Helpers.showSnackBar(context, 'No logs to export', isError: true);
        return;
      }

      final rows = <List<String>>[
        ['Date', 'Action', 'Target Type', 'Target ID', 'Actor ID'],
        ...logs.map((l) => [
          DateFormat('yyyy-MM-dd HH:mm').format(l.createdAt),
          l.action,
          l.targetType,
          l.targetId,
          l.actorId,
        ]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/audit_logs_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Audit Logs Export');
    } catch (e) {
      Helpers.showSnackBar(context, 'Export failed: $e', isError: true);
    }
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLogModel log;
  const _AuditLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: _actionColor.withAlpha(25),
        child: Icon(_actionIcon, size: 18, color: _actionColor),
      ),
      title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('${log.targetType} · ${log.targetId.substring(0, 8)}...',
          style: const TextStyle(fontSize: 12)),
      trailing: Text(
        Helpers.timeAgo(log.createdAt),
        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
      ),
      onTap: () => _showDetail(context),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log.action),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail('Actor', log.actorId),
            _detail('Target Type', log.targetType),
            _detail('Target ID', log.targetId),
            _detail('Date', Helpers.formatDateTime(log.createdAt)),
            if (log.metadata != null) ...[
              const SizedBox(height: 8),
              const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(log.metadata.toString(), style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Color get _actionColor {
    if (log.action.contains('delete') || log.action.contains('reject')) return AppColors.error;
    if (log.action.contains('create') || log.action.contains('approve')) return AppColors.success;
    if (log.action.contains('update')) return AppColors.info;
    return AppColors.textSecondary;
  }

  IconData get _actionIcon {
    if (log.action.contains('delete') || log.action.contains('reject')) return Icons.delete_outline;
    if (log.action.contains('create') || log.action.contains('approve')) return Icons.add_circle_outline;
    if (log.action.contains('update')) return Icons.edit_outlined;
    return Icons.info_outline;
  }
}
