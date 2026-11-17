import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/buttons.dart';
import '../chat/chat_sessions.dart';
import '../conversations/conversations_tab.dart';
import '../library/library_cubit.dart';
import '../library/library_screen.dart';
import '../settings/settings_tab.dart';

/// Main screen after setup: Documents / Chat / Settings with a bottom bar.
/// Owns the [LibraryCubit] and [ChatSessions] shared by every tab and by the
/// chat screens pushed on top.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final ChatSessions _sessions =
      ChatSessions(ServiceLocator.instance.rag);

  @override
  void dispose() {
    _sessions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ChatSessions>.value(
      value: _sessions,
      child: BlocProvider(
        create: (_) =>
            LibraryCubit(ServiceLocator.instance.documentRepository)..load(),
        child: const _HomeView(),
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _index = 0;

  Future<void> _addDocument() async {
    setState(() => _index = 0);
    final title = await context.read<LibraryCubit>().importDocument();
    if (title != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "$title"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final importing = context.select<LibraryCubit, bool>((c) => c.state.importing);

    return PopScope(
      // Back from Chat/Settings returns to Documents before leaving the app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: BlocListener<LibraryCubit, LibraryState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.error!))),
        child: Scaffold(
          backgroundColor: context.colors.background,
          body: AmbientBackground(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _index,
                children: [
                  const LibraryTab(),
                  ConversationsTab(onAddDocument: _addDocument),
                  SettingsTab(
                    isModelInstalled:
                        ServiceLocator.instance.modelManager.isModelInstalled,
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: AnimatedScale(
            scale: _index == 0 ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GradientButton(
                label: importing ? 'Processing…' : 'Add Document',
                icon: Icons.add_rounded,
                loading: importing,
                onPressed: _index == 0 ? _addDocument : null,
              ),
            ),
          ),
          bottomNavigationBar: _BottomNav(
            index: _index,
            onSelected: (i) => setState(() => _index = i),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.folder_rounded, Icons.folder_open_rounded, 'Documents'),
    (Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
    (Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.backgroundDeep,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    selectedIcon: _items[i].$1,
                    icon: _items[i].$2,
                    label: _items[i].$3,
                    selected: i == index,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.accent : context.colors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: 3,
              width: selected ? 56 : 0,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(3)),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? selectedIcon : icon,
                key: ValueKey(selected),
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
