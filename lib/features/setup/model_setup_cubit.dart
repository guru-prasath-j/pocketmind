import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/llm/model_manager.dart';

enum SetupStatus { idle, downloading, ready, error }

/// Immutable state for the first-run model download.
class ModelSetupState extends Equatable {
  const ModelSetupState({
    this.status = SetupStatus.idle,
    this.progress = 0,
    this.error,
  });

  final SetupStatus status;
  final double progress;
  final String? error;

  ModelSetupState copyWith({
    SetupStatus? status,
    double? progress,
    String? error,
  }) {
    return ModelSetupState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, progress, error];
}

/// Drives the one-time model download. Plain language: this is the "first run"
/// helper that fetches the AI brain onto the phone so everything afterward
/// works fully offline.
class ModelSetupCubit extends Cubit<ModelSetupState> {
  ModelSetupCubit(this._modelManager) : super(const ModelSetupState());

  final ModelManager _modelManager;

  Future<void> checkInstalled() async {
    if (await _modelManager.isModelInstalled()) {
      emit(state.copyWith(status: SetupStatus.ready));
    }
  }

  Future<void> download() async {
    emit(state.copyWith(status: SetupStatus.downloading, progress: 0));
    try {
      await for (final pct in _modelManager.downloadModel()) {
        emit(state.copyWith(progress: pct.toDouble()));
      }
      emit(state.copyWith(status: SetupStatus.ready));
    } catch (e) {
      emit(state.copyWith(status: SetupStatus.error, error: e.toString()));
    }
  }
}
