import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/core/error_handler.dart';
import 'package:remory/provider/error_provider.dart';

/// 글로벌 에러를 스낵바로 표시하는 위젯
class ErrorSnackBarListener extends HookConsumerWidget {
  final Widget child;

  const ErrorSnackBarListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(errorNotificationProvider);

    // 에러 상태 변화 감지
    ref.listen<AppError?>(
      errorNotificationProvider,
      (previous, next) {
        if (next != null) {
          _showErrorSnackBar(context, next, ref);
        }
      },
    );

    return child;
  }

  void _showErrorSnackBar(BuildContext context, AppError error, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    final message = ErrorHandler().getUserMessage(error);

    // 기존 스낵바 제거
    messenger.removeCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.type),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {
            ref.read(errorNotificationProvider.notifier).clearError();
          },
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    // 자동으로 에러 상태 클리어
    Future.delayed(const Duration(seconds: 4), () {
      ref.read(errorNotificationProvider.notifier).clearError();
    });
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.database:
        return Icons.storage;
      case ErrorType.permission:
        return Icons.lock;
      case ErrorType.fileSystem:
        return Icons.folder_off;
      case ErrorType.unknown:
      default:
        return Icons.error;
    }
  }

  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.database:
        return Colors.red;
      case ErrorType.permission:
        return Colors.amber;
      case ErrorType.fileSystem:
        return Colors.deepOrange;
      case ErrorType.unknown:
      default:
        return Colors.red.shade400;
    }
  }
}
