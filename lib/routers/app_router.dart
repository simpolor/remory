import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remory/presentation/analytics_screen.dart';

import 'package:remory/presentation/memo_add_screen.dart';
import 'package:remory/presentation/memo_detail_screen.dart';
import 'package:remory/presentation/memo_list_screen.dart';
import 'package:remory/presentation/setting_backup_screen.dart';
import 'package:remory/presentation/setting_contact_screen.dart';
import 'package:remory/presentation/setting_notification_screen.dart';
import 'package:remory/presentation/setting_privacy_policy_screen.dart';
import 'package:remory/presentation/setting_screen.dart';
import 'package:remory/presentation/tag_detail_screen.dart';
import 'package:remory/presentation/tag_list_screen.dart';
import 'package:remory/presentation/trash_screen.dart';
import 'package:remory/routers/router_extensions.dart';
import 'package:remory/routers/router_provider.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // child 트리 전체에 navigationShell을 주입
        return ProviderScope(
          overrides: [
            navigationShellProvider.overrideWithValue(navigationShell),
          ],
          child: navigationShell, // 각 스크린은 기존처럼 AppScaffold 사용 가능
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
              const NoTransitionPage(child: MemoListScreen()),
            ),
            GoRoute(
              path: '/memos/add',
              pageBuilder: (context, state) =>
              const NoTransitionPage(child: MemoAddScreen()),
            ),
            GoRoute(
                path: '/memos/:id(\\d+)',
                pageBuilder: (context, state) {
                  final memoId = state.getIntParamOrGoBack(context, 'id');
                  return NoTransitionPage(child: MemoDetailScreen(memoId: memoId));
                }
            ),
            // 🗑️ 휴지통 화면 추가
            GoRoute(
              path: '/trash',
              pageBuilder: (context, state) =>
              const NoTransitionPage(child: TrashScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tags',
              pageBuilder: (context, state) =>
              const NoTransitionPage(child: TagListScreen()),
            ),
            GoRoute(
                path: '/tags/:id(\\d+)',
                pageBuilder: (context, state) {
                  final tagId = state.getIntParamOrGoBack(context, 'id');
                  return NoTransitionPage(child: TagDetailScreen(tagId: tagId));
                }
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              pageBuilder: (context, state) =>
              const NoTransitionPage(child: AnalyticsScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingScreen()),
            ),
            GoRoute(
              path: '/settings/notifications',
              pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingNotificationScreen()),
            ),
            GoRoute(
              path: '/settings/backup',
              pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingBackupScreen()),
            ),
            GoRoute(
              path: '/settings/privacy_policy',
              pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingPrivacyPolicyScreen()),
            ),
            GoRoute(
              path: '/settings/contact',
              pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingContactScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);


