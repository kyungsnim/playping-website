import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          // Side Navigation
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 1200,
            minExtendedWidth: 200,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIndex: _getSelectedIndex(currentPath),
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/dashboard');
                  break;
                case 1:
                  context.go('/users');
                  break;
                case 2:
                  context.go('/user-management');
                  break;
                case 3:
                  context.go('/retention');
                  break;
                case 4:
                  context.go('/games');
                  break;
                case 5:
                  context.go('/game-results');
                  break;
                case 6:
                  context.go('/reports');
                  break;
              }
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  if (MediaQuery.of(context).size.width > 1200) ...[
                    const SizedBox(height: 8),
                    Text(
                      'PlayPing Admin',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      ref.read(adminAuthProvider.notifier).signOut();
                    },
                    tooltip: '로그아웃',
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('대시보드'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('사용자 통계'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people),
                label: Text('사용자 관리'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.trending_up_outlined),
                selectedIcon: Icon(Icons.trending_up),
                label: Text('리텐션'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.games_outlined),
                selectedIcon: Icon(Icons.games),
                label: Text('게임 통계'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('게임 결과'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.report_outlined),
                selectedIcon: Icon(Icons.report),
                label: Text('신고 관리'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(child: child),
        ],
      ),
    );
  }

  int _getSelectedIndex(String path) {
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/users')) return 1;
    if (path.startsWith('/user-management')) return 2;
    if (path.startsWith('/retention')) return 3;
    if (path.startsWith('/games')) return 4;
    if (path.startsWith('/game-results')) return 5;
    if (path.startsWith('/reports')) return 6;
    return 0;
  }
}
