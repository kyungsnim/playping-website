import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_stats.dart';
import '../../data/repositories/user_repository.dart';

/// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Provider for overall user statistics
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUserStats();
});

/// Provider for country statistics
final countryStatsProvider = FutureProvider<List<CountryStats>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCountryStats();
});

/// Provider for region statistics with optional country filter
final regionStatsProvider =
    FutureProvider.family<List<RegionStats>, String?>((ref, countryCode) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getRegionStats(countryCode: countryCode);
});

/// Provider for auth provider statistics
final providerStatsProvider =
    FutureProvider<List<ProviderStats>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getProviderStats();
});

/// Provider for daily signup data
final dailySignupsProvider =
    FutureProvider.family<List<DailySignupData>, int>((ref, days) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getDailySignups(days: days);
});

/// Provider for retention data
final retentionDataProvider =
    FutureProvider.family<List<RetentionData>, int>((ref, cohortCount) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getRetentionData(cohortCount: cohortCount);
});

/// Selected country for region filter
final selectedCountryProvider = StateProvider<String?>((ref) => null);
