import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/game_result_model.dart';
import '../providers/game_results_provider.dart';
import '../widgets/game_result_detail_dialog.dart';

class GameResultsPage extends ConsumerStatefulWidget {
  const GameResultsPage({super.key});

  @override
  ConsumerState<GameResultsPage> createState() => _GameResultsPageState();
}

class _GameResultsPageState extends ConsumerState<GameResultsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(gameResultsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameResultsProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.history, size: 28),
                const SizedBox(width: 12),
                Text(
                  '게임 결과',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(gameResultsProvider.notifier).refresh();
                  },
                  tooltip: '새로고침',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: state.error != null
                ? _buildError(state.error!)
                : state.results.isEmpty && state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.results.isEmpty
                        ? _buildEmpty()
                        : _buildResultsList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(gameResultsProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_esports_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '완료된 게임이 없습니다',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(GameResultsState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.results.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.results.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final result = state.results[index];
        return _GameResultCard(
          result: result,
          onTap: () => _showDetailDialog(result),
        );
      },
    );
  }

  void _showDetailDialog(GameResultModel result) {
    showDialog(
      context: context,
      builder: (context) => GameResultDetailDialog(roomId: result.roomId),
    );
  }
}

class _GameResultCard extends StatelessWidget {
  final GameResultModel result;
  final VoidCallback onTap;

  const _GameResultCard({
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Game type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getGameTypeColor(result.gameType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getGameTypeIcon(result.gameType),
                  color: _getGameTypeColor(result.gameType),
                ),
              ),
              const SizedBox(width: 16),

              // Game info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.roomName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (result.isTeamMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '팀전',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (result.isMultiGame) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '멀티 ${result.games?.length ?? 0}게임',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.displayGameType,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${result.playerCount}명',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(result.finishedAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGameTypeIcon(String gameType) {
    final iconMap = {
      'GameType.reflexes': Icons.flash_on,
      'GameType.memory': Icons.psychology,
      'GameType.bombPassing': Icons.whatshot,
      'GameType.findDifference': Icons.compare,
      'GameType.oxQuiz': Icons.check_circle_outline,
      'GameType.landmark': Icons.location_city,
      'GameType.tileMatching': Icons.grid_view,
      'GameType.speedTyping': Icons.keyboard,
      'GameType.leftRight': Icons.swap_horiz,
      'GameType.mathSpeed': Icons.calculate,
      'GameType.idioms': Icons.menu_book,
      'GameType.jumpGame': Icons.sports_gymnastics,
      'GameType.archery': Icons.gps_fixed,
      'GameType.numberSum': Icons.numbers,
      'GameType.escapeRoom': Icons.door_front_door,
      'GameType.avoidDog': Icons.pets,
      'GameType.colorSwitch': Icons.palette,
      'GameType.koreanWordle': Icons.abc,
      'GameType.oddOneOut': Icons.search,
    };
    return iconMap[gameType] ?? Icons.games;
  }

  Color _getGameTypeColor(String gameType) {
    final colorMap = {
      'GameType.reflexes': Colors.orange,
      'GameType.memory': Colors.purple,
      'GameType.bombPassing': Colors.red,
      'GameType.findDifference': Colors.green,
      'GameType.oxQuiz': Colors.blue,
      'GameType.landmark': Colors.teal,
      'GameType.tileMatching': Colors.indigo,
      'GameType.speedTyping': Colors.cyan,
      'GameType.leftRight': Colors.pink,
      'GameType.mathSpeed': Colors.amber,
      'GameType.idioms': Colors.brown,
      'GameType.jumpGame': Colors.lightGreen,
      'GameType.archery': Colors.deepOrange,
      'GameType.numberSum': Colors.lime,
      'GameType.escapeRoom': Colors.blueGrey,
      'GameType.avoidDog': Colors.yellow,
      'GameType.colorSwitch': Colors.deepPurple,
      'GameType.koreanWordle': Colors.lightBlue,
      'GameType.oddOneOut': Colors.redAccent,
    };
    return colorMap[gameType] ?? Colors.grey;
  }
}
