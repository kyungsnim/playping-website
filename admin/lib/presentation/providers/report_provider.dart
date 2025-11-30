import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/report_model.dart';
import '../../data/repositories/report_repository.dart';

/// Provider for ReportRepository
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

/// Provider for report statistics
final reportStatsProvider = FutureProvider<ReportStats>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getReportStats();
});

/// Selected report status filter
final selectedReportStatusProvider = StateProvider<ReportStatus?>((ref) => null);

/// Provider for filtered reports
final reportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  final status = ref.watch(selectedReportStatusProvider);
  return repository.getReports(status: status, limit: 100);
});

/// Provider for pending reports
final pendingReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getPendingReports(limit: 50);
});

/// Provider for pending reports count (stream)
final pendingReportsCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.watchPendingReportsCount();
});
