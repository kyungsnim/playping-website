import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/game_stats.dart';
import '../providers/game_stats_provider.dart';
import '../widgets/stat_card.dart';

class GameStatsPage extends ConsumerWidget {
  const GameStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStats = ref.watch(gameStatsProvider);
    final gameTypeStats = ref.watch(gameTypeStatsProvider);
    final dailyGames = ref.watch(dailyGamesProvider(30));
    final hourlyGames = ref.watch(hourlyGamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 통계'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(gameStatsProvider);
              ref.invalidate(gameTypeStatsProvider);
              ref.invalidate(dailyGamesProvider(30));
              ref.invalidate(hourlyGamesProvider);
            },
            tooltip: '새로고침',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Stats Overview
            Text(
              '게임 현황',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            gameStats.when(
              data: (stats) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  StatCard(
                    title: '전체 방',
                    value: _formatNumber(stats.totalGamesPlayed),
                    icon: Icons.games,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: '오늘',
                    value: _formatNumber(stats.todayGamesPlayed),
                    icon: Icons.today,
                    color: Colors.green,
                  ),
                  StatCard(
                    title: '이번 주',
                    value: _formatNumber(stats.weekGamesPlayed),
                    icon: Icons.date_range,
                    color: Colors.orange,
                  ),
                  StatCard(
                    title: '이번 달',
                    value: _formatNumber(stats.monthGamesPlayed),
                    icon: Icons.calendar_month,
                    color: Colors.purple,
                  ),
                  StatCard(
                    title: '활성 방',
                    value: stats.activeRooms.toString(),
                    icon: Icons.meeting_room,
                    color: Colors.teal,
                  ),
                  StatCard(
                    title: '평균 플레이어/게임',
                    value: stats.avgPlayersPerGame.toStringAsFixed(1),
                    icon: Icons.people,
                    color: Colors.indigo,
                  ),
                  StatCard(
                    title: '싱글 모드 (100)',
                    value: '${stats.singleModeRooms}',
                    icon: Icons.looks_one,
                    color: Colors.cyan,
                  ),
                  StatCard(
                    title: '멀티 모드 (100)',
                    value: '${stats.multiModeRooms}',
                    icon: Icons.format_list_numbered,
                    color: Colors.deepOrange,
                  ),
                  StatCard(
                    title: '개별 게임 (100)',
                    value: '${stats.totalIndividualGames}',
                    icon: Icons.sports_esports,
                    color: Colors.pink,
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorWidget(
                context,
                error.toString(),
                () => ref.invalidate(gameStatsProvider),
              ),
            ),

            const SizedBox(height: 32),

            // Daily Games Chart
            Text(
              '일별 게임 (최근 30일)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            dailyGames.when(
              data: (data) => SizedBox(
                height: 300,
                child: _buildDailyGamesChart(context, data),
              ),
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => _buildErrorWidget(
                context,
                error.toString(),
                () => ref.invalidate(dailyGamesProvider(30)),
              ),
            ),

            const SizedBox(height: 32),

            // Game Type Distribution & Hourly Distribution
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game Type Distribution
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '게임 유형별 분포',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      gameTypeStats.when(
                        data: (data) => _buildGameTypeSection(context, data),
                        loading: () => const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => _buildErrorWidget(
                          context,
                          error.toString(),
                          () => ref.invalidate(gameTypeStatsProvider),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Hourly Distribution
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 시간대별 분포',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      hourlyGames.when(
                        data: (data) => _buildHourlyChart(context, data),
                        loading: () => const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => _buildErrorWidget(
                          context,
                          error.toString(),
                          () => ref.invalidate(hourlyGamesProvider),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGamesChart(BuildContext context, List<DailyGameData> data) {
    if (data.isEmpty) {
      return const Card(
        child: Center(child: Text('데이터가 없습니다')),
      );
    }

    final maxY = data.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final adjustedMaxY = (maxY * 1.2).ceilToDouble();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: adjustedMaxY > 0 ? adjustedMaxY / 5 : 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (data.length / 7).ceil().toDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MM/dd').format(data[index].date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: adjustedMaxY > 0 ? adjustedMaxY / 5 : 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
                left: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            minX: 0,
            maxX: (data.length - 1).toDouble(),
            minY: 0,
            maxY: adjustedMaxY > 0 ? adjustedMaxY : 10,
            lineBarsData: [
              LineChartBarData(
                spots: data.asMap().entries.map((entry) {
                  return FlSpot(
                      entry.key.toDouble(), entry.value.count.toDouble());
                }).toList(),
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.green.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameTypeSection(
      BuildContext context, List<GameTypeStats> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('데이터가 없습니다')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Pie Chart
            Expanded(
              child: SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: data.take(8).toList().asMap().entries.map((entry) {
                      return PieChartSectionData(
                        value: entry.value.playCount.toDouble(),
                        title:
                            '${entry.value.percentage.toStringAsFixed(0)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        color: _getColorForIndex(entry.key),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data
                    .take(10)
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getColorForIndex(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.value.displayName,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${entry.value.playCount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyChart(BuildContext context, List<HourlyGameData> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('데이터가 없습니다')),
        ),
      );
    }

    final maxY = data.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY > 0 ? maxY * 1.2 : 10,
              barGroups: data.map((item) {
                return BarChartGroupData(
                  x: item.hour,
                  barRods: [
                    BarChartRodData(
                      toY: item.count.toDouble(),
                      color: Theme.of(context).colorScheme.primary,
                      width: 8,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 4,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${value.toInt()}h',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
      BuildContext context, String error, VoidCallback onRetry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('오류: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
    ];
    return colors[index % colors.length];
  }
}
