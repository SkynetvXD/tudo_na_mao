import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/checklist_item.dart';
import '../utils/constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;
  
  StorageService._();
  
  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }
  
  // Checklist Items
  Future<List<ChecklistItem>> getChecklistItems() async {
    try {
      final String? itemsJson = _prefs?.getString(AppConstants.keyChecklistItems);
      if (itemsJson == null || itemsJson.isEmpty) return [];
      
      final List<dynamic> itemsList = json.decode(itemsJson);
      return itemsList
          .map((item) => ChecklistItem.fromJson(item))
          .toList();
    } catch (e) {
      print('Erro ao carregar itens: $e');
      return [];
    }
  }
  
  Future<bool> saveChecklistItems(List<ChecklistItem> items) async {
    try {
      final String itemsJson = json.encode(
        items.map((item) => item.toJson()).toList()
      );
      return await _prefs?.setString(AppConstants.keyChecklistItems, itemsJson) ?? false;
    } catch (e) {
      print('Erro ao salvar itens: $e');
      return false;
    }
  }
  
  Future<bool> addChecklistItem(ChecklistItem item) async {
    try {
      final items = await getChecklistItems();
      items.add(item);
      return await saveChecklistItems(items);
    } catch (e) {
      print('Erro ao adicionar item: $e');
      return false;
    }
  }
  
  Future<bool> removeChecklistItem(int index) async {
    try {
      final items = await getChecklistItems();
      if (index >= 0 && index < items.length) {
        items.removeAt(index);
        return await saveChecklistItems(items);
      }
      return false;
    } catch (e) {
      print('Erro ao remover item: $e');
      return false;
    }
  }
  
  Future<bool> updateChecklistItem(int index, ChecklistItem item) async {
    try {
      final items = await getChecklistItems();
      if (index >= 0 && index < items.length) {
        items[index] = item;
        return await saveChecklistItems(items);
      }
      return false;
    } catch (e) {
      print('Erro ao atualizar item: $e');
      return false;
    }
  }
  
  Future<bool> clearChecklistItems() async {
    try {
      return await _prefs?.remove(AppConstants.keyChecklistItems) ?? false;
    } catch (e) {
      print('Erro ao limpar itens: $e');
      return false;
    }
  }
  
  // First Time Setup
  Future<bool> isFirstTime() async {
    return _prefs?.getBool(AppConstants.keyFirstTime) ?? true;
  }
  
  Future<bool> setFirstTime(bool isFirstTime) async {
    return await _prefs?.setBool(AppConstants.keyFirstTime, isFirstTime) ?? false;
  }
  
  // Exit Time Settings
  Future<TimeOfDay?> getExitTime() async {
    final int? hour = _prefs?.getInt(AppConstants.keyExitHour);
    final int? minute = _prefs?.getInt(AppConstants.keyExitMinute);
    
    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }
  
  Future<bool> setExitTime(TimeOfDay time) async {
    try {
      final bool hourSet = await _prefs?.setInt(AppConstants.keyExitHour, time.hour) ?? false;
      final bool minuteSet = await _prefs?.setInt(AppConstants.keyExitMinute, time.minute) ?? false;
      return hourSet && minuteSet;
    } catch (e) {
      print('Erro ao salvar horário de saída: $e');
      return false;
    }
  }
  
  // Alarm Settings
  Future<int> getAlarmMinutesBefore() async {
    return _prefs?.getInt(AppConstants.keyAlarmMinutesBefore) ?? 
           AppConstants.defaultAlarmMinutesBefore;
  }
  
  Future<bool> setAlarmMinutesBefore(int minutes) async {
    return await _prefs?.setInt(AppConstants.keyAlarmMinutesBefore, minutes) ?? false;
  }
  
  Future<bool> isDailyAlarmEnabled() async {
    return _prefs?.getBool(AppConstants.keyEnableDailyAlarm) ?? true;
  }
  
  Future<bool> setDailyAlarmEnabled(bool enabled) async {
    return await _prefs?.setBool(AppConstants.keyEnableDailyAlarm, enabled) ?? false;
  }
  
  // Selected Days
  Future<List<bool>> getSelectedDays() async {
    final List<String>? selectedDaysStr = _prefs?.getStringList(AppConstants.keySelectedDays);
    if (selectedDaysStr == null) {
      return List.from(AppConstants.defaultSelectedDays);
    }
    return selectedDaysStr.map((e) => e == 'true').toList();
  }
  
  Future<bool> setSelectedDays(List<bool> selectedDays) async {
    final List<String> selectedDaysStr = selectedDays.map((e) => e.toString()).toList();
    return await _prefs?.setStringList(AppConstants.keySelectedDays, selectedDaysStr) ?? false;
  }
  
  // Complete Settings Object
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'isFirstTime': await isFirstTime(),
      'exitTime': await getExitTime(),
      'alarmMinutesBefore': await getAlarmMinutesBefore(),
      'isDailyAlarmEnabled': await isDailyAlarmEnabled(),
      'selectedDays': await getSelectedDays(),
    };
  }
  
  Future<bool> saveAllSettings({
    required TimeOfDay exitTime,
    required int alarmMinutesBefore,
    required bool isDailyAlarmEnabled,
    required List<bool> selectedDays,
  }) async {
    try {
      final List<Future<bool>> futures = [
        setFirstTime(false),
        setExitTime(exitTime),
        setAlarmMinutesBefore(alarmMinutesBefore),
        setDailyAlarmEnabled(isDailyAlarmEnabled),
        setSelectedDays(selectedDays),
      ];
      
      final List<bool> results = await Future.wait(futures);
      return results.every((result) => result);
    } catch (e) {
      print('Erro ao salvar configurações: $e');
      return false;
    }
  }
  
  // Debug and Maintenance
  Future<bool> clearAllData() async {
    try {
      return await _prefs?.clear() ?? false;
    } catch (e) {
      print('Erro ao limpar dados: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>> exportData() async {
    try {
      final settings = await getAllSettings();
      final items = await getChecklistItems();
      
      return {
        'settings': settings,
        'items': items.map((item) => item.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    } catch (e) {
      print('Erro ao exportar dados: $e');
      return {};
    }
  }
  
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      // Importar configurações
      if (data['settings'] != null) {
        final settings = data['settings'];
        final exitTimeData = settings['exitTime'];
        
        if (exitTimeData != null) {
          await setExitTime(TimeOfDay(
            hour: exitTimeData['hour'] ?? AppConstants.defaultExitHour,
            minute: exitTimeData['minute'] ?? AppConstants.defaultExitMinute,
          ));
        }
        
        await setAlarmMinutesBefore(
          settings['alarmMinutesBefore'] ?? AppConstants.defaultAlarmMinutesBefore
        );
        await setDailyAlarmEnabled(settings['isDailyAlarmEnabled'] ?? true);
        await setSelectedDays(
          List<bool>.from(settings['selectedDays'] ?? AppConstants.defaultSelectedDays)
        );
      }
      
      // Importar itens
      if (data['items'] != null) {
        final List<ChecklistItem> items = (data['items'] as List)
            .map((item) => ChecklistItem.fromJson(item))
            .toList();
        await saveChecklistItems(items);
      }
      
      return true;
    } catch (e) {
      print('Erro ao importar dados: $e');
      return false;
    }
  }
}