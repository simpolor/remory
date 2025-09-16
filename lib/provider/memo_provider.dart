import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/presentation/models/memo_with_tags_model.dart';
import 'package:remory/provider/db_provider.dart';
import 'package:remory/provider/memo_tag_provider.dart';
import 'package:remory/provider/state/memo_paged_notifier.dart';
import 'package:remory/provider/state/memo_paged_state.dart';
import 'package:remory/provider/tag_provider.dart';
import 'package:remory/repository/memo_repository.dart';
import 'package:remory/service/memo_service.dart';

final memoRepositoryProvider = Provider((ref) {
  final db = ref.watch(dbProvider);
  return MemoRepository(db);
});

final memoServiceProvider = Provider((ref) {
  final db = ref.watch(dbProvider);
  final memoRepository = ref.watch(memoRepositoryProvider);
  final tagRepository = ref.watch(tagRepositoryProvider);
  final memoTagRepository = ref.watch(memoTagRepositoryProvider);
  return MemoService(db, memoRepository, tagRepository, memoTagRepository);
});

final memoPagedProvider = StateNotifierProvider<MemoPagedNotifier, MemoPagedState>((ref) {
  final service = ref.watch(memoServiceProvider);
  return MemoPagedNotifier(service);
});


// FutureProvider<T>: “값을 가져와서 화면에 보여줄 때”
// FutureProvider 팩토리에서 async는 옵션이에요.
// StreamProvider도 마찬가지로 async*는 옵션이고, 그냥 Stream만 반환하면 됩니다.
/*final memoDetailProvider = FutureProvider.autoDispose.family<MemoModel?, int>((ref, memoId) async {
  final service = ref.watch(memoServiceProvider);
  return await service.getMemoById(memoId);
});*/

final memoDetailProvider = FutureProvider.autoDispose.family<MemoWithTagsModel?, int>((ref, memoId) async {
  final service = ref.watch(memoServiceProvider);
  return await service.getMemoWithTagsById(memoId);
});

// Provider<U>: “함수를 주입해서 내가 원할 때 호출할 때”
// Provider 팩토리에는 async를 붙일 필요가 전혀 없습니다. 이 프로바이더는 “함수 하나를 동기적으로 반환”하고, 그 함수가 호출될 때 Future를 반환하면 됩니다.
// “원할 때만 실행할 액션(쓰기)” → 함수 반환 Provider (호출 시 비동기)
final addMemoProvider = Provider<Future<void> Function(String, List<String>)>((ref) {
  final service = ref.read(memoServiceProvider);

  return (String title, List<String> tagNames) => service.registerMemoWithTags(title, tagNames);
});

final editMemoProvider = Provider<Future<void> Function(int, String, List<String>)>((ref) {
  final service = ref.read(memoServiceProvider);

  return (int id, String title, List<String> tagNames) => service.modifyMemoWithTags(id, title, tagNames);
});

final deleteMemoProvider = Provider<Future<void> Function(int)>((ref) {
  final service = ref.read(memoServiceProvider);

  return (int id) => service.deleteMemoWithTags(id);
});
