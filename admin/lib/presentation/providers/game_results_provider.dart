import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_result_model.dart';
import '../../data/repositories/game_result_repository.dart';

/// Provider for game result repository
final gameResultRepositoryProvider = Provider<GameResultRepository>((ref) {
  return GameResultRepository();
});

/// State for paginated game results
class GameResultsState {
  final List<GameResultModel> results;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot? lastDocument;

  const GameResultsState({
    this.results = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.lastDocument,
  });

  GameResultsState copyWith({
    List<GameResultModel>? results,
    bool? isLoading,
    bool? hasMore,
    String? error,
    DocumentSnapshot? lastDocument,
  }) {
    return GameResultsState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

/// Notifier for game results with pagination
class GameResultsNotifier extends StateNotifier<GameResultsState> {
  final GameResultRepository _repository;
  static const int _pageSize = 10;

  GameResultsNotifier(this._repository) : super(const GameResultsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _repository.getFinishedGames(limit: _pageSize);

      state = state.copyWith(
        results: results,
        isLoading: false,
        hasMore: results.length >= _pageSize,
        lastDocument: results.isNotEmpty ? results.last.documentSnapshot : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final results = await _repository.getFinishedGames(
        limit: _pageSize,
        startAfter: state.lastDocument,
      );

      state = state.copyWith(
        results: [...state.results, ...results],
        isLoading: false,
        hasMore: results.length >= _pageSize,
        lastDocument: results.isNotEmpty ? results.last.documentSnapshot : state.lastDocument,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = const GameResultsState();
    await loadInitial();
  }
}

/// Provider for paginated game results
final gameResultsProvider =
    StateNotifierProvider<GameResultsNotifier, GameResultsState>((ref) {
  final repository = ref.watch(gameResultRepositoryProvider);
  return GameResultsNotifier(repository);
});

/// Provider for game result detail
final gameResultDetailProvider =
    FutureProvider.family<GameResultDetail, String>((ref, roomId) async {
  final repository = ref.watch(gameResultRepositoryProvider);
  return repository.getGameResultDetail(roomId);
});

/// Provider for multi-game scores
final multiGameScoresProvider =
    FutureProvider.family<List<MultiGameScore>, String>((ref, roomId) async {
  final repository = ref.watch(gameResultRepositoryProvider);
  return repository.getMultiGameScores(roomId);
});

/// Provider for team game scores
final teamGameScoresProvider =
    FutureProvider.family<List<TeamGameScore>, String>((ref, roomId) async {
  final repository = ref.watch(gameResultRepositoryProvider);
  return repository.getTeamGameScores(roomId);
});
