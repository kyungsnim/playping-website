import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../models/user_stats.dart';

/// Repository for fetching user statistics from Firestore
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(AdminConstants.usersCollection);

  /// Get overall user statistics
  Future<UserStats> getUserStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));
    final monthStart = todayStart.subtract(const Duration(days: 30));

    // Get all users count
    final allUsersSnapshot = await _usersCollection.count().get();
    final totalUsers = allUsersSnapshot.count ?? 0;

    // Get new users counts
    final todayNewUsersSnapshot = await _usersCollection
        .where(AdminConstants.userCreatedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .count()
        .get();

    final weekNewUsersSnapshot = await _usersCollection
        .where(AdminConstants.userCreatedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .count()
        .get();

    final monthNewUsersSnapshot = await _usersCollection
        .where(AdminConstants.userCreatedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .count()
        .get();

    // Get active users counts (based on lastLoginAt)
    final activeTodaySnapshot = await _usersCollection
        .where(AdminConstants.userLastLoginAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .count()
        .get();

    final activeWeekSnapshot = await _usersCollection
        .where(AdminConstants.userLastLoginAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .count()
        .get();

    final activeMonthSnapshot = await _usersCollection
        .where(AdminConstants.userLastLoginAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .count()
        .get();

    return UserStats(
      totalUsers: totalUsers,
      todayNewUsers: todayNewUsersSnapshot.count ?? 0,
      weekNewUsers: weekNewUsersSnapshot.count ?? 0,
      monthNewUsers: monthNewUsersSnapshot.count ?? 0,
      activeToday: activeTodaySnapshot.count ?? 0,
      activeWeek: activeWeekSnapshot.count ?? 0,
      activeMonth: activeMonthSnapshot.count ?? 0,
    );
  }

  /// Get user statistics by country
  Future<List<CountryStats>> getCountryStats() async {
    final snapshot = await _usersCollection.get();
    final countryMap = <String, int>{};
    int totalWithCountry = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final countryCode = data[AdminConstants.userCountryCode] as String?;
      final country = data[AdminConstants.userCountry] as String?;

      if (countryCode != null && countryCode.isNotEmpty) {
        final key = '$countryCode|${country ?? countryCode}';
        countryMap[key] = (countryMap[key] ?? 0) + 1;
        totalWithCountry++;
      }
    }

    // Add unknown count
    final unknownCount = snapshot.docs.length - totalWithCountry;
    if (unknownCount > 0) {
      countryMap['UNKNOWN|Unknown'] = unknownCount;
    }

    final total = snapshot.docs.length;

    final result = countryMap.entries.map((entry) {
      final parts = entry.key.split('|');
      return CountryStats(
        countryCode: parts[0],
        countryName: parts[1],
        userCount: entry.value,
        percentage: total > 0 ? (entry.value / total) * 100 : 0,
      );
    }).toList();

    // Sort by user count descending
    result.sort((a, b) => b.userCount.compareTo(a.userCount));

    return result;
  }

  /// Get user statistics by region (administrativeArea)
  Future<List<RegionStats>> getRegionStats({String? countryCode}) async {
    Query<Map<String, dynamic>> query = _usersCollection;

    if (countryCode != null && countryCode != 'UNKNOWN') {
      query =
          query.where(AdminConstants.userCountryCode, isEqualTo: countryCode);
    }

    final snapshot = await query.get();
    final regionMap = <String, int>{};
    int totalWithRegion = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final region = data[AdminConstants.userAdministrativeArea] as String?;

      if (region != null && region.isNotEmpty) {
        regionMap[region] = (regionMap[region] ?? 0) + 1;
        totalWithRegion++;
      }
    }

    // Add unknown count
    final unknownCount = snapshot.docs.length - totalWithRegion;
    if (unknownCount > 0) {
      regionMap['Unknown'] = unknownCount;
    }

    final total = snapshot.docs.length;

    final result = regionMap.entries
        .map((entry) => RegionStats(
              region: entry.key,
              userCount: entry.value,
              percentage: total > 0 ? (entry.value / total) * 100 : 0,
            ))
        .toList();

    // Sort by user count descending
    result.sort((a, b) => b.userCount.compareTo(a.userCount));

    return result;
  }

  /// Get user statistics by auth provider
  Future<List<ProviderStats>> getProviderStats() async {
    final snapshot = await _usersCollection.get();
    final providerMap = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final provider =
          (data[AdminConstants.userProvider] as String?) ?? 'unknown';
      providerMap[provider] = (providerMap[provider] ?? 0) + 1;
    }

    final total = snapshot.docs.length;

    final result = providerMap.entries
        .map((entry) => ProviderStats(
              provider: _formatProviderName(entry.key),
              userCount: entry.value,
              percentage: total > 0 ? (entry.value / total) * 100 : 0,
            ))
        .toList();

    // Sort by user count descending
    result.sort((a, b) => b.userCount.compareTo(a.userCount));

    return result;
  }

  /// Get daily signup data for the last N days
  Future<List<DailySignupData>> getDailySignups({int days = 30}) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final snapshot = await _usersCollection
        .where(AdminConstants.userCreatedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy(AdminConstants.userCreatedAt)
        .get();

    // Group by date
    final dailyMap = <String, int>{};

    // Initialize all dates with 0
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyMap[key] = 0;
    }

    // Count signups per day
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = data[AdminConstants.userCreatedAt] as Timestamp?;
      if (createdAt != null) {
        final date = createdAt.toDate();
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyMap[key] = (dailyMap[key] ?? 0) + 1;
      }
    }

    // Convert to list
    return dailyMap.entries.map((entry) {
      final parts = entry.key.split('-');
      return DailySignupData(
        date: DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        ),
        count: entry.value,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get retention data for cohorts
  Future<List<RetentionData>> getRetentionData({int cohortCount = 7}) async {
    final now = DateTime.now();
    final results = <RetentionData>[];

    for (int i = cohortCount - 1; i >= 0; i--) {
      final cohortDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i + 30)); // Start from 30+ days ago

      final cohortEnd = cohortDate.add(const Duration(days: 1));

      // Get users who signed up on this date
      final cohortSnapshot = await _usersCollection
          .where(AdminConstants.userCreatedAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(cohortDate))
          .where(AdminConstants.userCreatedAt,
              isLessThan: Timestamp.fromDate(cohortEnd))
          .get();

      final cohortUsers = cohortSnapshot.docs;
      final totalUsers = cohortUsers.length;

      if (totalUsers == 0) {
        results.add(RetentionData(
          cohortDate: cohortDate,
          totalUsers: 0,
          d1Retention: 0,
          d3Retention: 0,
          d7Retention: 0,
          d14Retention: 0,
          d30Retention: 0,
        ));
        continue;
      }

      // Calculate retention for each period
      int d1Count = 0, d3Count = 0, d7Count = 0, d14Count = 0, d30Count = 0;

      for (final doc in cohortUsers) {
        final data = doc.data();
        final lastLogin = data[AdminConstants.userLastLoginAt] as Timestamp?;

        if (lastLogin != null) {
          final lastLoginDate = lastLogin.toDate();
          final daysSinceSignup =
              lastLoginDate.difference(cohortDate).inDays;

          if (daysSinceSignup >= 1) d1Count++;
          if (daysSinceSignup >= 3) d3Count++;
          if (daysSinceSignup >= 7) d7Count++;
          if (daysSinceSignup >= 14) d14Count++;
          if (daysSinceSignup >= 30) d30Count++;
        }
      }

      results.add(RetentionData(
        cohortDate: cohortDate,
        totalUsers: totalUsers,
        d1Retention: (d1Count / totalUsers) * 100,
        d3Retention: (d3Count / totalUsers) * 100,
        d7Retention: (d7Count / totalUsers) * 100,
        d14Retention: (d14Count / totalUsers) * 100,
        d30Retention: (d30Count / totalUsers) * 100,
      ));
    }

    return results;
  }

  String _formatProviderName(String provider) {
    switch (provider.toLowerCase()) {
      case 'google.com':
      case 'google':
        return 'Google';
      case 'apple.com':
      case 'apple':
        return 'Apple';
      case 'kakao':
        return 'Kakao';
      case 'anonymous':
        return 'Anonymous';
      default:
        return provider;
    }
  }
}
