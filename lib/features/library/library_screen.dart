import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants.dart';
import '../../core/service_locator.dart';
import '../chat/chat_screen.dart';
import 'library_cubit.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          LibraryCubit(ServiceLocator.instance.documentRepository)..load(),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final cubit = context.read<LibraryCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text(AppConstants.appName)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.importing ? null : cubit.importDocument,
            icon: state.importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(state.importing ? 'Importing…' : 'Add document'),
          ),
          body: state.loading
              ? const Center(child: CircularProgressIndicator())
              : state.documents.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      itemCount: state.documents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final doc = state.documents[i];
                        return ListTile(
                          leading: const Icon(Icons.description),
                          title: Text(doc.title),
                          subtitle: Text('${doc.chunkCount} chunks'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => cubit.delete(doc),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                  documentId: doc.id!, title: doc.title),
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined, size: 64),
            const SizedBox(height: 16),
            Text('No documents yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Add a PDF, text, or markdown file, then ask questions about '
              'it — all answered on-device.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
