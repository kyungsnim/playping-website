import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_stats.dart';
import '../../data/repositories/game_repository.dart';

/// Provider for GameRepository
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

/// Provider for overall game statistics
final gameStatsProvider = FutureProvider<GameStats>((ref) async {
  final repository = ref.watch(gameRepositoryProvider);
  return repository.getGameStats();
});

/// Provider for game type statistics
final gameTypeStatsProvider = FutureProvider<List<GameTypeStats>>((ref) async {
  final repository = ref.watch(gameRepositoryProvider);
  return repository.getGameTypeStats();
});

/// Provider for daily game data
final dailyGamesProvider =
    FutureProvider.family<List<DailyGameData>, int>((ref, days) async {
  final repository = ref.watch(gameRepositoryProvider);
  return repository.getDailyGames(days: days);
});

/// Provider for hourly game distribution
final hourlyGamesProvider = FutureProvider<List<HourlyGameData>>((ref) async {
  final repository = ref.watch(gameRepositoryProvider);
  return repository.getHourlyGames();
});
