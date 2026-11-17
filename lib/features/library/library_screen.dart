import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/buttons.dart';
import '../../data/models.dart';
import 'document_actions.dart';
import 'library_cubit.dart';
import 'widgets/document_card.dart';

/// The "Documents" tab: header, category tabs and the document list.
/// Expects [LibraryCubit] and ChatSessions above it (see HomeShell).
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

enum _LibraryMenu { sortNewest, sortName, sortSize, refresh }

class _LibraryTabState extends State<LibraryTab> {
  bool _searching = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searching = true);
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    _searchController.clear();
    context.read<LibraryCubit>().setQuery('');
    _searchFocus.unfocus();
    setState(() => _searching = false);
  }

  void _onMenu(_LibraryMenu action) {
    final cubit = context.read<LibraryCubit>();
    switch (action) {
      case _LibraryMenu.sortNewest:
        cubit.setSort(DocumentSort.newest);
      case _LibraryMenu.sortName:
        cubit.setSort(DocumentSort.name);
      case _LibraryMenu.sortSize:
        cubit.setSort(DocumentSort.size);
      case _LibraryMenu.refresh:
        cubit.load();
    }
  }

  Future<void> _onCardAction(DocumentCardAction a, DocumentItem doc) async {
    switch (a) {
      case DocumentCardAction.open:
        await DocumentActions.openChat(context, doc);
      case DocumentCardAction.star:
        await context.read<LibraryCubit>().toggleStar(doc.id!);
      case DocumentCardAction.details:
        await DocumentActions.showDetails(context, doc);
      case DocumentCardAction.delete:
        await DocumentActions.confirmDelete(context, doc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LibraryCubit>().state;
    final docs = state.visibleDocuments;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, 16, AppSpacing.gutter, 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _searching
                ? _SearchField(
                    key: const ValueKey('search'),
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: context.read<LibraryCubit>().setQuery,
                    onClose: _closeSearch,
                  )
                : _Header(
                    key: const ValueKey('header'),
                    sort: state.sort,
                    onSearch: _openSearch,
                    onMenu: _onMenu,
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: _FilterTabs(
            selected: state.filter,
            onSelected: context.read<LibraryCubit>().setFilter,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: state.importing
              ? const _ImportingBanner()
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: state.loading && state.documents.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  color: context.colors.accent,
                  backgroundColor: context.colors.surfaceHigh,
                  onRefresh: context.read<LibraryCubit>().load,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: docs.isEmpty
                        ? _EmptyState(
                            key: ValueKey('empty-${state.filter}-${state.query}'),
                            filter: state.filter,
                            searching: state.query.trim().isNotEmpty,
                            hasAnyDocuments: state.documents.isNotEmpty,
                          )
                        : ListView.separated(
                            key: ValueKey('list-${state.filter}'),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.gutter, 4, AppSpacing.gutter, 120),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, i) => _EntryAnimation(
                              key: ValueKey(docs[i].id),
                              index: i,
                              child: DocumentCard(
                                document: docs[i],
                                onTap: () =>
                                    DocumentActions.openChat(context, docs[i]),
                                onAction: (a) => _onCardAction(a, docs[i]),
                              ),
                            ),
                          ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    super.key,
    required this.sort,
    required this.onSearch,
    required this.onMenu,
  });

  final DocumentSort sort;
  final VoidCallback onSearch;
  final ValueChanged<_LibraryMenu> onMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogo(size: 52),
        const SizedBox(width: 16),
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: BrandTitle(fontSize: 28),
          ),
        ),
        const SizedBox(width: 8),
        CircleIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Search documents',
          onPressed: onSearch,
        ),
        const SizedBox(width: 12),
        CircleMenuButton<_LibraryMenu>(
          tooltip: 'More options',
          onSelected: onMenu,
          items: [
            menuItem(_LibraryMenu.sortNewest, Icons.schedule_rounded,
                'Sort by newest',
                checked: sort == DocumentSort.newest),
            menuItem(_LibraryMenu.sortName, Icons.sort_by_alpha_rounded,
                'Sort by name',
                checked: sort == DocumentSort.name),
            menuItem(_LibraryMenu.sortSize, Icons.data_usage_rounded,
                'Sort by size',
                checked: sort == DocumentSort.size),
            const PopupMenuDivider(),
            menuItem(_LibraryMenu.refresh, Icons.refresh_rounded, 'Refresh'),
          ],
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search documents…',
                hintStyle: TextStyle(color: context.colors.textMuted),
                prefixIcon: Icon(Icons.search_rounded,
                    color: context.colors.accent),
                filled: true,
                fillColor: context.colors.surfaceHigh,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  borderSide:
                      BorderSide(color: context.colors.accent, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Close search',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelected});

  final DocumentFilter selected;
  final ValueChanged<DocumentFilter> onSelected;

  static const _tabs = [
    (DocumentFilter.all, Icons.folder_open_rounded, 'My Documents'),
    (DocumentFilter.recent, Icons.schedule_rounded, 'Recent'),
    (DocumentFilter.starred, Icons.star_outline_rounded, 'Starred'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            flex: i == 0 ? 6 : 5,
            child: _TabPill(
              icon: _tabs[i].$2,
              label: _tabs[i].$3,
              selected: selected == _tabs[i].$1,
              onTap: () => onSelected(_tabs[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onLavender : context.colors.textPrimary;
    final radius = BorderRadius.circular(AppSpacing.radiusPill);
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 52,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.lavenderGradient : null,
          color: selected ? null : context.colors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? Colors.transparent : context.colors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: fg),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportingBanner extends StatelessWidget {
  const _ImportingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.gutter, 16, AppSpacing.gutter, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.colors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: context.colors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Processing document — extracting text and building chunks…',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(minHeight: 4),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    super.key,
    required this.filter,
    required this.searching,
    required this.hasAnyDocuments,
  });

  final DocumentFilter filter;
  final bool searching;
  final bool hasAnyDocuments;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = searching
        ? (
            Icons.search_off_rounded,
            'No matches',
            'No documents match your search.',
          )
        : switch (filter) {
            DocumentFilter.all => (
                Icons.library_books_outlined,
                'No documents yet',
                'Add a PDF, text, or markdown file, then ask questions about '
                    'it — all answered on-device.',
              ),
            DocumentFilter.recent => (
                Icons.schedule_rounded,
                'Nothing recent',
                hasAnyDocuments
                    ? 'Documents you open will show up here.'
                    : 'Add a document to get started.',
              ),
            DocumentFilter.starred => (
                Icons.star_outline_rounded,
                'No starred documents',
                'Star a document from its ⋮ menu or the bookmark in chat.',
              ),
          };

    // Scrollable so pull-to-refresh works and nothing overflows with the
    // keyboard open.
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 24, 40, 120),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.surfaceHigh,
                    border: Border.all(color: context.colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 40, color: context.colors.accent),
                ),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and slides a list item in, staggered by [index].
class _EntryAnimation extends StatelessWidget {
  const _EntryAnimation({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index.clamp(0, 8) * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
