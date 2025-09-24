import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/core/error_handler.dart';

// 개발용 에러 로그 뷰어
class DebugScreen extends HookConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorLogs = useState<List<AppError>>([]);

    useEffect(() {
      void onError(AppError error) {
        errorLogs.value = [...errorLogs.value, error];
      }

      ErrorHandler().addListener(onError);
      return () => ErrorHandler().removeListener(onError);
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              errorLogs.value = [];
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              // 테스트 에러 발생
              try {
                throw Exception('Test error for debugging');
              } catch (e, stackTrace) {
                ErrorHandler().handleError(
                  e,
                  stackTrace: stackTrace,
                  type: ErrorType.unknown,
                  context: 'Debug Test',
                );
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: errorLogs.value.length,
        itemBuilder: (context, index) {
          final error = errorLogs.value.reversed.toList()[index];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: Icon(
                _getErrorIcon(error.type),
                color: _getErrorColor(error.type),
              ),
              title: Text(
                error.message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${error.type.name.toUpperCase()} • ${_formatTime(error.timestamp)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error.code != null) ...[
                        _buildInfoRow('Code', error.code!),
                        const SizedBox(height: 8),
                      ],
                      if (error.context != null) ...[
                        _buildInfoRow('Context', error.context.toString()),
                        const SizedBox(height: 8),
                      ],
                      if (error.originalError != null) ...[
                        _buildInfoRow('Original Error', error.originalError.toString()),
                        const SizedBox(height: 8),
                      ],
                      if (error.stackTrace != null) ...[
                        const Text(
                          'Stack Trace:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            error.stackTrace.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showErrorTypeTest(context);
        },
        label: const Text('Test Errors'),
        icon: const Icon(Icons.science),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  void _showErrorTypeTest(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Error Type Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ErrorType.values.map((type) => ListTile(
              leading: Icon(_getErrorIcon(type)),
              title: Text(type.name.toUpperCase()),
              onTap: () {
                Navigator.pop(context);
                _triggerTestError(type);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _triggerTestError(ErrorType type) {
    try {
      switch (type) {
        case ErrorType.database:
          throw Exception('Database connection failed');
        case ErrorType.network:
          throw Exception('Network timeout');
        case ErrorType.permission:
          throw Exception('Permission denied');
        case ErrorType.fileSystem:
          throw Exception('File not found');
        case ErrorType.unknown:
          throw Exception('Unknown error occurred');
      }
    } catch (e, stackTrace) {
      ErrorHandler().handleError(
        e,
        stackTrace: stackTrace,
        type: type,
        context: 'Debug Test - ${type.name}',
        additionalData: {
          'test_mode': true,
          'error_type': type.name,
        },
      );
    }
  }
}
