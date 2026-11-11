import 'dart:convert';

import 'package:random_jebi_flutter/decision/decision_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 캐릭터 세트 리스트 조회/저장만
class CharacterSetRepository {
  static const _key = 'CUSTOM_CHARACTER_SETS_V1';

  final SharedPreferencesAsync _prefs;

  CharacterSetRepository({SharedPreferencesAsync? preferences})
    : _prefs = preferences ?? SharedPreferencesAsync();

  Future<List<CharacterSet>> loadAll() async {
    final raw = await _prefs.getString(_key);

    if (raw == null) return [];

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw const FormatException('캐릭터 세트 데이터 형식이 올바르지 않습니다.');
    }

    return [
      for (final item in decoded)
        CharacterSet.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> saveAll(List<CharacterSet> sets) async {
    final json = jsonEncode([for (final set in sets) set.toJson()]);

    await _prefs.setString(_key, json);
  }
}
