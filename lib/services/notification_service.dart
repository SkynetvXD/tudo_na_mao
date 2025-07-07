import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Inicializar timezone
      tz.initializeTimeZones();
      
      // Solicitar permissões
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notifications.initialize(initSettings);
      _isInitialized = true;
      
    } catch (e) {
      // Silencioso em produção
    }
  }

  static Future<void> scheduleDailyReminder(
    TimeOfDay departureTime,
    int reminderMinutes,
  ) async {
    try {
      // Garantir que está inicializado
      if (!_isInitialized) {
        await initialize();
      }
      
      // Cancelar todas as notificações anteriores
      await _notifications.cancelAll();

      // Verificar permissões
      final hasPermission = await areNotificationsEnabled();
      if (!hasPermission) {
        return;
      }
      
      final location = tz.local;
      
      // 1. Notificação de preparação
      await _schedulePreparationNotification(departureTime, reminderMinutes, location);
      
      // 2. Notificação de saída
      await _scheduleExitNotification(departureTime, location);
      
    } catch (e) {
      // Silencioso em produção
    }
  }

  static Future<void> _schedulePreparationNotification(
    TimeOfDay departureTime, 
    int reminderMinutes, 
    tz.Location location
  ) async {
    final totalMinutes = departureTime.hour * 60 + departureTime.minute;
    final reminderTotalMinutes = totalMinutes - reminderMinutes;
    
    if (reminderTotalMinutes < 0) {
      return; // Horário inválido
    }
    
    final reminderHour = reminderTotalMinutes ~/ 60;
    final reminderMinute = reminderTotalMinutes % 60;
    
    final now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location, 
      now.year, 
      now.month, 
      now.day, 
      reminderHour, 
      reminderMinute
    );
    
    // Se já passou hoje, agendar para amanhã
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      1,
      '🎒 Tudo na Mão - Prepare-se!',
      'Faltam $reminderMinutes minutos para sair! Hora de conferir sua lista 📋',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'preparation_reminder',
          'Lembrete de Preparação',
          channelDescription: 'Lembrete para se preparar antes de sair',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
    );
  }

  static Future<void> _scheduleExitNotification(
    TimeOfDay departureTime,
    tz.Location location
  ) async {
    final now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      departureTime.hour,
      departureTime.minute,
    );
    
    // Se já passou hoje, agendar para amanhã
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      2,
      '🚪 Hora de sair!',
      'Está na hora de sair! Conferiu tudo na sua lista? 🎒',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'exit_reminder',
          'Lembrete de Saída',
          channelDescription: 'Lembrete no horário exato de saída',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
    );
  }

  static Future<void> showInstantReminder() async {
    try {
      await _notifications.show(
        99,
        '🎒 Tudo na Mão',
        'Não esqueça de conferir sua lista!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_reminder',
            'Lembretes Instantâneos',
            channelDescription: 'Lembretes imediatos para conferir a lista',
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      // Silencioso em produção
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openNotificationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      // Silencioso em produção
    }
  }

  static Future<void> testNotification() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      await _notifications.show(
        999,
        '🧪 Teste - Tudo na Mão',
        'Notificação de teste! Se você viu isso, está funcionando! 🎉',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_reminder',
            'Testes',
            channelDescription: 'Notificações de teste',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      // Silencioso em produção
    }
  }
}