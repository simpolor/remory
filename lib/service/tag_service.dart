import 'package:remory/presentation/models/tag_model.dart';
import 'package:remory/presentation/models/tag_with_count_model.dart';
import 'package:remory/provider/state/tag_cursor.dart';
import 'package:remory/repository/dtos/tag_dto.dart';
import 'package:remory/repository/tag_repository.dart';

class TagService {

  final TagRepository tagRepository;

  TagService(this.tagRepository);

  Future<List<TagModel>> searchTags(String keyword) async {
    final dtoList = await tagRepository.searchTagsByName(keyword);

    return dtoList.map(TagModel.fromDto).toList();
  }

  Future<List<TagWithCountModel>> getTagsAfter({
    TagCursor? tagCursor, 
    required int limit,
    String? searchQuery,
  }) async {
    final tagList = await tagRepository.fetchTagsWithAfter(
      tagCursor: tagCursor, 
      limit: limit,
      searchQuery: searchQuery,
    );
    if (tagList.isEmpty) return [];

    return tagList.map(TagWithCountModel.fromDto).toList();
  }

  Future<TagModel?> getTagById(int tagId) async {
    final tagDto = await tagRepository.findTagById(tagId);
    if (tagDto == null) return null;

    return TagModel.fromDto(tagDto);
  }

  Future<void> modifyTag({
    required int id,
    required String name,
  }) async {
    final dto = await tagRepository.findTagById(id);
    if (dto == null) return;

    final existingTag = await tagRepository.findTagByName(name);
    if (existingTag != null) {
      throw Exception('이미 존재하는 태그명입니다.');
    }

    final updatedDto = TagDto(
      tagId: id,  // id를 직접 사용
      name: name,
      usageCount: dto.usageCount,
      lastUsedAt: DateTime.now(),
      createdAt: dto.createdAt,
      updatedAt: DateTime.now(),
    );

    await tagRepository.updateTag(updatedDto);
  }

  Future<void> deleteTag(int id) async {
    await tagRepository.deleteTag(id);
  }
}