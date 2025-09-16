import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';
import 'package:remory/presentation/layouts/fab_config.dart';
import 'package:remory/routers/router_provider.dart';

class AppScaffold extends ConsumerWidget {
  final AppBarConfig appBar;
  final Widget child;
  final FabConfig? fab;
  final bool showBottomNav;

  const AppScaffold({
    required this.appBar,
    required this.child,
    this.fab,
    this.showBottomNav = true,
    super.key
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final shell = ref.watch(navigationShellProvider);

    return Scaffold(
      appBar: AppBar(
        leading: appBar.showBackButton
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ) : null,
        title: Text(appBar.title),
        actions: appBar.actions,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
      bottomNavigationBar: showBottomNav == false ? null : BottomNavigationBar(
        //currentIndex: _calculateSelectedIndex(context),
        currentIndex: shell?.currentIndex ?? _calculateSelectedIndex(context),

        // 아이템 폭 고정 (선택돼도 안 넓어짐)
        type: BottomNavigationBarType.fixed,

        // 라벨 폰트크기까지 0으로 고정하면 더 확실
        selectedFontSize: 0,
        unselectedFontSize: 0,

        // 아이콘 크기 동일하게 고정 (선택시 커지는 것 방지)
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 24),

        // 아이콘 색상
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,

        // 라벨 숨김 여부
        showSelectedLabels: false,
        showUnselectedLabels: false,

        onTap: (index) {
          /*switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/tags');
              break;
            case 2:
              context.go('/analytics');
              break;
            case 3:
              context.go('/settings');
              break;*/

          if (shell != null) {
            shell.goBranch(index, initialLocation: false); // ✅ 탭 스택/상태 유지
          } else {
            switch (index) {
              case 0: context.go('/'); break;
              case 1: context.go('/tags'); break;
              case 2: context.go('/analytics'); break;
              case 3: context.go('/settings'); break;
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timeline), label: '타임라인'),
          BottomNavigationBarItem(icon: Icon(Icons.tag), label: '태그'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: '통계'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
      floatingActionButton: fab == null ? null : FloatingActionButton(
        tooltip: fab!.tooltip,
        onPressed: () => context.push(fab!.route),
        child: Icon(fab!.icon),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/tags')) return 1;
    if (location.startsWith('/analytics')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0; // 기본값: 타임라인
  }
}
