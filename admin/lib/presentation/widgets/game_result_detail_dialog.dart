import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/game_result_model.dart';
import '../../data/repositories/game_result_repository.dart';
import '../providers/game_results_provider.dart';

class GameResultDetailDialog extends ConsumerWidget {
  final String roomId;

  const GameResultDetailDialog({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(gameResultDetailProvider(roomId));

    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        child: detailAsync.when(
          data: (detail) => _DetailContent(detail: detail),
          loading: () => const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('오류: $error'),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final GameResultDetail detail;

  const _DetailContent({required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.gameInfo.roomName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          detail.gameInfo.displayGameType,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (detail.gameInfo.isTeamMode) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '팀전',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(detail.gameInfo.finishedAt)} · ${detail.gameInfo.playerCount}명 참가',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Winner banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade300,
                Colors.amber.shade100,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Text(
                detail.winnerInfo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
        ),

        // Results content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: detail.gameInfo.isMultiGame
                ? _MultiGameResults(
                    detail: detail,
                    roomId: detail.gameInfo.roomId,
                  )
                : detail.gameInfo.isTeamMode
                    ? _TeamResults(detail: detail)
                    : _IndividualResults(detail: detail),
          ),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Room ID: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              SelectableText(
                detail.gameInfo.roomId,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.copy, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '복사',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: detail.gameInfo.roomId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room ID가 복사되었습니다'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Individual game results (not team mode)
class _IndividualResults extends StatelessWidget {
  final GameResultDetail detail;

  const _IndividualResults({required this.detail});

  @override
  Widget build(BuildContext context) {
    final sortedResults = List<PlayerResult>.from(detail.playerResults)
      ..sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));

    if (sortedResults.isEmpty) {
      // No results in subcollection - show player list from room data
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '참가자 정보',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '참가자 ${detail.gameInfo.playerCount}명',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: detail.playerNicknames.values.map((nickname) {
                    return Chip(
                      label: Text(nickname),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  '상세 점수 기록이 없습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '개인 순위',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...sortedResults.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          return _PlayerResultTile(
            rank: result.rank ?? (index + 1),
            nickname: result.playerNickname,
            score: result.score,
            isWinner: (result.rank ?? (index + 1)) == 1,
          );
        }),
      ],
    );
  }
}

/// Team game results
class _TeamResults extends StatelessWidget {
  final GameResultDetail detail;

  const _TeamResults({required this.detail});

  @override
  Widget build(BuildContext context) {
    final teamResults = detail.teamResults ?? [];

    if (teamResults.isEmpty) {
      return const Center(
        child: Text('팀 결과가 없습니다'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: teamResults.map((team) {
        final isWinner = team.teamRank == 1;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isWinner ? Colors.amber : Colors.grey.shade300,
              width: isWinner ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Team header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isWinner
                      ? Colors.amber.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.05),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRankColor(team.teamRank),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${team.teamRank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isWinner)
                      const Icon(Icons.emoji_events, color: Colors.amber),
                    if (isWinner) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        team.teamName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isWinner ? Colors.amber.shade800 : null,
                        ),
                      ),
                    ),
                    Text(
                      '${team.teamScore}점',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isWinner ? Colors.amber.shade800 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Team members
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: team.memberResults.asMap().entries.map((entry) {
                    final memberRank = entry.key + 1;
                    final member = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$memberRank.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              member.playerNickname,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${member.score}점',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
}

/// Multi-game results (shows each game's results)
class _MultiGameResults extends ConsumerWidget {
  final GameResultDetail detail;
  final String roomId;

  const _MultiGameResults({
    required this.detail,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeamMode = detail.gameInfo.isTeamMode;

    if (isTeamMode) {
      final teamScoresAsync = ref.watch(teamGameScoresProvider(roomId));
      return teamScoresAsync.when(
        data: (teamScores) => _buildTeamMultiGameResults(context, teamScores),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('오류: $e'),
      );
    } else {
      final multiScoresAsync = ref.watch(multiGameScoresProvider(roomId));
      return multiScoresAsync.when(
        data: (scores) => _buildIndividualMultiGameResults(context, scores),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('오류: $e'),
      );
    }
  }

  Widget _buildIndividualMultiGameResults(
    BuildContext context,
    List<MultiGameScore> scores,
  ) {
    if (scores.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '멀티게임 결과',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          const Text('멀티게임 점수 데이터가 없습니다'),
          const SizedBox(height: 16),
          _IndividualResults(detail: detail),
        ],
      );
    }

    final sortedScores = List<MultiGameScore>.from(scores)
      ..sort((a, b) => a.finalRank.compareTo(b.finalRank));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '멀티게임 최종 순위',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Final ranking table
        Table(
          columnWidths: const {
            0: FixedColumnWidth(50),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('순위', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('플레이어', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('총점', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...sortedScores.map((score) => TableRow(
                  decoration: score.finalRank == 1
                      ? BoxDecoration(color: Colors.amber.withValues(alpha: 0.1))
                      : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          if (score.finalRank == 1)
                            const Icon(Icons.emoji_events,
                                size: 16, color: Colors.amber),
                          if (score.finalRank == 1) const SizedBox(width: 4),
                          Text('${score.finalRank}'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(score.playerNickname),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${score.totalScore}점',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )),
          ],
        ),

        const SizedBox(height: 24),

        // Game by game breakdown
        Text(
          '게임별 점수',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        if (sortedScores.isNotEmpty && sortedScores.first.gameScores.isNotEmpty)
          ...sortedScores.first.gameScores.asMap().entries.map((gameEntry) {
            final gameIndex = gameEntry.key;
            final gameScore = gameEntry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Game ${gameIndex + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        gameScore.displayGameType,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...sortedScores.map((playerScore) {
                    final thisGameScore = playerScore.gameScores.length > gameIndex
                        ? playerScore.gameScores[gameIndex]
                        : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${thisGameScore?.rank ?? '-'}.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Expanded(child: Text(playerScore.playerNickname)),
                          Text(
                            '${thisGameScore?.score ?? 0}점',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTeamMultiGameResults(
    BuildContext context,
    List<TeamGameScore> teamScores,
  ) {
    if (teamScores.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '멀티게임 팀 결과',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          const Text('팀 점수 데이터가 없습니다'),
        ],
      );
    }

    final sortedTeams = List<TeamGameScore>.from(teamScores)
      ..sort((a, b) => a.finalRank.compareTo(b.finalRank));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '멀티게임 팀 최종 순위',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        ...sortedTeams.map((team) {
          final isWinner = team.finalRank == 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isWinner ? Colors.amber : Colors.grey.shade300,
                width: isWinner ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Team header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isWinner
                        ? Colors.amber.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getRankColor(team.finalRank),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${team.finalRank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isWinner)
                        const Icon(Icons.emoji_events, color: Colors.amber),
                      if (isWinner) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          team.teamName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isWinner ? Colors.amber.shade800 : null,
                          ),
                        ),
                      ),
                      Text(
                        '총 ${team.totalScore}점',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isWinner ? Colors.amber.shade800 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                // Game by game scores
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: team.gameScores.asMap().entries.map((entry) {
                      final gameIndex = entry.key;
                      final gameScore = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Game ${gameIndex + 1}: ${gameScore.displayGameType}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${gameScore.teamScore}점',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            if (gameScore.memberScores.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: gameScore.memberScores.map((member) {
                                  return Text(
                                    '${member.playerNickname ?? 'Player'}: ${member.score}점',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
}

class _PlayerResultTile extends StatelessWidget {
  final int rank;
  final String nickname;
  final int score;
  final bool isWinner;

  const _PlayerResultTile({
    required this.rank,
    required this.nickname,
    required this.score,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner ? Colors.amber.withValues(alpha: 0.1) : Colors.grey.shade50,
        border: Border.all(
          color: isWinner ? Colors.amber : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (isWinner) const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          if (isWinner) const SizedBox(width: 8),
          Expanded(
            child: Text(
              nickname,
              style: TextStyle(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '$score점',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWinner ? Colors.amber.shade800 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
}
