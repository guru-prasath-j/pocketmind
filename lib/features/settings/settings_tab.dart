import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/widgets/brand.dart';
import '../chat/chat_sessions.dart';
import '../library/library_cubit.dart';

/// The "Settings" tab: model + storage info and data management.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.isModelInstalled});

  /// e.g. `ModelManager.isModelInstalled` — injected to keep the tab testable.
  final Future<bool> Function() isModelInstalled;

  Future<void> _deleteAll(BuildContext context) async {
    final library = context.read<LibraryCubit>();
    final sessions = context.read<ChatSessions>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
        title: const Text('Delete all documents?'),
        content: const Text(
          'Every document, its chunks and its conversation will be removed '
          'from this device. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    sessions.closeAll();
    await library.deleteAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All documents deleted')),
      );
    }
  }

  void _clearChats(BuildContext context) {
    context.read<ChatSessions>().clearAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversations cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryCubit>().state;
    final sessions = context.read<ChatSessions>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 22, AppSpacing.gutter, 32),
      children: [
        Text('Settings',
            style:
                Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 28)),
        const SizedBox(height: 20),
        const _PrivacyCard(),
        const _Section('Appearance'),
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) => _ThemeSelector(
            mode: mode,
            onChanged: context.read<ThemeCubit>().setMode,
          ),
        ),
        const _Section('On-device AI'),
        _Card(children: [
          const _InfoRow(Icons.memory_rounded, 'Model', AppConstants.modelFileName),
          _ModelStatusRow(check: isModelInstalled),
          const _InfoRow(Icons.tune_rounded, 'Retrieval',
              'Top ${AppConstants.topK} of ${AppConstants.chunkSize}-char chunks'),
        ]),
        const _Section('Library'),
        _Card(children: [
          _InfoRow(Icons.folder_open_rounded, 'Documents',
              '${library.documents.length}'),
          _InfoRow(Icons.view_agenda_outlined, 'Chunks', '${library.totalChunks}'),
          _InfoRow(Icons.star_outline_rounded, 'Starred',
              '${library.documents.where((d) => d.starred).length}'),
        ]),
        const _Section('Data'),
        ListenableBuilder(
          listenable: sessions.changes,
          builder: (context, _) => _Card(children: [
            _ActionRow(
              icon: Icons.forum_outlined,
              label: 'Clear all conversations',
              onTap: sessions.documentIdsWithMessages.isEmpty
                  ? null
                  : () => _clearChats(context),
            ),
            _ActionRow(
              icon: Icons.delete_sweep_outlined,
              label: 'Delete all documents',
              destructive: true,
              onTap: library.documents.isEmpty ? null : () => _deleteAll(context),
            ),
          ]),
        ),
        const _Section('About'),
        _Card(children: [
          const _InfoRow(Icons.info_outline_rounded, 'Version', AppConstants.version),
          _ActionRow(
            icon: Icons.description_outlined,
            label: 'Open-source licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: AppConstants.version,
              applicationIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: AppLogo(size: 56),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

/// Runs the model check once (not on every rebuild of the tab).
class _ModelStatusRow extends StatefulWidget {
  const _ModelStatusRow({required this.check});

  final Future<bool> Function() check;

  @override
  State<_ModelStatusRow> createState() => _ModelStatusRowState();
}

class _ModelStatusRowState extends State<_ModelStatusRow> {
  late final Future<bool> _installed = widget.check();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _installed,
      builder: (context, snap) => _InfoRow(
        Icons.verified_outlined,
        'Status',
        switch (snap.data) {
          null => 'Checking…',
          true => 'Installed',
          false => 'Not installed',
        },
        valueColor: snap.data == true ? AppColors.success : null,
      ),
    );
  }
}

/// Three-way System / Light / Dark switch with a sliding highlight.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = [
    (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
    (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
    (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selected = _options.indexWhere((o) => o.$1 == mode);
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: c.border),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth / _options.length;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: w * selected,
              top: 0,
              bottom: 0,
              width: w,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.lavenderGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: 0.35 * c.glowStrength),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (final (value, icon, label) in _options)
                  Expanded(
                    child: Semantics(
                      selected: value == mode,
                      button: true,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                        onTap: () => onChanged(value),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon,
                                    size: 18,
                                    color: value == mode
                                        ? AppColors.onLavender
                                        : c.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: value == mode
                                        ? AppColors.onLavender
                                        : c.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.28),
            AppColors.primaryDeep.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const AppLogo(size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('100% on-device',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  'Your documents and questions never leave this phone.',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: context.colors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 52),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value, {this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.accent),
          const SizedBox(width: 16),
          Text(label),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : context.colors.textPrimary;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: destructive ? AppColors.danger : context.colors.accent),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: TextStyle(color: color))),
              Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
