import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_update_model.dart';

class AppUpdateService {
  static const String repo = String.fromEnvironment('GITHUB_REPO');

  static const String _apiBase = 'https://api.github.com/repos';

  bool get enabled => repo.isNotEmpty;

  String get currentVersionLabel {
    final v = _cachedVersion;
    if (v == null) return '';
    return '${v['version']} (${v['buildNumber']})';
  }

  PackageInfo? _cachedPackageInfo;

  Future<PackageInfo> _packageInfo() async {
    return _cachedPackageInfo ??= await PackageInfo.fromPlatform();
  }

  Future<Map<String, String>> _versionParts() async {
    final info = await _packageInfo();
    return {'version': info.version, 'buildNumber': info.buildNumber};
  }

  Future<String?> _currentVersion() async {
    final parts = await _versionParts();
    _cachedVersion = parts;
    return parts['version'];
  }

  Map<String, String>? _cachedVersion;

  Future<String> versionLabel() async {
    final info = await _packageInfo();
    return '${info.version} (${info.buildNumber})';
  }

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!enabled) return null;
    try {
      final uri = Uri.parse('$_apiBase/$repo/releases/latest');
      final res = await http.get(
        uri,
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'REMS',
        },
      );
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final info = AppUpdateInfo.fromJson(json);
      final current = await _currentVersion();
      if (current == null) return null;
      final parts = await _packageInfo();
      return info.isNewerThan(current, parts.buildNumber) ? info : null;
    } catch (_) {
      return null;
    }
  }

  Future<File> download(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/rems_update.apk');
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw HttpException('Download failed (${response.statusCode})');
      }
      final total = response.contentLength ?? 0;
      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          received += chunk.length;
          sink.add(chunk);
          if (total > 0 && onProgress != null) {
            onProgress(received, total);
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      return file;
    } finally {
      client.close();
    }
  }

  Future<void> install(File apk) async {
    final result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw Exception(result.message.isNotEmpty ? result.message : 'Unable to launch installer');
    }
  }
}