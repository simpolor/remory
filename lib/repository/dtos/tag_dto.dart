import 'package:remory/data/app_database.dart';

class TagDto {
  final int tagId;
  final String name;
  final int usageCount;
  final DateTime lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TagDto({
    required this.tagId,
    required this.name,
    required this.usageCount,
    required this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TagDto.fromEntity(Tag tag) {
    return TagDto(
      tagId: tag.tagId,
      name: tag.name,
      usageCount: tag.usageCount,
      lastUsedAt: tag.lastUsedAt,
      createdAt: tag.createdAt,
      updatedAt: tag.updatedAt,
    );
  }
}