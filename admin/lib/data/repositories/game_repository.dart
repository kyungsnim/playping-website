import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../models/game_stats.dart';

/// Repository for fetching game statistics from Firestore
class GameRepository {
  final FirebaseFirestore _firestore;

  GameRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      _firestore.collection(AdminConstants.roomsCollection);

  /// Get overall game statistics
  Future<GameStats> getGameStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));
    final monthStart = todayStart.subtract(const Duration(days: 30));

    // Get finished games count
    final totalGamesSnapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusFinished)
        .count()
        .get();

    final todayGamesSnapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusFinished)
        .where(AdminConstants.roomFinishedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .count()
        .get();

    final weekGamesSnapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusFinished)
        .where(AdminConstants.roomFinishedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .count()
        .get();

    final monthGamesSnapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusFinished)
        .where(AdminConstants.roomFinishedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .count()
        .get();

    // Get active rooms (waiting or playing)
    final waitingRoomsSnapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusWaiting)
        .count()
        .get();

    final playingRoomsSnapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusPlaying)
        .count()
        .get();

    final activeRooms =
        (waitingRoomsSnapshot.count ?? 0) + (playingRoomsSnapshot.count ?? 0);

    // Calculate average players per game (sample recent 100 games)
    final recentGamesSnapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusFinished)
        .orderBy(AdminConstants.roomFinishedAt, descending: true)
        .limit(100)
        .get();

    double avgPlayers = 0;
    if (recentGamesSnapshot.docs.isNotEmpty) {
      int totalPlayers = 0;
      for (final doc in recentGamesSnapshot.docs) {
        final playerIds = doc.data()[AdminConstants.roomPlayerIds] as List?;
        totalPlayers += playerIds?.length ?? 0;
      }
      avgPlayers = totalPlayers / recentGamesSnapshot.docs.length;
    }

    return GameStats(
      totalGamesPlayed: totalGamesSnapshot.count ?? 0,
      todayGamesPlayed: todayGamesSnapshot.count ?? 0,
      weekGamesPlayed: weekGamesSnapshot.count ?? 0,
      monthGamesPlayed: monthGamesSnapshot.count ?? 0,
      activeRooms: activeRooms,
      avgPlayersPerGame: avgPlayers,
    );
  }

  /// Get game statistics by type
  Future<List<GameTypeStats>> getGameTypeStats() async {
    final snapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusFinished)
        .get();

    final gameTypeMap = <String, int>{};

    for (final doc in snapshot.docs) {
      final gameType =
          doc.data()[AdminConstants.roomGameType] as String? ?? 'unknown';
      gameTypeMap[gameType] = (gameTypeMap[gameType] ?? 0) + 1;
    }

    final total = snapshot.docs.length;

    final result = gameTypeMap.entries.map((entry) {
      return GameTypeStats(
        gameType: entry.key,
        displayName:
            AdminConstants.gameTypeNames[entry.key] ?? entry.key,
        playCount: entry.value,
        percentage: total > 0 ? (entry.value / total) * 100 : 0,
      );
    }).toList();

    // Sort by play count descending
    result.sort((a, b) => b.playCount.compareTo(a.playCount));

    return result;
  }

  /// Get daily game data for the last N days
  Future<List<DailyGameData>> getDailyGames({int days = 30}) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final snapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusFinished)
        .where(AdminConstants.roomFinishedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy(AdminConstants.roomFinishedAt)
        .get();

    // Initialize all dates with 0
    final dailyMap = <String, int>{};
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyMap[key] = 0;
    }

    // Count games per day
    for (final doc in snapshot.docs) {
      final finishedAt =
          doc.data()[AdminConstants.roomFinishedAt] as Timestamp?;
      if (finishedAt != null) {
        final date = finishedAt.toDate();
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyMap[key] = (dailyMap[key] ?? 0) + 1;
      }
    }

    return dailyMap.entries.map((entry) {
      final parts = entry.key.split('-');
      return DailyGameData(
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

  /// Get hourly game distribution (for today)
  Future<List<HourlyGameData>> getHourlyGames() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final snapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusFinished)
        .where(AdminConstants.roomFinishedAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where(AdminConstants.roomFinishedAt,
            isLessThan: Timestamp.fromDate(todayEnd))
        .get();

    // Initialize all hours with 0
    final hourlyMap = <int, int>{};
    for (int i = 0; i < 24; i++) {
      hourlyMap[i] = 0;
    }

    // Count games per hour
    for (final doc in snapshot.docs) {
      final finishedAt =
          doc.data()[AdminConstants.roomFinishedAt] as Timestamp?;
      if (finishedAt != null) {
        final hour = finishedAt.toDate().hour;
        hourlyMap[hour] = (hourlyMap[hour] ?? 0) + 1;
      }
    }

    return hourlyMap.entries
        .map((entry) => HourlyGameData(hour: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));
  }
}
