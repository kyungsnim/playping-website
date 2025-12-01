import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a finished game room with its results
class GameResultModel {
  final String roomId;
  final String roomName;
  final String gameType;
  final String mode; // 'single' or 'multi'
  final String gameMode; // 'individual' or 'team'
  final DateTime finishedAt;
  final List<String> playerIds;
  final int playerCount;
  final String? hostId;
  final List<GameConfig>? games; // for multi-game mode
  final int? teamCount;
  final List<TeamInfo>? teams;
  final Map<String, String>? playerTeamMap;
  final DocumentSnapshot? documentSnapshot; // for pagination

  GameResultModel({
    required this.roomId,
    required this.roomName,
    required this.gameType,
    required this.mode,
    required this.gameMode,
    required this.finishedAt,
    required this.playerIds,
    required this.playerCount,
    this.hostId,
    this.games,
    this.teamCount,
    this.teams,
    this.playerTeamMap,
    this.documentSnapshot,
  });

  factory GameResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse games for multi-game mode
    List<GameConfig>? games;
    if (data['games'] != null) {
      games = (data['games'] as List)
          .map((g) => GameConfig.fromMap(g as Map<String, dynamic>))
          .toList();
    }

    // Parse teams
    List<TeamInfo>? teams;
    if (data['teams'] != null) {
      teams = (data['teams'] as List)
          .map((t) => TeamInfo.fromMap(t as Map<String, dynamic>))
          .toList();
    }

    return GameResultModel(
      roomId: doc.id,
      roomName: data['name'] as String? ?? 'Unknown Room',
      gameType: data['gameType'] as String? ?? 'Unknown',
      mode: data['mode'] as String? ?? 'single',
      gameMode: data['gameMode'] as String? ?? 'GameMode.individual',
      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      playerIds: List<String>.from(data['playerIds'] ?? []),
      playerCount: (data['playerIds'] as List?)?.length ?? 0,
      hostId: data['hostId'] as String?,
      games: games,
      teamCount: data['teamCount'] as int?,
      teams: teams,
      playerTeamMap: data['playerTeamMap'] != null
          ? Map<String, String>.from(data['playerTeamMap'])
          : null,
      documentSnapshot: doc,
    );
  }

  bool get isTeamMode => gameMode.contains('team');
  bool get isMultiGame => mode == 'multi';

  String get displayGameType {
    if (isMultiGame && games != null && games!.isNotEmpty) {
      return '멀티게임 (${games!.length}개)';
    }
    return _formatGameType(gameType);
  }

  static String _formatGameType(String gameType) {
    final typeMap = {
      'GameType.reflexes': '순발력 게임',
      'GameType.memory': '기억력 게임',
      'GameType.bombPassing': '폭탄 돌리기',
      'GameType.findDifference': '틀린그림찾기',
      'GameType.oxQuiz': 'OX 퀴즈',
      'GameType.landmark': '랜드마크 퀴즈',
      'GameType.tileMatching': '타일 매칭',
      'GameType.speedTyping': '빠른 타자',
      'GameType.leftRight': '좌우 구분',
      'GameType.mathSpeed': '수학 스피드',
      'GameType.idioms': '사자성어',
      'GameType.jumpGame': '점프 게임',
      'GameType.archery': '양궁',
      'GameType.numberSum': '숫자 합',
      'GameType.escapeRoom': '방탈출',
      'GameType.avoidDog': '강아지 피하기',
      'GameType.colorSwitch': '컬러 스위치',
      'GameType.koreanWordle': '한글 워들',
      'GameType.oddOneOut': '다른 것 찾기',
    };
    return typeMap[gameType] ?? gameType;
  }
}

/// Game configuration for multi-game mode
class GameConfig {
  final String gameType;
  final Map<String, dynamic> settings;
  final int order;

  GameConfig({
    required this.gameType,
    required this.settings,
    required this.order,
  });

  factory GameConfig.fromMap(Map<String, dynamic> data) {
    return GameConfig(
      gameType: data['gameType'] as String? ?? '',
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      order: data['order'] as int? ?? 0,
    );
  }

  String get displayName => GameResultModel._formatGameType(gameType);
}

/// Team information
class TeamInfo {
  final String id;
  final String name;
  final String color;
  final List<String> memberIds;

  TeamInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.memberIds,
  });

  factory TeamInfo.fromMap(Map<String, dynamic> data) {
    return TeamInfo(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      color: data['color'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
    );
  }
}

/// Individual player result
class PlayerResult {
  final String playerId;
  final String playerNickname;
  final int score;
  final int? rank;
  final int? completionTime;
  final DateTime? finishedAt;
  final String? teamId;
  final int? teamRank;
  final int? gameIndex; // for multi-game

  PlayerResult({
    required this.playerId,
    required this.playerNickname,
    required this.score,
    this.rank,
    this.completionTime,
    this.finishedAt,
    this.teamId,
    this.teamRank,
    this.gameIndex,
  });

  factory PlayerResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayerResult(
      playerId: data['playerId'] as String? ?? doc.id,
      playerNickname: data['playerNickname'] as String? ?? 'Unknown',
      score: (data['score'] as num?)?.toInt() ?? 0,
      rank: data['rank'] as int?,
      completionTime: data['completionTime'] as int?,
      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate(),
      teamId: data['teamId'] as String?,
      teamRank: data['teamRank'] as int?,
      gameIndex: data['gameIndex'] as int?,
    );
  }
}

/// Team result
class TeamResult {
  final String teamId;
  final String teamName;
  final int teamScore;
  final int teamRank;
  final List<PlayerResult> memberResults;

  TeamResult({
    required this.teamId,
    required this.teamName,
    required this.teamScore,
    required this.teamRank,
    required this.memberResults,
  });

  factory TeamResult.fromFirestore(DocumentSnapshot doc, List<PlayerResult> allResults) {
    final data = doc.data() as Map<String, dynamic>;
    final teamId = doc.id;

    // Filter member results for this team
    final memberResults = allResults.where((r) => r.teamId == teamId).toList();
    memberResults.sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));

    return TeamResult(
      teamId: teamId,
      teamName: data['teamName'] as String? ?? 'Unknown Team',
      teamScore: (data['teamScore'] as num?)?.toInt() ?? 0,
      teamRank: (data['teamRank'] as num?)?.toInt() ?? 0,
      memberResults: memberResults,
    );
  }
}

/// Complete game result detail including all player/team results
class GameResultDetail {
  final GameResultModel gameInfo;
  final List<PlayerResult> playerResults;
  final List<TeamResult>? teamResults;
  final Map<String, String> playerNicknames; // playerId -> nickname

  GameResultDetail({
    required this.gameInfo,
    required this.playerResults,
    this.teamResults,
    required this.playerNicknames,
  });

  /// Get winner information
  String get winnerInfo {
    if (gameInfo.isTeamMode && teamResults != null && teamResults!.isNotEmpty) {
      final winner = teamResults!.firstWhere(
        (t) => t.teamRank == 1,
        orElse: () => teamResults!.first,
      );
      return '${winner.teamName} 승리!';
    } else if (playerResults.isNotEmpty) {
      final winner = playerResults.firstWhere(
        (p) => p.rank == 1,
        orElse: () => playerResults.first,
      );
      return '${winner.playerNickname} 승리!';
    } else if (playerNicknames.isNotEmpty) {
      // No results but we have player info from room
      if (playerNicknames.length == 1) {
        return '${playerNicknames.values.first} 플레이';
      }
      return '게임 완료';
    }
    return '결과 없음';
  }
}
