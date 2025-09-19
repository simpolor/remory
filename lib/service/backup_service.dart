import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:remory/presentation/models/memo_model.dart';
import 'package:remory/presentation/models/memo_with_tags_model.dart';
import 'package:remory/presentation/models/tag_model.dart';
import 'package:remory/repository/backup_repository.dart';
import 'package:remory/repository/dtos/memo_with_tags_dto.dart';
import 'package:share_plus/share_plus.dart';
import 'package:remory/data/app_database.dart';
import 'package:remory/presentation/models/backup_data_model.dart';

class BackupService {
  final AppDatabase db;
  final BackupRepository backupRepository;

  BackupService(this.db, this.backupRepository);

  /// 원스톱 백업: 데이터 export → 파일 저장 → 공유
  Future<File> createAndShareBackup() async {
    final jsonData = await _exportToJson();
    final file = await _saveBackupToFile(jsonData);
    await _shareBackupFile(file);
    return file;
  }

  /// 원스톱 복원: 파일 선택 → 데이터 import
  Future<bool> pickAndRestoreBackup() async {
    final jsonData = await _pickAndReadBackupFile();
    if (jsonData != null) {
      await _importFromJson(jsonData);
      return true;
    }
    return false;
  }

  /// 데이터를 JSON 문자열로 변환
  Future<String> _exportToJson() async {
    final data = await _exportAllData();
    return jsonEncode(data.toJson());
  }

  Future<BackupDataModel> _exportAllData() async {
    final memos = await backupRepository.fetchAllMemosWithTags();
    final tags = await backupRepository.fetchAllTags();

    return BackupDataModel(
      version: "1.0",
      exportedAt: DateTime.now(),
      memos: memos.map((e) => MemoWithTagsModel.fromDto(e)).toList(),
      tags: tags.map((e) => TagModel.fromDto(e)).toList(),
    );
  }

  Future<File> _saveBackupToFile(String jsonData) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'remory_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(jsonData);
    return file;
  }

  Future<void> _shareBackupFile(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Remory 백업 파일');
  }

  Future<String?> _pickAndReadBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result?.files.single.path != null) {
      final file = File(result!.files.single.path!);
      return await file.readAsString();
    }
    return null;
  }

  Future<void> _importFromJson(String jsonData) async {
    final backupData = BackupDataModel.fromJson(jsonDecode(jsonData));

    await db.transaction(() async {
      await _clearAllData();

      // Model → DTO 변환
      final tagDtos = backupData.tags.map((tag) => tag.toDto()).toList();
      final memoDtos = backupData.memos.map((memo) => MemoWithTagsDto(
        memo: memo.memo.toDto(),
        tags: memo.tags.map((tag) => tag.toDto()).toList(),
      )).toList();

      // 태그 복원하고 ID 매핑 받기
      final tagIdMap = await backupRepository.restoreTags(tagDtos);
      
      // 메모 복원할 때 매핑된 ID 사용
      await backupRepository.restoreMemosWithTags(memoDtos, tagIdMap);
    });
  }

  Future<void> _clearAllData() async {
    await db.customStatement('DELETE FROM memo_tags');
    await db.customStatement('DELETE FROM memos');
    await db.customStatement('DELETE FROM tags');

    // FTS 인덱스도 초기화
    await db.customStatement('DELETE FROM memos_fts');
  }
}
