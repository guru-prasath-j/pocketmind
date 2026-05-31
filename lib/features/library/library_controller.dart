import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../data/document_repository.dart';
import '../../data/models.dart';

/// Manages the list of imported documents. Plain language: this is the
/// "bookshelf" — it loads what you've already added, imports new files
/// (PDF / txt / md), and removes ones you no longer want.
class LibraryController extends ChangeNotifier {
  LibraryController(this._repo);

  final DocumentRepository _repo;

  List<DocumentItem> documents = [];
  bool loading = false;
  bool importing = false;
  String? error;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    documents = await _repo.getDocuments();
    loading = false;
    notifyListeners();
  }

  Future<void> importDocument() async {
    error = null;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    importing = true;
    notifyListeners();
    try {
      await _repo.importFile(path);
      await load();
    } catch (e) {
      error = e.toString();
    } finally {
      importing = false;
      notifyListeners();
    }
  }

  Future<void> delete(DocumentItem doc) async {
    await _repo.deleteDocument(doc.id);
    await load();
  }
}
