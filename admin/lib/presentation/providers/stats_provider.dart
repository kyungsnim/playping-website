import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_stats.dart';
import '../../data/repositories/user_repository.dart';
import 'region_provider.dart';

/// Provider for UserRepository (uses selected region's Firestore)
final userRepositoryProvider = Provider.autoDispose<UserRepository>((ref) {
  final firestore = ref.watch(regionFirestoreProvider);
  debugPrint('📊 userRepositoryProvider 재생성: firestore.databaseId=${firestore.databaseId}');
  return UserRepository(firestore: firestore);
});

/// Provider for overall user statistics
final userStatsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  debugPrint('📈 userStatsProvider 호출');
  return repository.getUserStats();
});

/// Provider for country statistics
final countryStatsProvider = FutureProvider.autoDispose<List<CountryStats>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCountryStats();
});

/// Provider for region statistics with optional country filter
final regionStatsProvider =
    FutureProvider.autoDispose.family<List<RegionStats>, String?>((ref, countryCode) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getRegionStats(countryCode: countryCode);
});

/// Provider for auth provider statistics
final providerStatsProvider =
    FutureProvider.autoDispose<List<ProviderStats>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getProviderStats();
});

/// Provider for daily signup data
final dailySignupsProvider =
    FutureProvider.autoDispose.family<List<DailySignupData>, int>((ref, days) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getDailySignups(days: days);
});

/// Provider for retention data
final retentionDataProvider =
    FutureProvider.autoDispose.family<List<RetentionData>, int>((ref, cohortCount) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getRetentionData(cohortCount: cohortCount);
});

/// Selected country for region filter
final selectedCountryProvider = StateProvider<String?>((ref) => null);
