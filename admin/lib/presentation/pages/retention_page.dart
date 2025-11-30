import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/user_stats.dart';
import '../providers/stats_provider.dart';

class RetentionPage extends ConsumerWidget {
  const RetentionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retentionData = ref.watch(retentionDataProvider(14));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retention Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(retentionDataProvider(14)),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Cohort Retention Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track how users return to the app over time based on their signup date.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Retention Table
            retentionData.when(
              data: (data) => _buildRetentionTable(context, data),
              loading: () => const SizedBox(
                height: 400,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(retentionDataProvider(14)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Legend
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Read This Table',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildLegendItem(
                      context,
                      'D1',
                      'Users who returned 1+ days after signup',
                    ),
                    _buildLegendItem(
                      context,
                      'D3',
                      'Users who returned 3+ days after signup',
                    ),
                    _buildLegendItem(
                      context,
                      'D7',
                      'Users who returned 7+ days after signup',
                    ),
                    _buildLegendItem(
                      context,
                      'D14',
                      'Users who returned 14+ days after signup',
                    ),
                    _buildLegendItem(
                      context,
                      'D30',
                      'Users who returned 30+ days after signup',
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Color Legend',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildColorLegendItem(
                            context, _getRetentionColor(80), '80%+'),
                        _buildColorLegendItem(
                            context, _getRetentionColor(60), '60-79%'),
                        _buildColorLegendItem(
                            context, _getRetentionColor(40), '40-59%'),
                        _buildColorLegendItem(
                            context, _getRetentionColor(20), '20-39%'),
                        _buildColorLegendItem(
                            context, _getRetentionColor(10), '<20%'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionTable(BuildContext context, List<RetentionData> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No retention data available. Need at least 30 days of user data.'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
            columns: const [
              DataColumn(label: Text('Cohort Date')),
              DataColumn(label: Text('Users'), numeric: true),
              DataColumn(label: Text('D1'), numeric: true),
              DataColumn(label: Text('D3'), numeric: true),
              DataColumn(label: Text('D7'), numeric: true),
              DataColumn(label: Text('D14'), numeric: true),
              DataColumn(label: Text('D30'), numeric: true),
            ],
            rows: data
                .where((item) => item.totalUsers > 0)
                .map((item) => DataRow(
                      cells: [
                        DataCell(
                          Text(DateFormat('yyyy-MM-dd').format(item.cohortDate)),
                        ),
                        DataCell(Text(item.totalUsers.toString())),
                        DataCell(_buildRetentionCell(item.d1Retention)),
                        DataCell(_buildRetentionCell(item.d3Retention)),
                        DataCell(_buildRetentionCell(item.d7Retention)),
                        DataCell(_buildRetentionCell(item.d14Retention)),
                        DataCell(_buildRetentionCell(item.d30Retention)),
                      ],
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRetentionCell(double retention) {
    if (retention == 0) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getRetentionColor(retention),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${retention.toStringAsFixed(1)}%',
        style: TextStyle(
          color: retention >= 40 ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getRetentionColor(double retention) {
    if (retention >= 80) return Colors.green[700]!;
    if (retention >= 60) return Colors.green[400]!;
    if (retention >= 40) return Colors.orange[400]!;
    if (retention >= 20) return Colors.orange[200]!;
    return Colors.red[100]!;
  }

  Widget _buildLegendItem(BuildContext context, String label, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Text(description),
        ],
      ),
    );
  }

  Widget _buildColorLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
