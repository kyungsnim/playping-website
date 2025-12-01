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

  DocumentReference<Map<String, dynamic>> get _statsDocument => _firestore
      .collection(AdminConstants.statsCollection)
      .doc(AdminConstants.gameStatsDocument);

  /// Get overall game statistics from pre-aggregated stats document
  /// Falls back to direct query if stats document doesn't exist
  Future<GameStats> getGameStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));
    final monthStart = todayStart.subtract(const Duration(days: 30));

    // Try to get pre-aggregated stats first
    final statsDoc = await _statsDocument.get();

    if (statsDoc.exists) {
      final data = statsDoc.data()!;
      final dailyGames = data['dailyGames'] as Map<String, dynamic>? ?? {};

      // Calculate today/week/month games from dailyGames
      int todayGames = 0;
      int weekGames = 0;
      int monthGames = 0;

      for (final entry in dailyGames.entries) {
        final parts = entry.key.split('-');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          final count = (entry.value as num?)?.toInt() ?? 0;

          if (!date.isBefore(todayStart)) {
            todayGames += count;
          }
          if (!date.isBefore(weekStart)) {
            weekGames += count;
          }
          if (!date.isBefore(monthStart)) {
            monthGames += count;
          }
        }
      }

      // Get active rooms count (still need to query for this)
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

      // Calculate average players
      final totalGames = (data['totalGames'] as num?)?.toInt() ?? 0;
      final totalPlayers = (data['totalPlayers'] as num?)?.toInt() ?? 0;
      final avgPlayers = totalGames > 0 ? totalPlayers / totalGames : 0.0;

      return GameStats(
        totalGamesPlayed: totalGames,
        todayGamesPlayed: todayGames,
        weekGamesPlayed: weekGames,
        monthGamesPlayed: monthGames,
        activeRooms: activeRooms,
        avgPlayersPerGame: avgPlayers,
        singleModeRooms: (data['singleModeCount'] as num?)?.toInt() ?? 0,
        multiModeRooms: (data['multiModeCount'] as num?)?.toInt() ?? 0,
        totalIndividualGames:
            (data['totalIndividualGames'] as num?)?.toInt() ?? 0,
      );
    }

    // Fallback: direct query if stats document doesn't exist
    return _getGameStatsDirect();
  }

  /// Direct query method (fallback for when stats document doesn't exist)
  Future<GameStats> _getGameStatsDirect() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));
    final monthStart = todayStart.subtract(const Duration(days: 30));

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

    final recentGamesSnapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusFinished)
        .orderBy(AdminConstants.roomFinishedAt, descending: true)
        .limit(100)
        .get();

    double avgPlayers = 0;
    int singleModeRooms = 0;
    int multiModeRooms = 0;
    int totalIndividualGames = 0;

    if (recentGamesSnapshot.docs.isNotEmpty) {
      int totalPlayers = 0;
      for (final doc in recentGamesSnapshot.docs) {
        final data = doc.data();
        final playerIds = data[AdminConstants.roomPlayerIds] as List?;
        totalPlayers += playerIds?.length ?? 0;

        final mode = data[AdminConstants.roomMode] as String? ??
            AdminConstants.roomModeSingle;
        if (mode == AdminConstants.roomModeMulti) {
          multiModeRooms++;
          final games = data[AdminConstants.roomGames] as List?;
          totalIndividualGames += games?.length ?? 0;
        } else {
          singleModeRooms++;
          totalIndividualGames += 1;
        }
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
      singleModeRooms: singleModeRooms,
      multiModeRooms: multiModeRooms,
      totalIndividualGames: totalIndividualGames,
    );
  }

  /// Get game statistics by type from pre-aggregated stats
  Future<List<GameTypeStats>> getGameTypeStats() async {
    // Try to get pre-aggregated stats first
    final statsDoc = await _statsDocument.get();

    if (statsDoc.exists) {
      final data = statsDoc.data()!;
      final gameTypeCounts =
          data['gameTypeCounts'] as Map<String, dynamic>? ?? {};

      int totalGames = 0;
      for (final count in gameTypeCounts.values) {
        totalGames += (count as num?)?.toInt() ?? 0;
      }

      final result = gameTypeCounts.entries.map((entry) {
        final count = (entry.value as num?)?.toInt() ?? 0;
        return GameTypeStats(
          gameType: entry.key,
          displayName: AdminConstants.gameTypeNames[entry.key] ?? entry.key,
          playCount: count,
          percentage: totalGames > 0 ? (count / totalGames) * 100 : 0,
        );
      }).toList();

      result.sort((a, b) => b.playCount.compareTo(a.playCount));
      return result;
    }

    // Fallback: direct query
    return _getGameTypeStatsDirect();
  }

  /// Direct query method for game type stats
  Future<List<GameTypeStats>> _getGameTypeStatsDirect() async {
    final snapshot = await _roomsCollection
        .where(AdminConstants.roomStatus,
            isEqualTo: AdminConstants.roomStatusFinished)
        .get();

    final gameTypeMap = <String, int>{};
    int totalGames = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final mode = data[AdminConstants.roomMode] as String? ??
          AdminConstants.roomModeSingle;

      if (mode == AdminConstants.roomModeMulti) {
        final games = data[AdminConstants.roomGames] as List?;
        if (games != null) {
          for (final game in games) {
            if (game is Map<String, dynamic>) {
              final gameType = game[AdminConstants.gameConfigGameType]
                      as String? ??
                  'unknown';
              gameTypeMap[gameType] = (gameTypeMap[gameType] ?? 0) + 1;
              totalGames++;
            }
          }
        }
      } else {
        final gameType =
            data[AdminConstants.roomGameType] as String? ?? 'unknown';
        gameTypeMap[gameType] = (gameTypeMap[gameType] ?? 0) + 1;
        totalGames++;
      }
    }

    final result = gameTypeMap.entries.map((entry) {
      return GameTypeStats(
        gameType: entry.key,
        displayName: AdminConstants.gameTypeNames[entry.key] ?? entry.key,
        playCount: entry.value,
        percentage: totalGames > 0 ? (entry.value / totalGames) * 100 : 0,
      );
    }).toList();

    result.sort((a, b) => b.playCount.compareTo(a.playCount));
    return result;
  }

  /// Get daily game data from pre-aggregated stats
  Future<List<DailyGameData>> getDailyGames({int days = 30}) async {
    final now = DateTime.now();
    final startDate =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

    // Initialize all dates with 0
    final dailyMap = <String, int>{};
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyMap[key] = 0;
    }

    // Try to get from pre-aggregated stats
    final statsDoc = await _statsDocument.get();

    if (statsDoc.exists) {
      final data = statsDoc.data()!;
      final aggregatedDailyGames =
          data['dailyGames'] as Map<String, dynamic>? ?? {};

      for (final entry in aggregatedDailyGames.entries) {
        if (dailyMap.containsKey(entry.key)) {
          dailyMap[entry.key] = (entry.value as num?)?.toInt() ?? 0;
        }
      }
    } else {
      // Fallback: direct query
      final snapshot = await _roomsCollection
          .where(AdminConstants.roomStatus,
              isEqualTo: AdminConstants.roomStatusFinished)
          .where(AdminConstants.roomFinishedAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy(AdminConstants.roomFinishedAt)
          .get();

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
  /// Note: This still requires direct query as hourly data is not pre-aggregated
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

    final hourlyMap = <int, int>{};
    for (int i = 0; i < 24; i++) {
      hourlyMap[i] = 0;
    }

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
