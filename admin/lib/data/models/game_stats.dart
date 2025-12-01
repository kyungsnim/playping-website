/// Game statistics data models
library;

class GameStats {
  final int totalGamesPlayed;
  final int todayGamesPlayed;
  final int weekGamesPlayed;
  final int monthGamesPlayed;
  final int activeRooms;
  final double avgPlayersPerGame;
  // Multi-game mode stats
  final int singleModeRooms;
  final int multiModeRooms;
  final int totalIndividualGames; // 멀티게임 모드 내 개별 게임 수 포함

  const GameStats({
    required this.totalGamesPlayed,
    required this.todayGamesPlayed,
    required this.weekGamesPlayed,
    required this.monthGamesPlayed,
    required this.activeRooms,
    required this.avgPlayersPerGame,
    this.singleModeRooms = 0,
    this.multiModeRooms = 0,
    this.totalIndividualGames = 0,
  });

  factory GameStats.empty() => const GameStats(
        totalGamesPlayed: 0,
        todayGamesPlayed: 0,
        weekGamesPlayed: 0,
        monthGamesPlayed: 0,
        activeRooms: 0,
        avgPlayersPerGame: 0,
        singleModeRooms: 0,
        multiModeRooms: 0,
        totalIndividualGames: 0,
      );
}

class GameTypeStats {
  final String gameType;
  final String displayName;
  final int playCount;
  final double percentage;

  const GameTypeStats({
    required this.gameType,
    required this.displayName,
    required this.playCount,
    required this.percentage,
  });
}

class DailyGameData {
  final DateTime date;
  final int count;

  const DailyGameData({
    required this.date,
    required this.count,
  });
}

class HourlyGameData {
  final int hour;
  final int count;

  const HourlyGameData({
    required this.hour,
    required this.count,
  });
}
