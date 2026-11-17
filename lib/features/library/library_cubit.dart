import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../data/document_repository.dart';
import '../../data/models.dart';

/// Which slice of the library is shown (the tabs under the header).
enum DocumentFilter { all, recent, starred }

enum DocumentSort { newest, name, size }

/// Immutable state for the document library.
class LibraryState extends Equatable {
  const LibraryState({
    this.documents = const [],
    this.loading = false,
    this.importing = false,
    this.error,
    this.filter = DocumentFilter.all,
    this.sort = DocumentSort.newest,
    this.query = '',
  });

  final List<DocumentItem> documents;
  final bool loading;
  final bool importing;
  final String? error;
  final DocumentFilter filter;
  final DocumentSort sort;
  final String query;

  /// Documents for the current tab, search query and sort order.
  List<DocumentItem> get visibleDocuments {
    final q = query.trim().toLowerCase();
    var docs = documents.where((d) {
      final matchesTab = switch (filter) {
        DocumentFilter.all => true,
        DocumentFilter.recent => d.lastOpenedAt != null,
        DocumentFilter.starred => d.starred,
      };
      return matchesTab && (q.isEmpty || d.title.toLowerCase().contains(q));
    }).toList();

    if (filter == DocumentFilter.recent) {
      docs.sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
      return docs;
    }
    docs = switch (sort) {
      DocumentSort.newest => docs
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      DocumentSort.name => docs
        ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase())),
      DocumentSort.size => docs
        ..sort((a, b) => (b.fileSize ?? -1).compareTo(a.fileSize ?? -1)),
    };
    return docs;
  }

  DocumentItem? byId(int id) {
    for (final d in documents) {
      if (d.id == id) return d;
    }
    return null;
  }

  int get totalChunks => documents.fold(0, (sum, d) => sum + d.chunkCount);

  LibraryState copyWith({
    List<DocumentItem>? documents,
    bool? loading,
    bool? importing,
    String? error,
    DocumentFilter? filter,
    DocumentSort? sort,
    String? query,
  }) {
    return LibraryState(
      documents: documents ?? this.documents,
      loading: loading ?? this.loading,
      importing: importing ?? this.importing,
      error: error,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props =>
      [documents, loading, importing, error, filter, sort, query];
}

/// Manages the list of imported documents. Plain language: this is the
/// "bookshelf" — it loads what you've already added, imports new files
/// (PDF / txt / md), and removes ones you no longer want. It also remembers
/// which documents you starred and which you opened recently.
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repo) : super(const LibraryState());

  final DocumentRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final docs = await _repo.all();
    emit(state.copyWith(documents: docs, loading: false));
  }

  /// Returns the imported document's title on success, null otherwise.
  Future<String?> importDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;

    emit(state.copyWith(importing: true));
    try {
      final doc = await _repo.importFile(path, p.basename(path));
      final docs = await _repo.all();
      emit(state.copyWith(documents: docs, importing: false));
      return doc.title;
    } catch (e) {
      emit(state.copyWith(importing: false, error: 'Import failed: $e'));
      return null;
    }
  }

  Future<void> delete(DocumentItem doc) async {
    await _repo.delete(doc.id!);
    await load();
  }

  Future<void> deleteAll() async {
    await _repo.deleteAll();
    await load();
  }

  Future<void> toggleStar(int id) async {
    final doc = state.byId(id);
    if (doc == null) return;
    final starred = !doc.starred;
    _replace(doc.copyWith(starred: starred));
    await _repo.setStarred(id, starred);
  }

  Future<void> markOpened(int id) async {
    final doc = state.byId(id);
    if (doc == null) return;
    final now = DateTime.now();
    _replace(doc.copyWith(lastOpenedAt: now));
    await _repo.markOpened(id, now);
  }

  void setFilter(DocumentFilter filter) => emit(state.copyWith(filter: filter));

  void setSort(DocumentSort sort) => emit(state.copyWith(sort: sort));

  void setQuery(String query) => emit(state.copyWith(query: query));

  void _replace(DocumentItem updated) {
    emit(state.copyWith(
      documents: [
        for (final d in state.documents) d.id == updated.id ? updated : d,
      ],
    ));
  }
}
