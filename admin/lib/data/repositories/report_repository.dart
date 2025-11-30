import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants.dart';
import '../models/report_model.dart';

/// Repository for managing reports in Firestore
class ReportRepository {
  final FirebaseFirestore _firestore;

  ReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection(AdminConstants.reportsCollection);

  /// Get report statistics
  Future<ReportStats> getReportStats() async {
    final totalSnapshot = await _reportsCollection.count().get();

    final pendingSnapshot = await _reportsCollection
        .where(AdminConstants.reportStatus,
            isEqualTo: AdminConstants.reportStatusPending)
        .count()
        .get();

    final reviewedSnapshot = await _reportsCollection
        .where(AdminConstants.reportStatus,
            isEqualTo: AdminConstants.reportStatusReviewed)
        .count()
        .get();

    final dismissedSnapshot = await _reportsCollection
        .where(AdminConstants.reportStatus,
            isEqualTo: AdminConstants.reportStatusDismissed)
        .count()
        .get();

    return ReportStats(
      totalReports: totalSnapshot.count ?? 0,
      pendingReports: pendingSnapshot.count ?? 0,
      reviewedReports: reviewedSnapshot.count ?? 0,
      dismissedReports: dismissedSnapshot.count ?? 0,
    );
  }

  /// Get reports with optional status filter
  Future<List<ReportModel>> getReports({
    ReportStatus? status,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _reportsCollection
        .orderBy(AdminConstants.reportCreatedAt, descending: true);

    if (status != null) {
      String statusString;
      switch (status) {
        case ReportStatus.pending:
          statusString = AdminConstants.reportStatusPending;
          break;
        case ReportStatus.reviewed:
          statusString = AdminConstants.reportStatusReviewed;
          break;
        case ReportStatus.dismissed:
          statusString = AdminConstants.reportStatusDismissed;
          break;
      }
      query = query.where(AdminConstants.reportStatus, isEqualTo: statusString);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(limit).get();

    return snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
  }

  /// Get pending reports (for quick access)
  Future<List<ReportModel>> getPendingReports({int limit = 20}) async {
    return getReports(status: ReportStatus.pending, limit: limit);
  }

  /// Update report status
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    required String reviewedBy,
    String? action,
  }) async {
    String statusString;
    switch (newStatus) {
      case ReportStatus.pending:
        statusString = AdminConstants.reportStatusPending;
        break;
      case ReportStatus.reviewed:
        statusString = AdminConstants.reportStatusReviewed;
        break;
      case ReportStatus.dismissed:
        statusString = AdminConstants.reportStatusDismissed;
        break;
    }

    await _reportsCollection.doc(reportId).update({
      AdminConstants.reportStatus: statusString,
      AdminConstants.reportReviewedAt: FieldValue.serverTimestamp(),
      AdminConstants.reportReviewedBy: reviewedBy,
      if (action != null) AdminConstants.reportAction: action,
    });
  }

  /// Get report by ID
  Future<ReportModel?> getReport(String reportId) async {
    final doc = await _reportsCollection.doc(reportId).get();
    if (!doc.exists) return null;
    return ReportModel.fromFirestore(doc);
  }

  /// Stream of pending reports count
  Stream<int> watchPendingReportsCount() {
    return _reportsCollection
        .where(AdminConstants.reportStatus,
            isEqualTo: AdminConstants.reportStatusPending)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
