import 'dart:convert';

import 'package:random_jebi_flutter/draw/jebi_rules.dart';
import 'package:random_jebi_flutter/models/jebi_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JebiSlotRepository {
  static const String _storageKey = 'JEBI_SAVED_SLOTS';

  final SharedPreferencesAsync _preferences;

  JebiSlotRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  Future<List<JebiSlot>> load() async {
    final raw = await _preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw const FormatException('저장된 슬롯 데이터의 형식이 잘못되었습니다.');
    }

    final slots = [
      for (final item in decoded)
        JebiSlot.fromJson(Map<String, dynamic>.from(item as Map)),
    ];

    return slots;
  }

  Future<void> saveAll(List<JebiSlot> slots) async {
    if (slots.length > JebiRules.maxSlots) {
      throw ArgumentError('슬롯은 최대 ${JebiRules.maxSlots}까지 저장할 수 있습니다.');
    }

    final json = jsonEncode(slots.map((slot) => slot.toJson()).toList());

    await _preferences.setString(_storageKey, json);
  }
}
