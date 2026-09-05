import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/navigation.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/app_update_model.dart';
import '../../../data/services/app_update_service.dart';

class UpdateController extends ChangeNotifier {
  final AppUpdateService _service = AppUpdateService();

  bool _checking = false;
  bool _updating = false;
  double _progress = 0;
  String? _error;
  bool _promptedThisSession = false;

  bool get checking => _checking;
  bool get updating => _updating;
  double get progress => _progress;
  String? get error => _error;

  Future<String> versionLabel() => _service.versionLabel();

  Future<void> checkAndPrompt({BuildContext? context, bool manual = false}) async {
    if (_checking || _updating) return;
    if (!manual && _promptedThisSession) return;

    _checking = true;
    _error = null;
    notifyListeners();
    AppUpdateInfo? info;
    try {
      info = await _service.checkForUpdate();
    } finally {
      _checking = false;
      notifyListeners();
    }

    final ctx = context ?? Navigation.navigatorKey.currentContext;
    if (ctx == null) return;

    if (info != null) {
      _promptedThisSession = true;
      await _showUpdateDialog(ctx, info);
    } else if (manual) {
      final label = await versionLabel();
      if (ctx.mounted) {
        Helpers.showSnackBar(ctx, 'You are up to date (v$label).');
      }
    }
  }

  Future<void> updateNow(AppUpdateInfo info, {BuildContext? context}) async {
    if (_updating) return;
    _updating = true;
    _progress = 0;
    _error = null;
    notifyListeners();

    final ctx = context ?? Navigation.navigatorKey.currentContext;
    try {
      final apk = await _service.download(
        info.downloadUrl,
        onProgress: (received, total) {
          _progress = total > 0 ? received / total : 0;
          notifyListeners();
        },
      );
      _progress = 1;
      notifyListeners();
      await _service.install(apk);
    } catch (e) {
      _error = e is HttpException ? e.message : e.toString();
      if (ctx != null && ctx.mounted) {
        Helpers.showSnackBar(ctx, 'Update failed: ${_error!.replaceAll('Exception: ', '')}', isError: true);
      }
    } finally {
      _updating = false;
      notifyListeners();
    }
  }

  Future<void> _showUpdateDialog(BuildContext ctx, AppUpdateInfo info) async {
    return showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        title: Text('Update available (${info.versionLabel})'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A new version is ready. Would you like to download and install it now?',
                style: const TextStyle(color: Colors.black54),
              ),
              if ((info.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  info.notes!,
                  maxLines: 12,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                info.sizeBytes > 0
                    ? 'Size: ${(info.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                    : 'Size: unknown',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dctx).pop();
              _downloadAndInstall(ctx, info);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstall(BuildContext ctx, AppUpdateInfo info) async {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (pctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: AnimatedBuilder(
            animation: this,
            builder: (context, _) => Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    value: _progress > 0 ? _progress : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _updating
                        ? 'Downloading update… ${(_progress * 100).toStringAsFixed(0)}%'
                        : 'Starting install…',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await updateNow(info, context: ctx);
    if (!ctx.mounted) return;
    if (_error == null) {
      Helpers.showSnackBar(ctx, 'Update downloaded. Approve installation on your device.');
    }
    Navigator.of(ctx, rootNavigator: true).pop();
  }
}

final updateControllerProvider = ChangeNotifierProvider<UpdateController>((ref) {
  return UpdateController();
});