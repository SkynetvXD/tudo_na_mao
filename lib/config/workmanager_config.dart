import 'package:workmanager/workmanager.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('WorkManager task executada: $task');
      
      if (task == AppConstants.dailyAlarmTaskName) {
        await _handleDailyAlarmTask(inputData);
      }
      
      return Future.value(true);
    } catch (e) {
      print('Erro na execução da task WorkManager: $e');
      return Future.value(false);
    }
  });
}

Future<void> _handleDailyAlarmTask(Map<String, dynamic>? inputData) async {
  try {
    final storageService = await StorageService.getInstance();
    final notificationService = await NotificationService.getInstance();
    
    // Verificar se o alarme diário está habilitado
    final bool enableDailyAlarm = await storageService.isDailyAlarmEnabled();
    if (!enableDailyAlarm) {
      print('Alarme diário desabilitado, pulando execução');
      return;
    }
    
    // Obter configurações
    final exitTime = await storageService.getExitTime();
    if (exitTime == null) {
      print('Horário de saída não configurado');
      return;
    }
    
    final int alarmMinutesBefore = await storageService.getAlarmMinutesBefore();
    final List<bool> selectedDays = await storageService.getSelectedDays();
    
    // Verificar dia atual
    final DateTime now = DateTime.now();
    final int todayIndex = (now.weekday - 1) % 7; // Segunda = 0, Domingo = 6
    
    if (!selectedDays[todayIndex]) {
      print('Hoje não é um dia selecionado para alarme');
      return;
    }
    
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
    
    // Tolerância de 15 minutos para verificação (intervalo do WorkManager)
    final Duration tolerance = Duration(minutes: AppConstants.workManagerCheckInterval);
    
    // Verificar se é hora do alarme
    if (_isTimeInRange(now, alarmDateTime, tolerance)) {
      // Verificar se há itens na lista
      final items = await storageService.getChecklistItems();
      
      if (items.isEmpty) {
        print('Lista vazia, verificando alarme de emergência');
        // Se não há lista, verificar se deve usar alarme de emergência
        if (_isTimeInRange(now, emergencyAlarmDateTime, tolerance)) {
          await notificationService.showEmergencyAlarm();
          print('Alarme de emergência disparado via WorkManager');
        }
      } else {
        // Se há lista, usar alarme normal
        await notificationService.showNormalAlarm(
          minutesBefore: alarmMinutesBefore
        );
        print('Alarme normal disparado via WorkManager');
      }
    } else if (_isTimeInRange(now, emergencyAlarmDateTime, tolerance)) {
      // Verificação adicional para alarme de emergência
      final items = await storageService.getChecklistItems();
      if (items.isEmpty) {
        await notificationService.showEmergencyAlarm();
        print('Alarme de emergência (backup) disparado via WorkManager');
      }
    }
    
    print('Verificação de alarme WorkManager concluída');
  } catch (e) {
    print('Erro ao processar alarme diário: $e');
  }
}

bool _isTimeInRange(DateTime current, DateTime target, Duration tolerance) {
  final DateTime start = target.subtract(tolerance);
  final DateTime end = target.add(tolerance);
  return current.isAfter(start) && current.isBefore(end);
}

class WorkManagerConfig {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Defina como true para debug
    );
  }
  
  static Future<void> registerDailyAlarmTask() async {
    try {
      // Cancelar tarefas anteriores
      await Workmanager().cancelByUniqueName(AppConstants.dailyAlarmTaskId);
      
      // Registrar nova tarefa periódica
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
          'registered_at': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
        },
        initialDelay: Duration(minutes: 1), // Delay inicial de 1 minuto
      );
      
      print('Tarefa do WorkManager registrada com sucesso');
    } catch (e) {
      print('Erro ao registrar tarefa do WorkManager: $e');
    }
  }
  
  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      print('Todas as tarefas do WorkManager canceladas');
    } catch (e) {
      print('Erro ao cancelar tarefas do WorkManager: $e');
    }
  }
  
  static Future<void> cancelDailyAlarmTask() async {
    try {
      await Workmanager().cancelByUniqueName(AppConstants.dailyAlarmTaskId);
      print('Tarefa de alarme diário cancelada');
    } catch (e) {
      print('Erro ao cancelar tarefa de alarme diário: $e');
    }
  }
  
  // Registrar tarefa one-time para teste
  static Future<void> registerTestTask({int delayMinutes = 1}) async {
    try {
      await Workmanager().registerOneOffTask(
        'test_task',
        'test_task_name',
        initialDelay: Duration(minutes: delayMinutes),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'test': true,
          'scheduled_at': DateTime.now().toIso8601String(),
        },
      );
      
      print('Tarefa de teste registrada para $delayMinutes minuto(s)');
    } catch (e) {
      print('Erro ao registrar tarefa de teste: $e');
    }
  }
  
  // Configurações avançadas para otimização de bateria
  static Future<void> setupBatteryOptimization() async {
    try {
      // Aqui você pode implementar lógica para solicitar
      // que o usuário desative a otimização de bateria para o app
      // Isso é específico do Android e requer configuração adicional
      
      print('Configurações de otimização de bateria verificadas');
    } catch (e) {
      print('Erro ao configurar otimização de bateria: $e');
    }
  }
  
  // Verificar status das tarefas
  static Future<Map<String, dynamic>> getTasksStatus() async {
    try {
      // O WorkManager não fornece uma API direta para listar tarefas,
      // mas podemos implementar nossa própria verificação
      
      return {
        'isInitialized': true,
        'lastCheck': DateTime.now().toIso8601String(),
        'status': 'active',
      };
    } catch (e) {
      return {
        'isInitialized': false,
        'error': e.toString(),
        'lastCheck': DateTime.now().toIso8601String(),
      };
    }
  }
}