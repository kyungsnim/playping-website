import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore 리전 정보
enum FirestoreRegion {
  seoul('(default)', 'Seoul (Asia)', 'KR'),
  europe('firestore-eu', 'Europe', 'EU'),
  us('firestore-us', 'US', 'US');

  final String databaseId;
  final String displayName;
  final String code;

  const FirestoreRegion(this.databaseId, this.displayName, this.code);
}

/// 현재 선택된 리전 Provider
final selectedRegionProvider = StateProvider<FirestoreRegion>((ref) {
  return FirestoreRegion.seoul;
});

/// 선택된 리전의 Firestore 인스턴스 Provider
final regionFirestoreProvider = Provider.autoDispose<FirebaseFirestore>((ref) {
  final region = ref.watch(selectedRegionProvider);
  final firestore = _getFirestoreInstance(region);
  debugPrint('🌍 regionFirestoreProvider 재생성: ${region.displayName} (${region.databaseId}) → ${firestore.databaseId}');
  return firestore;
});

/// 모든 리전의 Firestore 인스턴스 캐시
final Map<FirestoreRegion, FirebaseFirestore> _firestoreCache = {};

/// 리전별 Firestore 인스턴스 가져오기
FirebaseFirestore _getFirestoreInstance(FirestoreRegion region) {
  if (_firestoreCache.containsKey(region)) {
    return _firestoreCache[region]!;
  }

  FirebaseFirestore instance;
  if (region.databaseId == '(default)') {
    instance = FirebaseFirestore.instance;
  } else {
    instance = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: region.databaseId,
    );
  }

  _firestoreCache[region] = instance;
  return instance;
}

/// 특정 리전의 Firestore 인스턴스 가져오기 (직접 호출용)
FirebaseFirestore getFirestoreForRegion(FirestoreRegion region) {
  return _getFirestoreInstance(region);
}

/// 모든 리전 목록
final allRegionsProvider = Provider<List<FirestoreRegion>>((ref) {
  return FirestoreRegion.values.toList();
});
