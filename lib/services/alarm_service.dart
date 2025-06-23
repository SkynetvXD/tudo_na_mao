import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import '../utils/constants.dart';

class AlarmService {
  static AlarmService? _instance;
  
  AlarmService._();
  
  static AlarmService getInstance() {
    _instance ??= AlarmService._();
    return _instance!;
  }
  
  // Configurar todos os alarmes baseado nas configurações
  Future<bool> setupAlarms() async {
    try {
      final storageService = await StorageService.getInstance();
      
      // Cancelar alarmes anteriores
      await cancelAllAlarms();
      
      // Verificar se o alarme diário está habilitado
      final bool isDailyAlarmEnabled = await storageService.isDailyAlarmEnabled();
      if (!isDailyAlarmEnabled) {
        print('Alarme diário desabilitado');
        return true;
      }
      
      // Obter configurações
      final TimeOfDay? exitTime = await storageService.getExitTime();
      if (exitTime == null) {
        print('Horário de saída não configurado');
        return false;
      }
      
      // Registrar tarefa periódica para verificar alarmes
      await Workmanager().registerPeriodicTask(
        AppConstants.dailyAlarmTaskId,
        AppConstants.dailyAlarmTaskName,
        frequency: Duration(minutes: AppConstants.workManagerCheckInterval),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'setup_time': DateTime.now().toIso8601String(),
        },
      );
      
      print('Alarmes configurados com sucesso');
      return true;
    } catch (e) {
      print('Erro ao configurar alarmes: $e');
      return false;
    }
  }
  
  // Cancelar todos os alarmes
  Future<void> cancelAllAlarms() async {
    try {
      await Workmanager().cancelAll();
      final notificationService = await NotificationService.getInstance();
      await notificationService.cancelAllNotifications();
      print('Todos os alarmes cancelados');
    } catch (e) {
      print('Erro ao cancelar alarmes: $e');
    }
  }
  
  // Verificar se deve disparar alarme agora
  Future<void> checkAndTriggerAlarm() async {
    try {
      final storageService = await StorageService.getInstance();
      final notificationService = await NotificationService.getInstance();
      
      // Verificar se o alarme está habilitado
      final bool isDailyAlarmEnabled = await storageService.isDailyAlarmEnabled();
      if (!isDailyAlarmEnabled) return;
      
      // Obter configurações
      final TimeOfDay? exitTime = await storageService.getExitTime();
      if (exitTime == null) return;
      
      final int alarmMinutesBefore = await storageService.getAlarmMinutesBefore();
      final List<bool> selectedDays = await storageService.getSelectedDays();
      
      final DateTime now = DateTime.now();
      final int todayIndex = (now.weekday - 1) % 7; // Segunda = 0, Domingo = 6
      
      // Verificar se hoje é um dia selecionado
      if (!selectedDays[todayIndex]) return;
      
      // Calcular horários
      final DateTime exitDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        exitTime.hour,
        exitTime.minute,
      );
      
      final DateTime alarmDateTime = exitDateTime.subtract(
        Duration(minutes: alarmMinutesBefore)
      );
      
      final DateTime emergencyAlarmDateTime = exitDateTime.subtract(
        Duration(minutes: AppConstants.emergencyAlarmMinutesBefore)
      );
      
      // Verificar se é hora do alarme (com tolerância de 2 minutos)
      final Duration tolerance = Duration(minutes: 2);
      
      if (_isTimeInRange(now, alarmDateTime, tolerance)) {
        // Verificar se há itens na lista
        final items = await storageService.getChecklistItems();
        
        if (items.isEmpty) {
          // Se não há lista, usar alarme de emergência
          if (_isTimeInRange(now, emergencyAlarmDateTime, tolerance)) {
            await notificationService.showEmergencyAlarm();
            print('Alarme de emergência disparado');
          }
        } else {
          // Se há lista, usar alarme normal
          await notificationService.showNormalAlarm(
            minutesBefore: alarmMinutesBefore
          );
          print('Alarme normal disparado');
        }
      } else if (_isTimeInRange(now, emergencyAlarmDateTime, tolerance)) {
        // Sempre disparar alarme de emergência 10 minutos antes se não há lista
        final items = await storageService.getChecklistItems();
        if (items.isEmpty) {
          await notificationService.showEmergencyAlarm();
          print('Alarme de emergência (backup) disparado');
        }
      }
    } catch (e) {
      print('Erro ao verificar alarme: $e');
    }
  }
  
  // Verificar se o horário atual está dentro do range especificado
  bool _isTimeInRange(DateTime current, DateTime target, Duration tolerance) {
    final DateTime start = target.subtract(tolerance);
    final DateTime end = target.add(tolerance);
    return current.isAfter(start) && current.isBefore(end);
  }
  
  // Obter próximo horário de alarme
  Future<DateTime?> getNextAlarmTime() async {
    try {
      final storageService = await StorageService.getInstance();
      
      final TimeOfDay? exitTime = await storageService.getExitTime();
      if (exitTime == null) return null;
      
      final int alarmMinutesBefore = await storageService.getAlarmMinutesBefore();
      final List<bool> selectedDays = await storageService.getSelectedDays();
      
      final DateTime now = DateTime.now();
      
      // Procurar pelo próximo dia válido
      for (int i = 0; i < 7; i++) {
        final DateTime targetDate = now.add(Duration(days: i));
        final int dayIndex = (targetDate.weekday - 1) % 7;
        
        if (selectedDays[dayIndex]) {
          final DateTime exitDateTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            exitTime.hour,
            exitTime.minute,
          );
          
          final DateTime alarmDateTime = exitDateTime.subtract(
            Duration(minutes: alarmMinutesBefore)
          );
          
          // Se é hoje, verificar se o alarme ainda não passou
          if (i == 0 && alarmDateTime.isBefore(now)) {
            continue; // Pular para o próximo dia
          }
          
          return alarmDateTime;
        }
      }
      
      return null;
    } catch (e) {
      print('Erro ao calcular próximo alarme: $e');
      return null;
    }
  }
  
  // Formatar horário do próximo alarme
  Future<String?> getNextAlarmTimeFormatted() async {
    final DateTime? nextAlarm = await getNextAlarmTime();
    if (nextAlarm == null) return null;
    
    final DateTime now = DateTime.now();
    final Duration difference = nextAlarm.difference(now);
    
    final String timeString = '${nextAlarm.hour.toString().padLeft(2, '0')}:${nextAlarm.minute.toString().padLeft(2, '0')}';
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Amanhã às $timeString';
      } else {
        final int dayIndex = (nextAlarm.weekday - 1) % 7;
        return '${AppConstants.weekDays[dayIndex]} às $timeString';
      }
    } else if (difference.inHours > 0) {
      return 'Hoje às $timeString (${difference.inHours}h ${difference.inMinutes % 60}min)';
    } else if (difference.inMinutes > 0) {
      return 'Hoje às $timeString (${difference.inMinutes}min)';
    } else {
      return 'Agora!';
    }
  }
  
  // Verificar status do alarme
  Future<Map<String, dynamic>> getAlarmStatus() async {
    try {
      final storageService = await StorageService.getInstance();
      
      final bool isDailyAlarmEnabled = await storageService.isDailyAlarmEnabled();
      final TimeOfDay? exitTime = await storageService.getExitTime();
      final int alarmMinutesBefore = await storageService.getAlarmMinutesBefore();
      final List<bool> selectedDays = await storageService.getSelectedDays();
      final DateTime? nextAlarm = await getNextAlarmTime();
      final String? nextAlarmFormatted = await getNextAlarmTimeFormatted();
      
      // Contar dias selecionados
      final int selectedDaysCount = selectedDays.where((day) => day).length;
      
      return {
        'isEnabled': isDailyAlarmEnabled,
        'exitTime': exitTime,
        'alarmMinutesBefore': alarmMinutesBefore,
        'selectedDays': selectedDays,
        'selectedDaysCount': selectedDaysCount,
        'nextAlarm': nextAlarm,
        'nextAlarmFormatted': nextAlarmFormatted,
        'isConfigured': exitTime != null && isDailyAlarmEnabled,
      };
    } catch (e) {
      print('Erro ao obter status do alarme: $e');
      return {
        'isEnabled': false,
        'isConfigured': false,
        'error': e.toString(),
      };
    }
  }
  
  // Testar alarme manualmente
  Future<void> testAlarm({bool isEmergency = false}) async {
    try {
      final notificationService = await NotificationService.getInstance();
      
      if (isEmergency) {
        await notificationService.showEmergencyAlarm();
        print('Teste de alarme de emergência executado');
      } else {
        await notificationService.showNormalAlarm();
        print('Teste de alarme normal executado');
      }
    } catch (e) {
      print('Erro ao testar alarme: $e');
    }
  }
  
  // Snooze (adiar) alarme por X minutos
  Future<void> snoozeAlarm(int minutes) async {
    try {
      final notificationService = await NotificationService.getInstance();
      
      // Cancelar notificações atuais
      await notificationService.cancelAllNotifications();
      
      // Agendar nova notificação para daqui X minutos
      final DateTime snoozeTime = DateTime.now().add(Duration(minutes: minutes));
      
      await notificationService.scheduleNotification(
        id: 999, // ID especial para snooze
        title: '😴 Lembrete adiado - ${AppConstants.appName}',
        body: 'Não se esqueça de verificar sua lista!',
        scheduledTime: snoozeTime,
        channelId: AppConstants.normalAlarmChannelId,
        payload: 'snooze_alarm',
      );
      
      print('Alarme adiado por $minutes minutos');
    } catch (e) {
      print('Erro ao adiar alarme: $e');
    }
  }
  
  // Validar configurações de alarme
  Future<List<String>> validateAlarmSettings() async {
    final List<String> errors = [];
    
    try {
      final storageService = await StorageService.getInstance();
      
      final TimeOfDay? exitTime = await storageService.getExitTime();
      if (exitTime == null) {
        errors.add('Horário de saída não configurado');
      }
      
      final int alarmMinutesBefore = await storageService.getAlarmMinutesBefore();
      if (alarmMinutesBefore < AppConstants.minAlarmMinutesBefore || 
          alarmMinutesBefore > AppConstants.maxAlarmMinutesBefore) {
        errors.add('Antecedência do alarme inválida ($alarmMinutesBefore min)');
      }
      
      final List<bool> selectedDays = await storageService.getSelectedDays();
      if (!selectedDays.any((day) => day)) {
        errors.add('Nenhum dia da semana selecionado');
      }
      
      // Verificar permissões de notificação
      final notificationService = await NotificationService.getInstance();
      final bool notificationsEnabled = await notificationService.areNotificationsEnabled();
      if (!notificationsEnabled) {
        errors.add('Notificações não estão habilitadas');
      }
      
      final bool canScheduleExact = await notificationService.canScheduleExactNotifications();
      if (!canScheduleExact) {
        errors.add('Permissão para alarmes exatos não concedida');
      }
      
    } catch (e) {
      errors.add('Erro ao validar configurações: $e');
    }
    
    return errors;
  }
  
  // Obter estatísticas de uso do alarme
  Future<Map<String, dynamic>> getAlarmStats() async {
    try {
      final notificationService = await NotificationService.getInstance();
      final pendingNotifications = await notificationService.getPendingNotifications();
      
      return {
        'pendingNotificationsCount': pendingNotifications.length,
        'lastSetupTime': DateTime.now().toIso8601String(),
        'isWorkManagerActive': await _isWorkManagerActive(),
      };
    } catch (e) {
      print('Erro ao obter estatísticas: $e');
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Verificar se o WorkManager está ativo
  Future<bool> _isWorkManagerActive() async {
    try {
      // Esta é uma verificação básica
      // Você pode expandir isso para verificar se a tarefa está realmente agendada
      return true; // Por enquanto, assumimos que está ativo se chegamos até aqui
    } catch (e) {
      return false;
    }
  }
  
  // Reset completo dos alarmes
  Future<void> resetAlarms() async {
    try {
      await cancelAllAlarms();
      await setupAlarms();
      print('Alarmes resetados com sucesso');
    } catch (e) {
      print('Erro ao resetar alarmes: $e');
    }
  }
}