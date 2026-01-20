import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/user_stats.dart';
import '../../data/repositories/user_repository.dart';
import '../providers/region_provider.dart';
import '../widgets/region_filter.dart';

/// 사용자 관리 페이지 (무한 스크롤)
class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  late UserRepository _userRepository;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  FirestoreRegion? _currentRegion;

  final List<UserModel> _users = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 초기 로드는 didChangeDependencies에서 수행
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final selectedRegion = ref.read(selectedRegionProvider);
    if (_currentRegion != selectedRegion) {
      _currentRegion = selectedRegion;
      final firestore = ref.read(regionFirestoreProvider);
      _userRepository = UserRepository(firestore: firestore);
      _loadUsers();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore &&
        !_isSearching) {
      _loadMore();
    }
  }

  Future<void> _loadUsers() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _userRepository.getRecentUsers(limit: 10);
      setState(() {
        _users.clear();
        _users.addAll(result.users);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _userRepository.getRecentUsers(
        limit: 10,
        startAfter: _lastDocument,
      );
      setState(() {
        _users.addAll(result.users);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      _loadUsers();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _userRepository.searchUsers(query);
      setState(() {
        _users.clear();
        _users.addAll(results);
        _hasMore = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showUserDetail(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailDialog(
        user: user,
        userRepository: _userRepository,
        onUserUpdated: _loadUsers,
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

  @override
  Widget build(BuildContext context) {
    // 리전 변경 감지
    ref.listen<FirestoreRegion>(selectedRegionProvider, (previous, next) {
      if (previous != next) {
        _currentRegion = next;
        final firestore = ref.read(regionFirestoreProvider);
        _userRepository = UserRepository(firestore: firestore);
        _searchController.clear();
        _loadUsers();
      }
    });

    final selectedRegion = ref.watch(selectedRegionProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '사용자 관리',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '가입된 사용자를 조회하고 관리합니다',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                const RegionFilter(),
              ],
            ),
          ),

          // 리전 안내
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
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
                    '${selectedRegion.displayName} 리전의 사용자를 표시합니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getRegionColor(selectedRegion),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 검색창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '닉네임 또는 이메일로 검색...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchUsers('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      if (value.length >= 2 || value.isEmpty) {
                        _searchUsers(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _searchController.clear();
                    _loadUsers();
                  },
                  tooltip: '새로고침',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 사용자 수
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _isSearching
                  ? '검색 결과: ${_users.length}명'
                  : '${_users.length}명 표시 중',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),

          const SizedBox(height: 16),

          // 사용자 목록
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('오류: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                : _users.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching
                                  ? '검색 결과가 없습니다'
                                  : '사용자가 없습니다',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _users.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _users.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final user = _users[index];
                          return _UserListTile(
                            user: user,
                            onTap: () => _showUserDetail(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserListTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getProviderColor(user.provider),
          child: Text(
            user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.nickname,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getProviderColor(user.provider).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.displayProvider,
                style: TextStyle(
                  fontSize: 12,
                  color: _getProviderColor(user.provider),
                ),
              ),
            ),
            if (user.isAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '관리자',
                  style: TextStyle(fontSize: 12, color: Colors.purple),
                ),
              ),
            ],
            if (user.adsRemoved) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '광고제거',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
            ],
            if (user.isBlocked) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '차단됨',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${user.coins}',
                    style: const TextStyle(fontSize: 12, color: Colors.amber),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.email != null && user.email!.isNotEmpty)
              Text(
                user.email!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.location,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  user.createdAt != null
                      ? '가입: ${dateFormat.format(user.createdAt!)}'
                      : '가입일 알 수 없음',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: onTap,
        ),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }

  Color _getProviderColor(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'google.com':
      case 'google':
        return Colors.red;
      case 'apple.com':
      case 'apple':
        return Colors.black;
      case 'kakao':
        return Colors.yellow[700]!;
      case 'anonymous':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

class UserDetailDialog extends StatefulWidget {
  final UserModel user;
  final UserRepository userRepository;
  final VoidCallback onUserUpdated;

  const UserDetailDialog({
    super.key,
    required this.user,
    required this.userRepository,
    required this.onUserUpdated,
  });

  @override
  State<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<UserDetailDialog> {
  late UserRepository _userRepository;
  late UserModel _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _userRepository = widget.userRepository;
  }

  Future<void> _refreshUser() async {
    final updatedUser = await _userRepository.getUserById(_user.id);
    if (updatedUser != null) {
      setState(() {
        _user = updatedUser;
      });
      widget.onUserUpdated();
    }
  }

  Future<void> _showAddCoinsDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('코인 추가'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '수량',
            hintText: '추가할 코인 수량 입력',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context, amount);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        await _userRepository.addCoins(_user.id, result);
        await _refreshUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$result 코인 추가됨')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e')),
          );
        }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAdsRemoved() async {
    setState(() => _isLoading = true);
    try {
      await _userRepository.toggleAdsRemoved(_user.id, !_user.adsRemoved);
      await _refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_user.adsRemoved ? '광고 제거됨' : '광고 활성화됨'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleAdmin() async {
    setState(() => _isLoading = true);
    try {
      await _userRepository.toggleAdmin(_user.id, !_user.isAdmin);
      await _refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_user.isAdmin ? '관리자 권한 부여됨' : '관리자 권한 해제됨'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleBlocked() async {
    setState(() => _isLoading = true);
    try {
      await _userRepository.toggleBlocked(_user.id, !_user.isBlocked);
      await _refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_user.isBlocked ? '사용자 차단됨' : '차단 해제됨'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 스크롤 가능한 내용
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue,
                          child: Text(
                            _user.nickname.isNotEmpty
                                ? _user.nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _user.nickname,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_user.isAdmin) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '관리자',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                _user.displayProvider,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 사용자 상세 정보
                    _buildDetailRow('사용자 ID', _user.id),
                    if (_user.email != null && _user.email!.isNotEmpty)
                      _buildDetailRow('이메일', _user.email!),
                    _buildDetailRow('로그인 방식', _user.displayProvider),
                    _buildDetailRow('위치', _user.location),
                    _buildDetailRow(
                      '가입일',
                      _user.createdAt != null
                          ? dateFormat.format(_user.createdAt!)
                          : '알 수 없음',
                    ),
                    _buildDetailRow(
                      '최근 로그인',
                      _user.lastLoginAt != null
                          ? dateFormat.format(_user.lastLoginAt!)
                          : '알 수 없음',
                    ),
                    _buildDetailRow('플레이한 게임 수', _user.gamesPlayed.toString()),
                    _buildDetailRow('보유 코인', _user.coins.toString()),
                    _buildDetailRow('광고 제거', _user.adsRemoved ? '예' : '아니오'),
                    _buildDetailRow('관리자', _user.isAdmin ? '예' : '아니오'),
                    _buildDetailRow('상태', _user.isBlocked ? '차단됨' : '활성'),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 액션 버튼
                    const Text(
                      '관리 기능',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _showAddCoinsDialog,
                          icon: const Icon(Icons.monetization_on),
                          label: const Text('코인 추가'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _toggleAdsRemoved,
                          icon: Icon(_user.adsRemoved ? Icons.ads_click : Icons.block),
                          label: Text(_user.adsRemoved ? '광고 활성화' : '광고 제거'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _user.adsRemoved ? Colors.grey : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _toggleAdmin,
                          icon: Icon(
                            _user.isAdmin
                                ? Icons.remove_moderator
                                : Icons.admin_panel_settings,
                          ),
                          label: Text(_user.isAdmin ? '관리자 해제' : '관리자 부여'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _user.isAdmin ? Colors.grey : Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _toggleBlocked,
                          icon: Icon(_user.isBlocked ? Icons.lock_open : Icons.block),
                          label: Text(_user.isBlocked ? '차단 해제' : '사용자 차단'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _user.isBlocked ? Colors.orange : Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 닫기 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('닫기'),
                        ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
