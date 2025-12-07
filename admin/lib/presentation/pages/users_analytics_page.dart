import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_stats.dart';
import '../providers/stats_provider.dart';

class UsersAnalyticsPage extends ConsumerWidget {
  const UsersAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryStats = ref.watch(countryStatsProvider);
    final providerStats = ref.watch(providerStatsProvider);
    final selectedCountry = ref.watch(selectedCountryProvider);
    final regionStats = ref.watch(regionStatsProvider(selectedCountry));

    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 통계'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(countryStatsProvider);
              ref.invalidate(providerStatsProvider);
              ref.invalidate(regionStatsProvider(selectedCountry));
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
            // Country Stats Section
            Text(
              '국가별 사용자',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            countryStats.when(
              data: (data) => _buildCountrySection(context, ref, data),
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => _buildErrorWidget(
                context,
                error.toString(),
                () => ref.invalidate(countryStatsProvider),
              ),
            ),

            const SizedBox(height: 32),

            // Region Stats Section
            Row(
              children: [
                Text(
                  '지역별 사용자',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 16),
                countryStats.when(
                  data: (countries) => DropdownButton<String?>(
                    value: selectedCountry,
                    hint: const Text('전체 국가'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('전체 국가'),
                      ),
                      ...countries.map((c) => DropdownMenuItem<String?>(
                            value: c.countryCode,
                            child: Text(c.countryName),
                          )),
                    ],
                    onChanged: (value) {
                      ref.read(selectedCountryProvider.notifier).state = value;
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            regionStats.when(
              data: (data) => _buildRegionSection(context, data),
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => _buildErrorWidget(
                context,
                error.toString(),
                () => ref.invalidate(regionStatsProvider(selectedCountry)),
              ),
            ),

            const SizedBox(height: 32),

            // Auth Provider Stats Section
            Text(
              '로그인 방식별 사용자',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            providerStats.when(
              data: (data) => _buildProviderSection(context, data),
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => _buildErrorWidget(
                context,
                error.toString(),
                () => ref.invalidate(providerStatsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySection(
      BuildContext context, WidgetRef ref, List<CountryStats> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('데이터가 없습니다')),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pie Chart
        Expanded(
          flex: 2,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: data.take(10).map((item) {
                      return PieChartSectionData(
                        value: item.userCount.toDouble(),
                        title:
                            '${item.countryCode}\n${item.percentage.toStringAsFixed(1)}%',
                        radius: 100,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        color: _getColorForIndex(data.indexOf(item)),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Data Table
        Expanded(
          flex: 3,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('국가')),
                  DataColumn(label: Text('사용자'), numeric: true),
                  DataColumn(label: Text('%'), numeric: true),
                ],
                rows: data
                    .map((item) => DataRow(
                          cells: [
                            DataCell(
                              InkWell(
                                onTap: () {
                                  ref.read(selectedCountryProvider.notifier).state =
                                      item.countryCode;
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color:
                                            _getColorForIndex(data.indexOf(item)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(item.countryName),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(Text(item.userCount.toString())),
                            DataCell(
                                Text('${item.percentage.toStringAsFixed(1)}%')),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegionSection(BuildContext context, List<RegionStats> data) {
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
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.first.userCount * 1.2,
                  barGroups: data.take(10).toList().asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.userCount.toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final region = data[index].region;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: RotatedBox(
                              quarterTurns: -1,
                              child: Text(
                                region.length > 15
                                    ? '${region.substring(0, 12)}...'
                                    : region,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data
                  .map((item) => Chip(
                        label: Text(
                          '${item.region}: ${item.userCount}명 (${item.percentage.toStringAsFixed(1)}%)',
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSection(BuildContext context, List<ProviderStats> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('데이터가 없습니다')),
        ),
      );
    }

    final colors = {
      'Google': Colors.red,
      'Apple': Colors.black,
      'Kakao': Colors.yellow[700]!,
      'Anonymous': Colors.grey,
    };

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
                    sections: data.map((item) {
                      final color =
                          colors[item.provider] ?? _getColorForIndex(data.indexOf(item));
                      return PieChartSectionData(
                        value: item.userCount.toDouble(),
                        title:
                            '${item.provider}\n${item.percentage.toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.provider == 'Apple' ? Colors.white : Colors.white,
                        ),
                        color: color,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 32),
            // Legend
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: colors[item.provider] ??
                                      _getColorForIndex(data.indexOf(item)),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.provider,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '${item.userCount}명',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${item.percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
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
