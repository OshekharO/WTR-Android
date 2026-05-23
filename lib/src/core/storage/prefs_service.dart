import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] so the rest of the app never
/// imports shared_preferences directly.
class PrefsService {
  PrefsService._(this._prefs);

  final SharedPreferences _prefs;

  static PrefsService? _instance;

  static Future<PrefsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = PrefsService._(prefs);
    return _instance!;
  }

  static PrefsService get instance {
    assert(_instance != null,
        'PrefsService.init() must be called before accessing instance');
    return _instance!;
  }

  // ── Active source ─────────────────────────────────────────────────────────

  static const _keyActiveSource = 'active_source_id';

  String? get activeSourceId => _prefs.getString(_keyActiveSource);

  Future<void> setActiveSourceId(String id) =>
      _prefs.setString(_keyActiveSource, id);

  // ── Theme ─────────────────────────────────────────────────────────────────

  static const _keyTheme = 'theme_mode';

  String get themeMode => _prefs.getString(_keyTheme) ?? 'system';

  Future<void> setThemeMode(String mode) => _prefs.setString(_keyTheme, mode);

  // ── DNS ───────────────────────────────────────────────────────────────────

  static const _keyDns = 'custom_dns';
  static const _keyDnsPreset = 'dns_preset_id';

  /// Stores a custom DoH URL when [dnsPresetId] == 'custom'.
  String? get customDns => _prefs.getString(_keyDns);

  Future<void> setCustomDns(String? dns) async {
    if (dns == null || dns.trim().isEmpty) {
      await _prefs.remove(_keyDns);
    } else {
      await _prefs.setString(_keyDns, dns.trim());
    }
  }

  String get dnsPresetId => _prefs.getString(_keyDnsPreset) ?? 'system';

  Future<void> setDnsPresetId(String id) => _prefs.setString(_keyDnsPreset, id);
}
