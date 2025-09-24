import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:remory/data/seed/seed_bundle.dart';
import 'package:remory/repository/dtos/memo_dto.dart';
import 'package:remory/repository/dtos/memo_tag_dto.dart';
import 'package:remory/repository/dtos/tag_dto.dart';

class SeedSourceAssets {
  final String memosPath;
  final String tagsPath;
  final String memoTagsPath;

  const SeedSourceAssets({
    this.memosPath = 'assets/seed/memos.json',
    this.tagsPath = 'assets/seed/tags.json',
    this.memoTagsPath = 'assets/seed/memo_tags.json',
  });

  Future<SeedBundle> load() async {
    final memos = await _loadList(memosPath);
    final tags = await _loadList(tagsPath);
    final memoTags = await _loadList(memoTagsPath);

    return SeedBundle(
      memos: memos.map<MemoDto>((e) => MemoDto(
        memoId: 0,
        title: e['title'] as String,
        viewCount: 0,
        createdAt: DateTime.parse(e['createdAt'] as String),
        updatedAt: DateTime.parse(e['updatedAt'] as String),
      )).toList(),
      tags: tags.map<TagDto>((e) => TagDto(
        tagId: 0,
        name: e['name'] as String,
        usageCount: 0,
        lastUsedAt: DateTime.now(),
        createdAt: DateTime.parse(e['createdAt'] as String),
        updatedAt: DateTime.parse(e['updatedAt'] as String),
      )).toList(),
      memoTags: memoTags.map<MemoTagDto>((e) => MemoTagDto(
        memoId: e['memoId'] as int,
        tagId: e['tagId'] as int,
        sortOrder: e['sortOrder'] as int,
      )).toList(),
    );
  }

  Future<List<dynamic>> _loadList(String path) async {
    final raw = await rootBundle.loadString(path);
    return compute((s) => (json.decode(s) as List).cast<dynamic>(), raw);
  }
}