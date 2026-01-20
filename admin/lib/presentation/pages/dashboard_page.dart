import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/region_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/region_filter.dart';
import '../widgets/stat_card.dart';
import '../widgets/signup_chart.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    // 리전 변경 감지 시 통계 데이터 새로고침
    ref.listen<FirestoreRegion>(selectedRegionProvider, (previous, next) {
      if (previous != next) {
        debugPrint('🔄 리전 변경 감지: ${previous?.displayName} → ${next.displayName}');
        ref.invalidate(userRepositoryProvider);
        ref.invalidate(userStatsProvider);
        ref.invalidate(dailySignupsProvider(30));
      }
    });

    final userStats = ref.watch(userStatsProvider);
    final dailySignups = ref.watch(dailySignupsProvider(30));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('대시보드'),
        actions: [
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: currentUser.photoURL != null
                        ? NetworkImage(currentUser.photoURL!)
                        : null,
                    child: currentUser.photoURL == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(currentUser.email ?? ''),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(adminAuthProvider.notifier).signOut();
            },
            tooltip: '로그아웃',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userStatsProvider);
          ref.invalidate(dailySignupsProvider(30));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '환영합니다!',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '오늘의 PlayPing 현황입니다.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const RegionFilter(),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Region Info
              _buildRegionInfo(context, ref),
              const SizedBox(height: 32),

              // User Stats Cards
              userStats.when(
                data: (stats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '사용자 현황',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        StatCard(
                          title: '전체 사용자',
                          value: _formatNumber(stats.totalUsers),
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                        StatCard(
                          title: '오늘 신규',
                          value: _formatNumber(stats.todayNewUsers),
                          icon: Icons.person_add,
                          color: Colors.green,
                        ),
                        StatCard(
                          title: '이번 주',
                          value: _formatNumber(stats.weekNewUsers),
                          icon: Icons.trending_up,
                          color: Colors.orange,
                        ),
                        StatCard(
                          title: '이번 달',
                          value: _formatNumber(stats.monthNewUsers),
                          icon: Icons.calendar_month,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '활성 사용자',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        StatCard(
                          title: '오늘 활성',
                          value: _formatNumber(stats.activeToday),
                          icon: Icons.today,
                          color: Colors.teal,
                        ),
                        StatCard(
                          title: '이번 주 활성',
                          value: _formatNumber(stats.activeWeek),
                          icon: Icons.date_range,
                          color: Colors.indigo,
                        ),
                        StatCard(
                          title: '이번 달 활성',
                          value: _formatNumber(stats.activeMonth),
                          icon: Icons.calendar_today,
                          color: Colors.pink,
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('통계 로딩 오류: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(userStatsProvider),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Daily Signups Chart
              Text(
                '일별 가입자 (최근 30일)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              dailySignups.when(
                data: (data) => SizedBox(
                  height: 300,
                  child: SignupChart(data: data),
                ),
                loading: () => const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SizedBox(
                  height: 300,
                  child: Center(
                    child: Text('차트 로딩 오류: $error'),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildRegionInfo(BuildContext context, WidgetRef ref) {
    final selectedRegion = ref.watch(selectedRegionProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getRegionColor(selectedRegion).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRegionColor(selectedRegion).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: _getRegionColor(selectedRegion),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '현재 ${selectedRegion.displayName} 리전의 데이터를 보고 있습니다. '
              '다른 리전의 데이터를 보려면 오른쪽 상단 필터를 변경하세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getRegionColor(selectedRegion),
                  ),
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
