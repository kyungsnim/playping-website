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

/// User model for admin user management
class UserModel {
  final String id;
  final String? email;
  final String nickname;
  final String? provider;
  final String? countryCode;
  final String? country;
  final String? administrativeArea;
  final String? locality;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final int gamesPlayed;
  final bool isBlocked;
  final int coins;
  final bool adsRemoved;
  final DateTime? adsRemovedAt;
  final bool isAdmin;

  const UserModel({
    required this.id,
    this.email,
    required this.nickname,
    this.provider,
    this.countryCode,
    this.country,
    this.administrativeArea,
    this.locality,
    this.createdAt,
    this.lastLoginAt,
    this.gamesPlayed = 0,
    this.isBlocked = false,
    this.coins = 0,
    this.adsRemoved = false,
    this.adsRemovedAt,
    this.isAdmin = false,
  });

  String get displayProvider {
    switch (provider?.toLowerCase()) {
      case 'google.com':
      case 'google':
        return 'Google';
      case 'apple.com':
      case 'apple':
        return 'Apple';
      case 'kakao':
        return 'Kakao';
      case 'anonymous':
        return 'Guest';
      default:
        return provider ?? 'Unknown';
    }
  }

  String get location {
    final parts = <String>[];
    if (locality != null && locality!.isNotEmpty) parts.add(locality!);
    if (administrativeArea != null && administrativeArea!.isNotEmpty) {
      parts.add(administrativeArea!);
    }
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.isEmpty ? 'Unknown' : parts.join(', ');
  }
}
