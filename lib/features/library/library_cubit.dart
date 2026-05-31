import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/document_repository.dart';
import '../../data/models.dart';

/// Immutable state for the document library.
class LibraryState extends Equatable {
  const LibraryState({
    this.documents = const [],
    this.loading = false,
    this.importing = false,
    this.error,
  });

  final List<DocumentItem> documents;
  final bool loading;
  final bool importing;
  final String? error;

  LibraryState copyWith({
    List<DocumentItem>? documents,
    bool? loading,
    bool? importing,
    String? error,
  }) {
    return LibraryState(
      documents: documents ?? this.documents,
      loading: loading ?? this.loading,
      importing: importing ?? this.importing,
      error: error,
    );
  }

  @override
  List<Object?> get props => [documents, loading, importing, error];
}

/// Manages the list of imported documents. Plain language: this is the
/// "bookshelf" — it loads what you've already added, imports new files
/// (PDF / txt / md), and removes ones you no longer want.
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repo) : super(const LibraryState());

  final DocumentRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final docs = await _repo.getDocuments();
    emit(state.copyWith(documents: docs, loading: false));
  }

  Future<void> importDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    emit(state.copyWith(importing: true));
    try {
      await _repo.importFile(path);
      final docs = await _repo.getDocuments();
      emit(state.copyWith(documents: docs, importing: false));
    } catch (e) {
      emit(state.copyWith(importing: false, error: e.toString()));
    }
  }

  Future<void> delete(DocumentItem doc) async {
    await _repo.deleteDocument(doc.id);
    await load();
  }
}
