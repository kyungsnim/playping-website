import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_result_model.dart';

/// Repository for fetching game results from Firestore
class GameResultRepository {
  final FirebaseFirestore _firestore;

  GameResultRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      _firestore.collection('rooms');

  /// Get finished games with pagination (ordered by finishedAt descending)
  /// Note: Uses in-memory sorting to avoid composite index requirement
  Future<List<GameResultModel>> getFinishedGames({
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    // Get all finished rooms and sort in memory
    final snapshot = await _roomsCollection
        .where('status', isEqualTo: 'RoomStatus.finished')
        .get();

    // Convert to models and sort by finishedAt descending
    var results = snapshot.docs
        .map((doc) => GameResultModel.fromFirestore(doc))
        .toList();
    results.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));

    // Handle pagination manually
    if (startAfter != null) {
      final startIndex = results.indexWhere(
        (r) => r.roomId == startAfter.id,
      );
      if (startIndex >= 0 && startIndex + 1 < results.length) {
        results = results.sublist(startIndex + 1);
      } else {
        return [];
      }
    }

    // Apply limit
    if (results.length > limit) {
      results = results.sublist(0, limit);
    }

    return results;
  }

  /// Get detailed results for a specific game
  Future<GameResultDetail> getGameResultDetail(String roomId) async {
    // Get room info
    final roomDoc = await _roomsCollection.doc(roomId).get();
    if (!roomDoc.exists) {
      throw Exception('Room not found');
    }

    final gameInfo = GameResultModel.fromFirestore(roomDoc);

    // Get player results from subcollection (without orderBy to get all results)
    final resultsSnapshot = await _roomsCollection
        .doc(roomId)
        .collection('results')
        .get();

    var playerResults = resultsSnapshot.docs
        .map((doc) => PlayerResult.fromFirestore(doc))
        .toList();

    // Sort by score descending and assign rank if not present
    playerResults.sort((a, b) => b.score.compareTo(a.score));
    playerResults = playerResults.asMap().entries.map((entry) {
      final index = entry.key;
      final result = entry.value;
      return PlayerResult(
        playerId: result.playerId,
        playerNickname: result.playerNickname,
        score: result.score,
        rank: result.rank ?? (index + 1),
        completionTime: result.completionTime,
        finishedAt: result.finishedAt,
        teamId: result.teamId,
        teamRank: result.teamRank,
        gameIndex: result.gameIndex,
      );
    }).toList();

    // Get player nicknames
    final playerNicknames = <String, String>{};
    for (final playerId in gameInfo.playerIds) {
      try {
        final userDoc = await _firestore.collection('users').doc(playerId).get();
        if (userDoc.exists) {
          playerNicknames[playerId] =
              userDoc.data()?['nickname'] as String? ?? 'Unknown';
        }
      } catch (e) {
        playerNicknames[playerId] = 'Unknown';
      }
    }

    // Get team results if team mode
    List<TeamResult>? teamResults;
    if (gameInfo.isTeamMode) {
      final teamResultsSnapshot = await _roomsCollection
          .doc(roomId)
          .collection('teamResults')
          .get();

      if (teamResultsSnapshot.docs.isNotEmpty) {
        teamResults = teamResultsSnapshot.docs
            .map((doc) => TeamResult.fromFirestore(doc, playerResults))
            .toList();
      } else {
        // Fallback: Build team results from player results and team info
        teamResults = _buildTeamResultsFromPlayerResults(
          gameInfo,
          playerResults,
          playerNicknames,
        );
      }
    }

    return GameResultDetail(
      gameInfo: gameInfo,
      playerResults: playerResults,
      teamResults: teamResults,
      playerNicknames: playerNicknames,
    );
  }

  /// Build team results from player results when teamResults subcollection is empty
  List<TeamResult> _buildTeamResultsFromPlayerResults(
    GameResultModel gameInfo,
    List<PlayerResult> playerResults,
    Map<String, String> playerNicknames,
  ) {
    if (gameInfo.teams == null || gameInfo.playerTeamMap == null) {
      return [];
    }

    final teamResultsMap = <String, List<PlayerResult>>{};
    final teamScores = <String, int>{};

    // Group player results by team
    for (final result in playerResults) {
      final teamId = result.teamId ?? gameInfo.playerTeamMap?[result.playerId];
      if (teamId != null) {
        teamResultsMap.putIfAbsent(teamId, () => []).add(result);
        teamScores[teamId] = (teamScores[teamId] ?? 0) + result.score;
      }
    }

    // Sort teams by total score
    final sortedTeamIds = teamScores.keys.toList()
      ..sort((a, b) => (teamScores[b] ?? 0).compareTo(teamScores[a] ?? 0));

    // Build team results
    return sortedTeamIds.asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final teamId = entry.value;
      final teamInfo = gameInfo.teams?.firstWhere(
        (t) => t.id == teamId,
        orElse: () => TeamInfo(id: teamId, name: 'Team $teamId', color: '', memberIds: []),
      );

      final memberResults = teamResultsMap[teamId] ?? [];
      memberResults.sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));

      return TeamResult(
        teamId: teamId,
        teamName: teamInfo?.name ?? 'Unknown Team',
        teamScore: teamScores[teamId] ?? 0,
        teamRank: rank,
        memberResults: memberResults,
      );
    }).toList();
  }

  /// Get multi-game scores for a room
  Future<List<MultiGameScore>> getMultiGameScores(String roomId) async {
    final snapshot = await _firestore
        .collection('multiGameScores')
        .where('roomId', isEqualTo: roomId)
        .get();

    final scores = snapshot.docs.map((doc) => MultiGameScore.fromFirestore(doc)).toList();
    // Sort by finalRank (handle 0 or missing rank)
    scores.sort((a, b) {
      if (a.finalRank == 0 && b.finalRank == 0) {
        return b.totalScore.compareTo(a.totalScore);
      }
      if (a.finalRank == 0) return 1;
      if (b.finalRank == 0) return -1;
      return a.finalRank.compareTo(b.finalRank);
    });
    return scores;
  }

  /// Get team scores for multi-game team mode
  Future<List<TeamGameScore>> getTeamGameScores(String roomId) async {
    final snapshot = await _firestore
        .collection('teamScores')
        .where('roomId', isEqualTo: roomId)
        .get();

    final scores = snapshot.docs.map((doc) => TeamGameScore.fromFirestore(doc)).toList();
    // Sort by finalRank (handle 0 or missing rank)
    scores.sort((a, b) {
      if (a.finalRank == 0 && b.finalRank == 0) {
        return b.totalScore.compareTo(a.totalScore);
      }
      if (a.finalRank == 0) return 1;
      if (b.finalRank == 0) return -1;
      return a.finalRank.compareTo(b.finalRank);
    });
    return scores;
  }
}

