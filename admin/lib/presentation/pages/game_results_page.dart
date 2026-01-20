import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/game_result_model.dart';
import '../providers/game_results_provider.dart';
import '../providers/region_provider.dart';
import '../widgets/game_result_detail_dialog.dart';
import '../widgets/region_filter.dart';

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
    // 리전 변경 감지 시 게임 결과 새로고침
    ref.listen<FirestoreRegion>(selectedRegionProvider, (previous, next) {
      if (previous != next) {
        debugPrint('🔄 게임결과 리전 변경 감지: ${previous?.displayName} → ${next.displayName}');
        // provider를 invalidate해서 새 repository로 재생성
        ref.invalidate(gameResultRepositoryProvider);
        ref.invalidate(gameResultsProvider);
      }
    });

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
                // Region filter
                const RegionFilter(),
                const SizedBox(width: 16),
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
          // Region info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildRegionInfo(context, ref),
          ),
          const SizedBox(height: 16),
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

  Widget _buildRegionInfo(BuildContext context, WidgetRef ref) {
    final selectedRegion = ref.watch(selectedRegionProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getRegionColor(selectedRegion).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRegionColor(selectedRegion).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: _getRegionColor(selectedRegion),
          ),
          const SizedBox(width: 8),
          Text(
            '${selectedRegion.displayName} 리전의 게임 결과를 표시합니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getRegionColor(selectedRegion),
                ),
          ),
        ],
      ),
    );
  }

  Color _getRegionColor(FirestoreRegion region) {
    switch (region) {
      case FirestoreRegion.seoul:
        return Colors.blue;
      case FirestoreRegion.europe:
        return Colors.green;
      case FirestoreRegion.us:
        return Colors.orange;
    }
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
    // 'GameType.' 접두사 제거 및 snake_case를 camelCase로 변환
    String typeName = gameType.replaceFirst('GameType.', '');
    if (typeName.contains('_')) {
      final parts = typeName.split('_');
      typeName = parts.first +
          parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
    }

    final iconMap = {
      'reflexes': Icons.flash_on,
      'memory': Icons.psychology,
      'bombPassing': Icons.whatshot,
      'findDifference': Icons.compare,
      'oxQuiz': Icons.check_circle_outline,
      'landmark': Icons.location_city,
      'tileMatching': Icons.grid_view,
      'speedTyping': Icons.keyboard,
      'leftRight': Icons.swap_horiz,
      'mathSpeed': Icons.calculate,
      'idioms': Icons.menu_book,
      'jumpGame': Icons.sports_gymnastics,
      'archery': Icons.gps_fixed,
      'numberSum': Icons.numbers,
      'escapeRoom': Icons.door_front_door,
      'avoidDog': Icons.pets,
      'colorSwitch': Icons.palette,
      'koreanWordle': Icons.abc,
      'oddOneOut': Icons.search,
    };
    return iconMap[typeName] ?? Icons.games;
  }

  Color _getGameTypeColor(String gameType) {
    // 'GameType.' 접두사 제거 및 snake_case를 camelCase로 변환
    String typeName = gameType.replaceFirst('GameType.', '');
    if (typeName.contains('_')) {
      final parts = typeName.split('_');
      typeName = parts.first +
          parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
    }

    final colorMap = {
      'reflexes': Colors.orange,
      'memory': Colors.purple,
      'bombPassing': Colors.red,
      'findDifference': Colors.green,
      'oxQuiz': Colors.blue,
      'landmark': Colors.teal,
      'tileMatching': Colors.indigo,
      'speedTyping': Colors.cyan,
      'leftRight': Colors.pink,
      'mathSpeed': Colors.amber,
      'idioms': Colors.brown,
      'jumpGame': Colors.lightGreen,
      'archery': Colors.deepOrange,
      'numberSum': Colors.lime,
      'escapeRoom': Colors.blueGrey,
      'avoidDog': Colors.yellow,
      'colorSwitch': Colors.deepPurple,
      'koreanWordle': Colors.lightBlue,
      'oddOneOut': Colors.redAccent,
    };
    return colorMap[typeName] ?? Colors.grey;
  }
}
