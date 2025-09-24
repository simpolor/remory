import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/presentation/models/tag_model.dart';
import 'package:remory/provider/db_provider.dart';
import 'package:remory/provider/state/tag_paged_notifier.dart';
import 'package:remory/provider/state/tag_paged_state.dart';
import 'package:remory/repository/tag_repository.dart';
import 'package:remory/service/tag_service.dart';

final tagRepositoryProvider = Provider((ref) {
  final db = ref.watch(dbProvider);
  return TagRepository(db);
});

final tagServiceProvider = Provider<TagService>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return TagService(repository);
});

final tagSuggestionsProvider = FutureProvider.autoDispose.family<List<TagModel>, String>((ref, keyword) {
  final tagService = ref.watch(tagServiceProvider);
  return tagService.searchTags(keyword);
});

final tagSearchQueryProvider = StateProvider<String>((_) => '');

final tagPagedProvider = StateNotifierProvider<TagPagedNotifier, TagPagedState>((ref) {
  final service = ref.watch(tagServiceProvider);
  final searchQuery = ref.watch(tagSearchQueryProvider);
  debugPrint('[tagPagedProvider] searchQuery changed: $searchQuery');
  return TagPagedNotifier(service, searchQuery);
});

final tagDetailProvider = FutureProvider.autoDispose.family<TagModel?, int>((ref, tagId) async {
  final service = ref.watch(tagServiceProvider);
  return await service.getTagById(tagId);
});

final editTagProvider = Provider<Future<void> Function(int, String)>((ref) {
  final service = ref.watch(tagServiceProvider);
  return (int id, String name) => service.modifyTag(id: id, name: name);

});

final deleteTagProvider = Provider<Future<void> Function(int)>((ref) {
  final service = ref.watch(tagServiceProvider);
  return (int id) => service.deleteTag(id);
});