/// Multi-game score for a player
class MultiGameScore {
  final String playerId;
  final String playerNickname;
  final String? teamId;
  final int totalScore;
  final int finalRank;
  final List<GameScoreEntry> gameScores;

  MultiGameScore({
    required this.playerId,
    required this.playerNickname,
    this.teamId,
    required this.totalScore,
    required this.finalRank,
    required this.gameScores,
  });

  factory MultiGameScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<GameScoreEntry> gameScores = [];
    if (data['gameScores'] != null) {
      gameScores = (data['gameScores'] as List)
          .map((g) => GameScoreEntry.fromMap(g as Map<String, dynamic>))
          .toList();
    }

    return MultiGameScore(
      playerId: data['playerId'] as String? ?? '',
      playerNickname: data['playerNickname'] as String? ?? 'Unknown',
      teamId: data['teamId'] as String?,
      totalScore: (data['totalScore'] as num?)?.toInt() ?? 0,
      finalRank: (data['finalRank'] as num?)?.toInt() ?? 0,
      gameScores: gameScores,
    );
  }
}

/// Individual game score within multi-game
class GameScoreEntry {
  final int gameIndex;
  final String gameType;
  final int rank;
  final int score;

  GameScoreEntry({
    required this.gameIndex,
    required this.gameType,
    required this.rank,
    required this.score,
  });

