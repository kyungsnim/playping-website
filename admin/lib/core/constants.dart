/// Admin Dashboard Constants
library;

class AdminConstants {
  AdminConstants._();

  // Admin email whitelist - only these emails can access admin dashboard
  static const List<String> adminEmails = [
    'skyboom86@gmail.com',
    // Add more admin emails here
  ];

  // Firestore collection names (same as main app)
  static const String usersCollection = 'users';
  static const String roomsCollection = 'rooms';
  static const String reportsCollection = 'reports';

  // User fields
  static const String userEmail = 'email';
  static const String userNickname = 'nickname';
  static const String userCreatedAt = 'createdAt';
  static const String userLastLoginAt = 'lastLoginAt';
  static const String userCountry = 'country';
  static const String userCountryCode = 'countryCode';
  static const String userAdministrativeArea = 'administrativeArea';
  static const String userLocality = 'locality';
  static const String userProvider = 'provider';

  // Room fields
  static const String roomGameType = 'gameType';
  static const String roomStatus = 'status';
  static const String roomCreatedAt = 'createdAt';
  static const String roomFinishedAt = 'finishedAt';
  static const String roomPlayerIds = 'playerIds';

  // Room status values
  static const String roomStatusWaiting = 'RoomStatus.waiting';
  static const String roomStatusPlaying = 'RoomStatus.playing';
  static const String roomStatusFinished = 'RoomStatus.finished';

  // Report fields
  static const String reportReporterId = 'reporterId';
  static const String reportReporterNickname = 'reporterNickname';
  static const String reportReportedUserId = 'reportedUserId';
  static const String reportReportedUserNickname = 'reportedUserNickname';
  static const String reportReason = 'reason';
  static const String reportDescription = 'description';
  static const String reportStatus = 'status';
  static const String reportCreatedAt = 'createdAt';
  static const String reportReviewedAt = 'reviewedAt';
  static const String reportReviewedBy = 'reviewedBy';
  static const String reportAction = 'action';

  // Report status values
  static const String reportStatusPending = 'pending';
  static const String reportStatusReviewed = 'reviewed';
  static const String reportStatusDismissed = 'dismissed';

  // Game type display names
  static const Map<String, String> gameTypeNames = {
    'GameType.reflexes': 'Reflexes',
    'GameType.memory': 'Memory',
    'GameType.liar': 'Liar Game',
    'GameType.bombPassing': 'Bomb Passing',
    'GameType.dilemma': 'Dilemma',
    'GameType.roulette': 'Roulette',
    'GameType.truthOrDare': 'Truth or Dare',
    'GameType.findDifference': 'Find Difference',
    'GameType.landmark': 'Landmark Quiz',
    'GameType.tileMatching': 'Tile Matching',
    'GameType.speedTyping': 'Speed Typing',
    'GameType.leftRight': 'Left Right',
    'GameType.mathSpeed': 'Math Speed',
    'GameType.idioms': 'Idioms',
    'GameType.archery': 'Archery',
    'GameType.jump': 'Jump Game',
    'GameType.colorSwitch': 'Color Switch',
    'GameType.numberSum': 'Number Sum',
    'GameType.escapeRoom': 'Escape Room',
    'GameType.oxQuiz': 'OX Quiz',
  };
}
