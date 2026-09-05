class AppUpdateInfo {
  final String tagName;
  final int major;
  final int minor;
  final int patch;
  final String downloadUrl;
  final int sizeBytes;
  final String? notes;

  const AppUpdateInfo({
    required this.tagName,
    required this.major,
    required this.minor,
    required this.patch,
    required this.downloadUrl,
    required this.sizeBytes,
    this.notes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String?)?.trim() ?? '';
    final parts = tag
        .replaceFirst(RegExp(r'^v'), '')
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
    final assets = (json['assets'] as List?) ?? const [];
    Map<String, dynamic>? apkAsset;
    for (final asset in assets) {
      final a = asset as Map<String, dynamic>;
      final name = (a['name'] as String?) ?? '';
      if (name.toLowerCase().endsWith('.apk')) {
        apkAsset = a;
        break;
      }
    }
    if (apkAsset == null) {
      throw const FormatException('No APK asset found in release');
    }
    return AppUpdateInfo(
      tagName: tag,
      major: parts.isNotEmpty ? parts[0] : 0,
      minor: parts.length > 1 ? parts[1] : 0,
      patch: parts.length > 2 ? parts[2] : 0,
      downloadUrl: apkAsset['browser_download_url'] as String? ?? '',
      sizeBytes: (apkAsset['size'] as num?)?.toInt() ?? 0,
      notes: (json['body'] as String?)?.trim(),
    );
  }

  bool isNewerThan(String version, String buildNumber) {
    final vParts = version.split('.');
    final v = <int>[
      int.tryParse(vParts.isNotEmpty ? vParts[0] : '0') ?? 0,
      int.tryParse(vParts.length > 1 ? vParts[1] : '0') ?? 0,
      int.tryParse(vParts.length > 2 ? vParts[2] : buildNumber) ?? 0,
    ];
    if (major > v[0]) return true;
    if (major < v[0]) return false;
    if (minor > v[1]) return true;
    if (minor < v[1]) return false;
    return patch > v[2];
  }

  String get versionLabel => tagName.isEmpty ? '${major}.${minor}.$patch' : tagName;
}