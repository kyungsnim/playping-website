/// User statistics data models
library;

class UserStats {
  final int totalUsers;
  final int todayNewUsers;
  final int weekNewUsers;
  final int monthNewUsers;
  final int activeToday;
  final int activeWeek;
  final int activeMonth;

  const UserStats({
    required this.totalUsers,
    required this.todayNewUsers,
    required this.weekNewUsers,
    required this.monthNewUsers,
    required this.activeToday,
    required this.activeWeek,
    required this.activeMonth,
  });

  factory UserStats.empty() => const UserStats(
    totalUsers: 0,
    todayNewUsers: 0,
    weekNewUsers: 0,
    monthNewUsers: 0,
    activeToday: 0,
    activeWeek: 0,
    activeMonth: 0,
  );
}

class CountryStats {
  final String countryCode;
  final String countryName;
  final int userCount;
  final double percentage;

  const CountryStats({
    required this.countryCode,
    required this.countryName,
    required this.userCount,
    required this.percentage,
  });
}

class RegionStats {
  final String region;
  final int userCount;
  final double percentage;

  const RegionStats({
    required this.region,
    required this.userCount,
    required this.percentage,
  });
}

class ProviderStats {
  final String provider;
  final int userCount;
  final double percentage;

  const ProviderStats({
    required this.provider,
    required this.userCount,
    required this.percentage,
  });
}

class RetentionData {
  final DateTime cohortDate;
  final int totalUsers;
  final double d1Retention;
  final double d3Retention;
  final double d7Retention;
  final double d14Retention;
  final double d30Retention;

  const RetentionData({
    required this.cohortDate,
    required this.totalUsers,
    required this.d1Retention,
    required this.d3Retention,
    required this.d7Retention,
    required this.d14Retention,
    required this.d30Retention,
  });
}

class DailySignupData {
  final DateTime date;
  final int count;

  const DailySignupData({
    required this.date,
    required this.count,
  });
}
