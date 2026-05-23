import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dns_client/dns_client.dart';
import 'package:logger/logger.dart';

import '../storage/prefs_service.dart';

/// Well-known DNS presets shown in Settings.
enum DnsPreset {
  systemDefault('system', 'System Default'),
  cloudflare('cloudflare', 'Cloudflare DoH (1.1.1.1)'),
  google('google', 'Google DoH (8.8.8.8)'),
  adGuard('adguard', 'AdGuard DoH'),
  custom('custom', 'Custom DoH URL');

  const DnsPreset(this.id, this.label);

  final String id;
  final String label;

  static DnsPreset fromId(String? id) => DnsPreset.values.firstWhere(
        (p) => p.id == id,
        orElse: () => DnsPreset.systemDefault,
      );
}

/// Manages a [DnsClient] instance based on the user's DNS preference.
///
/// On Flutter Web, DNS resolution is always handled by the browser — this
/// service returns a null client and is effectively a no-op on that platform.
///
/// Call [DnsService.init] once at startup, then use [DnsService.instance].
class DnsService {
  DnsService._(this._client, this._log);

  final DnsClient? _client;
  final Logger _log;

  static DnsService? _instance;

  static DnsService get instance {
    assert(_instance != null, 'DnsService.init() must be called first');
    return _instance!;
  }

  /// Initialises the service from saved preferences.
  static Future<DnsService> init({Logger? logger}) async {
    final log = logger ?? Logger();
    // DNS resolution via dart:io is not available on Flutter Web.
    final client = kIsWeb
        ? null
        : _buildClient(
            PrefsService.instance.dnsPresetId,
            PrefsService.instance.customDns,
            log,
          );
    _instance = DnsService._(client, log);
    return _instance!;
  }

  /// Rebuilds the client after the user changes DNS settings in Settings.
  static Future<void> reload() async {
    final log = _instance?._log ?? Logger();
    final client = kIsWeb
        ? null
        : _buildClient(
            PrefsService.instance.dnsPresetId,
            PrefsService.instance.customDns,
            log,
          );
    _instance = DnsService._(client, log);
  }

  /// The active [DnsClient], or null when using system DNS / on web.
  DnsClient? get client => _client;

  /// Resolves [host] to an IP string using the active DoH client.
  /// Always returns null on Flutter Web.
  Future<String?> resolve(String host) async {
    if (_client == null) return null;
    try {
      final addresses = await _client.lookup(host);
      return addresses.firstOrNull?.address;
    } catch (e) {
      _log.w('DnsService.resolve failed for $host', error: e);
      return null;
    }
  }

  static DnsClient? _buildClient(
      String? presetId, String? customUrl, Logger log) {
    final preset = DnsPreset.fromId(presetId);
    switch (preset) {
      case DnsPreset.cloudflare:
        return DnsOverHttps.cloudflare();
      case DnsPreset.google:
        return DnsOverHttps.google();
      case DnsPreset.adGuard:
        return DnsOverHttps.adguard();
      case DnsPreset.custom:
        final url = customUrl?.trim();
        if (url == null || url.isEmpty) return null;
        try {
          return DnsOverHttps(url);
        } catch (e) {
          log.e('DnsService: invalid custom URL "$url"', error: e);
          return null;
        }
      case DnsPreset.systemDefault:
        return null;
    }
  }
}
