/// Report data model for admin dashboard
library;

import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { pending, reviewed, dismissed }

class ReportModel {
  final String id;
  final String reporterId;
  final String reporterNickname;
  final String reportedUserId;
  final String reportedUserNickname;
  final String reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? action;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterNickname,
    required this.reportedUserId,
    required this.reportedUserNickname,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.action,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reporterNickname: data['reporterNickname'] ?? 'Unknown',
      reportedUserId: data['reportedUserId'] ?? '',
      reportedUserNickname: data['reportedUserNickname'] ?? 'Unknown',
      reason: data['reason'] ?? '',
      description: data['description'],
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      action: data['action'],
    );
  }

  static ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }

  String get statusString {
    switch (status) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.reviewed:
        return 'reviewed';
      case ReportStatus.dismissed:
        return 'dismissed';
    }
  }

  ReportModel copyWith({
    ReportStatus? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? action,
  }) {
    return ReportModel(
      id: id,
      reporterId: reporterId,
      reporterNickname: reporterNickname,
      reportedUserId: reportedUserId,
      reportedUserNickname: reportedUserNickname,
      reason: reason,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      action: action ?? this.action,
    );
  }
}

class ReportStats {
  final int totalReports;
  final int pendingReports;
  final int reviewedReports;
  final int dismissedReports;

  const ReportStats({
    required this.totalReports,
    required this.pendingReports,
    required this.reviewedReports,
    required this.dismissedReports,
  });

  factory ReportStats.empty() => const ReportStats(
        totalReports: 0,
        pendingReports: 0,
        reviewedReports: 0,
        dismissedReports: 0,
      );
}
