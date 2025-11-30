import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/report_model.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../widgets/stat_card.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportStats = ref.watch(reportStatsProvider);
    final reports = ref.watch(reportsProvider);
    final selectedStatus = ref.watch(selectedReportStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(reportStatsProvider);
              ref.invalidate(reportsProvider);
            },
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
            // Report Stats Overview
            Text(
              'Report Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            reportStats.when(
              data: (stats) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  StatCard(
                    title: 'Total Reports',
                    value: stats.totalReports.toString(),
                    icon: Icons.report,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: 'Pending',
                    value: stats.pendingReports.toString(),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  StatCard(
                    title: 'Reviewed',
                    value: stats.reviewedReports.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  StatCard(
                    title: 'Dismissed',
                    value: stats.dismissedReports.toString(),
                    icon: Icons.cancel,
                    color: Colors.grey,
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
                () => ref.invalidate(reportStatsProvider),
              ),
            ),

            const SizedBox(height: 32),

            // Filter Section
            Row(
              children: [
                Text(
                  'Reports',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 16),
                SegmentedButton<ReportStatus?>(
                  segments: const [
                    ButtonSegment<ReportStatus?>(
                      value: null,
                      label: Text('All'),
                    ),
                    ButtonSegment<ReportStatus?>(
                      value: ReportStatus.pending,
                      label: Text('Pending'),
                    ),
                    ButtonSegment<ReportStatus?>(
                      value: ReportStatus.reviewed,
                      label: Text('Reviewed'),
                    ),
                    ButtonSegment<ReportStatus?>(
                      value: ReportStatus.dismissed,
                      label: Text('Dismissed'),
                    ),
                  ],
                  selected: {selectedStatus},
                  onSelectionChanged: (newSelection) {
                    ref.read(selectedReportStatusProvider.notifier).state =
                        newSelection.first;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reports List
            reports.when(
              data: (reportList) => reportList.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No reports found')),
                      ),
                    )
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Reporter')),
                            DataColumn(label: Text('Reported User')),
                            DataColumn(label: Text('Reason')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: reportList
                              .map((report) => _buildReportRow(context, ref, report))
                              .toList(),
                        ),
                      ),
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
                () => ref.invalidate(reportsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildReportRow(
      BuildContext context, WidgetRef ref, ReportModel report) {
    return DataRow(
      cells: [
        DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(report.createdAt))),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(report.reporterNickname,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                report.reporterId.length > 8
                    ? '${report.reporterId.substring(0, 8)}...'
                    : report.reporterId,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(report.reportedUserNickname,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                report.reportedUserId.length > 8
                    ? '${report.reportedUserId.substring(0, 8)}...'
                    : report.reportedUserId,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        DataCell(
          Tooltip(
            message: report.description ?? report.reason,
            child: SizedBox(
              width: 150,
              child: Text(
                report.reason,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        DataCell(_buildStatusChip(report.status)),
        DataCell(
          report.status == ReportStatus.pending
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () =>
                          _showActionDialog(context, ref, report, true),
                      tooltip: 'Mark as Reviewed',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          _showActionDialog(context, ref, report, false),
                      tooltip: 'Dismiss',
                    ),
                  ],
                )
              : report.action != null
                  ? Tooltip(
                      message: 'Action: ${report.action}',
                      child: const Icon(Icons.info_outline, color: Colors.grey),
                    )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ReportStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ReportStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.pending_actions;
        break;
      case ReportStatus.reviewed:
        color = Colors.green;
        label = 'Reviewed';
        icon = Icons.check_circle;
        break;
      case ReportStatus.dismissed:
        color = Colors.grey;
        label = 'Dismissed';
        icon = Icons.cancel;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }

  void _showActionDialog(
      BuildContext context, WidgetRef ref, ReportModel report, bool isReview) {
    final actionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isReview ? 'Review Report' : 'Dismiss Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reporter: ${report.reporterNickname}'),
            Text('Reported: ${report.reportedUserNickname}'),
            Text('Reason: ${report.reason}'),
            if (report.description != null) ...[
              const SizedBox(height: 8),
              Text('Description: ${report.description}'),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: actionController,
              decoration: InputDecoration(
                labelText: isReview ? 'Action Taken' : 'Reason for Dismissal',
                hintText: isReview
                    ? 'e.g., Warning issued, Account suspended'
                    : 'e.g., Insufficient evidence, False report',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentUser = ref.read(currentUserProvider);
              final repository = ref.read(reportRepositoryProvider);

              await repository.updateReportStatus(
                reportId: report.id,
                newStatus:
                    isReview ? ReportStatus.reviewed : ReportStatus.dismissed,
                reviewedBy: currentUser?.email ?? 'admin',
                action: actionController.text.isNotEmpty
                    ? actionController.text
                    : null,
              );

              if (context.mounted) {
                Navigator.of(context).pop();
                ref.invalidate(reportStatsProvider);
                ref.invalidate(reportsProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isReview
                          ? 'Report marked as reviewed'
                          : 'Report dismissed',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isReview ? Colors.green : Colors.grey,
            ),
            child: Text(isReview ? 'Review' : 'Dismiss'),
          ),
        ],
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
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
