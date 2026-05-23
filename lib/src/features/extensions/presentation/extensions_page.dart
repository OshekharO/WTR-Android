import 'package:flutter/material.dart';

import '../../../extensions/models/content_source.dart';
import '../../../extensions/registry/source_registry.dart';

class ExtensionsPage extends StatefulWidget {
  const ExtensionsPage({super.key});

  @override
  State<ExtensionsPage> createState() => _ExtensionsPageState();
}

class _ExtensionsPageState extends State<ExtensionsPage> {
  final _registry = SourceRegistry.instance;

  @override
  void initState() {
    super.initState();
    _registry.addListener(_onRegistryChanged);
  }

  @override
  void dispose() {
    _registry.removeListener(_onRegistryChanged);
    super.dispose();
  }

  void _onRegistryChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final sources = _registry.all;
    final active = _registry.active;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Active Source',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        _SourceCard(
          source: active,
          isActive: true,
          onTap: null,
        ),
        const SizedBox(height: 24),
        Text(
          'All Sources',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        ...sources.map(
          (source) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SourceCard(
              source: source,
              isActive: source.id == active.id,
              onTap: source.id == active.id
                  ? null
                  : () async {
                      await _registry.setActive(source);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${source.name}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
            ),
          ),
        ),
        const SizedBox(height: 24),
        _ComingSoonCard(),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.isActive,
    required this.onTap,
  });

  final ContentSource source;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: isActive
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _SourceIcon(type: source.type, isActive: isActive),
        title: Text(
          source.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isActive ? colorScheme.onPrimaryContainer : null,
              ),
        ),
        subtitle: Text(
          source.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.75)
                    : colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: isActive
            ? Icon(Icons.check_circle_rounded,
                color: colorScheme.primary, size: 22)
            : onTap != null
                ? Icon(Icons.radio_button_unchecked_rounded,
                    color: colorScheme.outlineVariant, size: 22)
                : null,
        onTap: onTap,
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.type, required this.isActive});

  final SourceType type;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (type) {
      SourceType.novel => Icons.auto_stories_rounded,
      SourceType.manga => Icons.image_rounded,
      SourceType.anime => Icons.play_circle_rounded,
      SourceType.other => Icons.extension_rounded,
    };
    return CircleAvatar(
      backgroundColor: isActive
          ? colorScheme.primary.withValues(alpha: 0.15)
          : colorScheme.surfaceContainerHighest,
      child: Icon(
        icon,
        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        size: 22,
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.extension_rounded,
                color: colorScheme.onSurfaceVariant, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'More sources coming soon',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Custom extension support will allow adding any source without rebuilding the app.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