  factory GameScoreEntry.fromMap(Map<String, dynamic> data) {
    return GameScoreEntry(
      gameIndex: data['gameIndex'] as int? ?? 0,
      gameType: data['gameType'] as String? ?? '',
      rank: data['rank'] as int? ?? 0,
      score: data['score'] as int? ?? 0,
    );
  }

  String get displayGameType => _formatGameType(gameType);

  static String _formatGameType(String gameType) {
    final typeMap = {
      'GameType.reflexes': '순발력',
      'GameType.memory': '기억력',
      'GameType.bombPassing': '폭탄 돌리기',
      'GameType.findDifference': '틀린그림',
      'GameType.oxQuiz': 'OX 퀴즈',
      'GameType.landmark': '랜드마크',
      'GameType.tileMatching': '타일 매칭',
      'GameType.speedTyping': '빠른 타자',
      'GameType.leftRight': '좌우 구분',
      'GameType.mathSpeed': '수학 스피드',
      'GameType.idioms': '사자성어',
      'GameType.jumpGame': '점프',
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

/// Team score for multi-game team mode
class TeamGameScore {
  final String teamId;
  final String teamName;
  final int totalScore;
  final int finalRank;
  final List<TeamGameScoreEntry> gameScores;

  TeamGameScore({
    required this.teamId,
    required this.teamName,
    required this.totalScore,
    required this.finalRank,
    required this.gameScores,
  });

  factory TeamGameScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<TeamGameScoreEntry> gameScores = [];
    if (data['gameScores'] != null) {
      gameScores = (data['gameScores'] as List)
          .map((g) => TeamGameScoreEntry.fromMap(g as Map<String, dynamic>))
          .toList();
    }

    return TeamGameScore(
      teamId: data['teamId'] as String? ?? doc.id,
      teamName: data['teamName'] as String? ?? 'Unknown Team',
      totalScore: (data['totalScore'] as num?)?.toInt() ?? 0,
      finalRank: (data['finalRank'] as num?)?.toInt() ?? 0,
      gameScores: gameScores,
    );
  }
}

/// Team game score entry for multi-game
class TeamGameScoreEntry {
  final int gameIndex;
  final String gameType;
  final int teamScore;
  final List<MemberScoreEntry> memberScores;

  TeamGameScoreEntry({
    required this.gameIndex,
    required this.gameType,
    required this.teamScore,
    required this.memberScores,
  });

  factory TeamGameScoreEntry.fromMap(Map<String, dynamic> data) {
    List<MemberScoreEntry> memberScores = [];
    if (data['memberScores'] != null) {
      memberScores = (data['memberScores'] as List)
          .map((m) => MemberScoreEntry.fromMap(m as Map<String, dynamic>))
          .toList();
    }

    return TeamGameScoreEntry(
      gameIndex: data['gameIndex'] as int? ?? 0,
      gameType: data['gameType'] as String? ?? '',
      teamScore: data['teamScore'] as int? ?? 0,
      memberScores: memberScores,
    );
  }

  String get displayGameType => GameScoreEntry._formatGameType(gameType);
}

/// Member score within team game
class MemberScoreEntry {
  final String playerId;
  final String? playerNickname;
  final int rank;
  final int score;

  MemberScoreEntry({
    required this.playerId,
    this.playerNickname,
    required this.rank,
    required this.score,
  });

  factory MemberScoreEntry.fromMap(Map<String, dynamic> data) {
    return MemberScoreEntry(
      playerId: data['playerId'] as String? ?? '',
      playerNickname: data['playerNickname'] as String?,
      rank: data['rank'] as int? ?? 0,
      score: data['score'] as int? ?? 0,
    );
  }
}
