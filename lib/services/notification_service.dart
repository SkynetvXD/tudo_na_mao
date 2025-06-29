import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Inicializar timezone
      tz.initializeTimeZones();
      
      // Solicitar todas as permissões necessárias
      await _requestAllPermissions();
      
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
      
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      if (kDebugMode) {
        print('✅ Serviço de notificações inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inicializar notificações: $e');
      }
    }
  }

  static Future<void> _requestAllPermissions() async {
    // Solicitar permissão básica de notificação
    await Permission.notification.request();
    
    // Para Android 12+ (API 31+), solicitar permissão de alarmes exatos
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
    
    // Verificar se as permissões foram concedidas
    final notificationStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    
    if (kDebugMode) {
      print('📱 Status das permissões:');
      print('  - Notificações: $notificationStatus');
      print('  - Alarmes exatos: $alarmStatus');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('Notificação tocada: ${response.payload}');
    }
  }

  static Future<void> scheduleDailyReminder(
    TimeOfDay departureTime,
    int reminderMinutes,
  ) async {
    try {
      // Cancelar notificações anteriores
      await _notifications.cancelAll();

      // Calcular horário do lembrete
      final totalMinutes = departureTime.hour * 60 + departureTime.minute;
      final reminderTotalMinutes = totalMinutes - reminderMinutes;
      
      if (reminderTotalMinutes < 0) {
        if (kDebugMode) {
          print('⚠️ Horário de lembrete inválido: seria antes de 00:00');
        }
        return;
      }
      
      final reminderHour = reminderTotalMinutes ~/ 60;
      final reminderMinute = reminderTotalMinutes % 60;

      // Obter timezone local do Brasil
      final location = tz.getLocation('America/Sao_Paulo');
      final scheduledDate = _nextInstanceOfTime(reminderHour, reminderMinute, location);

      // Configurar notificação diária
      await _notifications.zonedSchedule(
        0, // ID da notificação
        '🎒 Tudo na Mão',
        'Hora de conferir sua lista antes de sair! Você sai às ${_formatTime(departureTime)}',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Lembretes Diários',
            channelDescription: 'Lembretes para conferir a lista antes de sair',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            showWhen: true,
            // icon: 'ic_stat_name', // Comentado temporariamente
            //largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (kDebugMode) {
        print('✅ Notificação agendada para: ${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}');
        print('📅 Próxima notificação: ${scheduledDate.toString()}');
        print('🕐 Saída programada: ${_formatTime(departureTime)}');
      }

      // Agendar também uma notificação de backup para 5 minutos antes da saída
      if (reminderMinutes > 5) {
        await _scheduleBackupReminder(departureTime, location);
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao agendar notificação: $e');
      }
    }
  }

  static Future<void> _scheduleBackupReminder(TimeOfDay departureTime, tz.Location location) async {
    try {
      final totalMinutes = departureTime.hour * 60 + departureTime.minute;
      final backupMinutes = totalMinutes - 5; // 5 minutos antes

      if (backupMinutes < 0) return;

      final backupHour = backupMinutes ~/ 60;
      final backupMinute = backupMinutes % 60;
      final backupDate = _nextInstanceOfTime(backupHour, backupMinute, location);

      await _notifications.zonedSchedule(
        1, // ID diferente
        '⏰ Última chance!',
        'Faltam 5 minutos para sua saída! Conferiu tudo?',
        backupDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'backup_reminder',
            'Lembretes de Última Hora',
            channelDescription: 'Lembrete final antes da saída',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            // icon: 'ic_stat_name', // Comentado temporariamente
           // largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (kDebugMode) {
        print('🔔 Notificação de backup agendada para: ${backupHour.toString().padLeft(2, '0')}:${backupMinute.toString().padLeft(2, '0')}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao agendar notificação de backup: $e');
      }
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute, tz.Location location) {
    final now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> showInstantReminder() async {
    try {
      await _notifications.show(
        1,
        '🎒 Tudo na Mão',
        'Não esqueça de conferir sua lista!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_reminder',
            'Lembretes Instantâneos',
            channelDescription: 'Lembretes imediatos para conferir a lista',
            importance: Importance.high,
            priority: Priority.high,
            // icon: 'ic_stat_name', // Comentado temporariamente
            //largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao mostrar notificação instantânea: $e');
      }
    }
  }

  // Método para verificar se as notificações estão funcionando
  static Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao verificar permissões: $e');
      }
      return false;
    }
  }

  // Método para abrir configurações de notificação
  static Future<void> openNotificationSettings() async {
    try {
      await Permission.notification.request();
      if (await Permission.notification.isDenied) {
        await openAppSettings();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao abrir configurações: $e');
      }
    }
  }

  // Método para listar notificações agendadas (debug)
  static Future<void> listScheduledNotifications() async {
    try {
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      
      if (kDebugMode) {
        print('📋 Notificações agendadas (${pendingNotifications.length}):');
        for (final notification in pendingNotifications) {
          print('  - ID: ${notification.id}, Título: ${notification.title}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao listar notificações: $e');
      }
    }
  }

  // Método para testar notificação instantânea (simplificado)
  static Future<void> testNotification() async {
    try {
      // Teste com notificação simples primeiro
      await _notifications.show(
        999,
        '🧪 Teste - Tudo na Mão',
        'Esta é uma notificação de teste! Se você viu isso, as notificações estão funcionando! 🎉',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_reminder',
            'Testes',
            channelDescription: 'Notificações de teste',
            importance: Importance.max,
            priority: Priority.max,
            enableVibration: true,
            playSound: true,
            // icon: 'ic_stat_name', // Comentado temporariamente
            //largeIcon: DrawableResourceAndroidBitmap('ic_launcher'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      if (kDebugMode) {
        print('🧪 Notificação de teste enviada imediatamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao enviar notificação de teste: $e');
      }
      
      // Fallback: notificação ainda mais simples
      try {
        await _notifications.show(
          999,
          'Teste',
          'Notificação de teste simples',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'test_simple',
              'Teste Simples',
              importance: Importance.high,
            ),
          ),
        );
      } catch (e2) {
        if (kDebugMode) {
          print('❌ Erro no fallback: $e2');
        }
      }
    }
  }
}