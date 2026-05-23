import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import '../../../core/network/dns_service.dart';
import '../../../core/storage/prefs_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _prefs = PrefsService.instance;
  final _customDnsController = TextEditingController();

  late DnsPreset _selectedPreset;

  @override
  void initState() {
    super.initState();
    _selectedPreset = DnsPreset.fromId(_prefs.dnsPresetId);
    _customDnsController.text = _prefs.customDns ?? '';
  }

  @override
  void dispose() {
    _customDnsController.dispose();
    super.dispose();
  }

  Future<void> _applyDns() async {
    await _prefs.setDnsPresetId(_selectedPreset.id);
    if (_selectedPreset == DnsPreset.custom) {
      await _prefs.setCustomDns(_customDnsController.text);
    }
    await DnsService.reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('DNS updated to ${_selectedPreset.label}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentMode = AdaptiveTheme.of(context).mode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Appearance ──────────────────────────────────────────────────────
        _SectionHeader(title: 'Appearance'),
        _SettingsCard(
          children: [
            _ThemeTile(
              label: 'Light',
              icon: Icons.light_mode_rounded,
              selected: currentMode == AdaptiveThemeMode.light,
              onTap: () => AdaptiveTheme.of(context).setLight(),
            ),
            const _Divider(),
            _ThemeTile(
              label: 'Dark',
              icon: Icons.dark_mode_rounded,
              selected: currentMode == AdaptiveThemeMode.dark,
              onTap: () => AdaptiveTheme.of(context).setDark(),
            ),
            const _Divider(),
            _ThemeTile(
              label: 'System default',
              icon: Icons.brightness_auto_rounded,
              selected: currentMode == AdaptiveThemeMode.system,
              onTap: () => AdaptiveTheme.of(context).setSystem(),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Network / DNS ────────────────────────────────────────────────────
        _SectionHeader(title: 'Network'),
        _SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.dns_rounded, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'DNS Resolver',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Choose a DNS server to resolve hostnames. Useful for bypassing regional blocks. Only applies on Android/iOS — browsers manage DNS on web.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            // Preset tiles
            ...DnsPreset.values.map((preset) {
              final isSelected = _selectedPreset == preset;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Divider(),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      preset.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                    ),
                    onTap: () => setState(() => _selectedPreset = preset),
                  ),
                  // Custom DoH URL input — only shown when Custom is selected
                  if (preset == DnsPreset.custom && isSelected)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _customDnsController,
                        decoration: InputDecoration(
                          hintText: 'e.g. https://my-doh.example.com/dns-query',
                          labelText: 'Custom DoH URL',
                          prefixIcon: const Icon(Icons.edit_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.url,
                      ),
                    ),
                ],
              );
            }),
            // Apply button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Apply DNS Settings'),
                  onPressed: _applyDns,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── About ────────────────────────────────────────────────────────────
        _SectionHeader(title: 'About'),
        _SettingsCard(
          children: [
            const ListTile(
              leading: Icon(Icons.auto_stories_rounded),
              title: Text('OtakuStream'),
              subtitle: Text('v1.0.0 — Multi-source content reader'),
            ),
            const _Divider(),
            const ListTile(
              leading: Icon(Icons.person_rounded),
              title: Text('Developer'),
              subtitle: Text('Saksham Shekher / OshekharO'),
            ),
            const _Divider(),
            const ListTile(
              leading: Icon(Icons.code_rounded),
              title: Text('Source'),
              subtitle: Text('github.com/OshekharO/OtakuStream'),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 16);
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_rounded, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
