import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../utils/constants.dart';

class NotificationService {
  static NotificationService? _instance;
  static FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  
  NotificationService._();
  
  static Future<NotificationService> getInstance() async {
    _instance ??= NotificationService._();
    _flutterLocalNotificationsPlugin ??= FlutterLocalNotificationsPlugin();
    await _instance!._initialize();
    return _instance!;
  }
  
  Future<void> _initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _flutterLocalNotificationsPlugin!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    await _createNotificationChannels();
    await _requestPermissions();
  }
  
  Future<void> _createNotificationChannels() async {
    // Canal para alarme de emergência
    const AndroidNotificationChannel emergencyChannel =
        AndroidNotificationChannel(
      AppConstants.emergencyAlarmChannelId,
      AppConstants.emergencyAlarmChannelName,
      description: AppConstants.emergencyAlarmChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.red,
    );
    
    // Canal para alarme normal
    const AndroidNotificationChannel normalChannel =
        AndroidNotificationChannel(
      AppConstants.normalAlarmChannelId,
      AppConstants.normalAlarmChannelName,
      description: AppConstants.normalAlarmChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.blue,
    );
    
    // Canal para alarme manual
    const AndroidNotificationChannel manualChannel =
        AndroidNotificationChannel(
      AppConstants.manualAlarmChannelId,
      AppConstants.manualAlarmChannelName,
      description: AppConstants.manualAlarmChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.orange,
    );
    
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(emergencyChannel);
      await androidImplementation.createNotificationChannel(normalChannel);
      await androidImplementation.createNotificationChannel(manualChannel);
    }
  }
  
  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificação tocada: ${response.payload}');
    // Aqui você pode navegar para uma tela específica
    // ou executar uma ação baseada no payload
  }
  
  // Notificação de alarme de emergência (sem lista)
  Future<void> showEmergencyAlarm() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConstants.emergencyAlarmChannelId,
      AppConstants.emergencyAlarmChannelName,
      channelDescription: AppConstants.emergencyAlarmChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Colors.red,
      ledColor: Colors.red,
      ticker: 'Alarme de Emergência',
      autoCancel: false,
      ongoing: true,
      colorized: true,
      channelShowBadge: true,
      onlyAlertOnce: false,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin!.show(
      AppConstants.emergencyNotificationId,
      '🚨 URGENTE - ${AppConstants.appName}',
      'Você sai em ${AppConstants.emergencyAlarmMinutesBefore} minutos e não tem lista! Verifique seus itens essenciais.',
      notificationDetails,
      payload: 'emergency_alarm',
    );
  }
  
  // Notificação de alarme normal
  Future<void> showNormalAlarm({int? minutesBefore}) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConstants.normalAlarmChannelId,
      AppConstants.normalAlarmChannelName,
      channelDescription: AppConstants.normalAlarmChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Colors.blue,
      ledColor: Colors.blue,
      ticker: 'Hora de verificar sua lista',
      autoCancel: true,
      ongoing: false,
      colorized: true,
      channelShowBadge: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    final String message = minutesBefore != null
        ? 'Você sai em $minutesBefore minutos. Verifique sua lista!'
        : 'Hora de verificar sua lista antes de sair!';

    await _flutterLocalNotificationsPlugin!.show(
      AppConstants.normalNotificationId,
      '⏰ Hora de verificar - ${AppConstants.appName}',
      message,
      notificationDetails,
      payload: 'normal_alarm',
    );
  }
  
  // Notificação de alarme manual
  Future<void> showManualAlarm() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConstants.manualAlarmChannelId,
      AppConstants.manualAlarmChannelName,
      channelDescription: AppConstants.manualAlarmChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Colors.orange,
      ledColor: Colors.orange,
      ticker: 'Alarme manual ativado',
      autoCancel: true,
      ongoing: false,
      colorized: true,
      channelShowBadge: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin!.show(
      AppConstants.manualNotificationId,
      '🔔 Alarme Manual - ${AppConstants.appName}',
      'Lembrete ativado! Não esqueça de verificar sua lista.',
      notificationDetails,
      payload: 'manual_alarm',
    );
  }
  
  // Notificação de sucesso (todos os itens marcados)
  Future<void> showSuccessNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      AppConstants.normalAlarmChannelId,
      AppConstants.normalAlarmChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      playSound: false,
      enableVibration: false,
      enableLights: false,
      color: Colors.green,
      ticker: 'Lista completa!',
      autoCancel: true,
      ongoing: false,
      colorized: true,
      channelShowBadge: false,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin!.show(
      4, // ID diferente para não conflitar
      '✅ Parabéns! - ${AppConstants.appName}',
      'Você pegou tudo! Pode sair tranquilo! 🎉',
      notificationDetails,
      payload: 'success',
    );
  }
  
  // Agendar notificação para um horário específico
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    String? payload,
  }) async {
    // Simplificada - apenas agenda para o horário especificado
    // Para funcionalidade completa de agendamento, seria necessário
    // integração com timezone e mais configurações
    
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == AppConstants.emergencyAlarmChannelId
          ? AppConstants.emergencyAlarmChannelName
          : AppConstants.normalAlarmChannelName,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      autoCancel: false,
      ongoing: true,
    );

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Por enquanto, mostra imediatamente
    // Para agendamento real seria necessário usar timezone
    await _flutterLocalNotificationsPlugin!.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  // Cancelar notificação específica
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin!.cancel(id);
  }
  
  // Cancelar todas as notificações
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin!.cancelAll();
  }
  
  // Obter notificações pendentes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin!.pendingNotificationRequests();
  }
  
  // Verificar se as notificações estão habilitadas
  Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final bool? enabled = await androidImplementation.areNotificationsEnabled();
      return enabled ?? false;
    }
    return false;
  }
  
  // Verificar se pode usar alarmes exatos
  Future<bool> canScheduleExactNotifications() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin!.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final bool? canSchedule = await androidImplementation.canScheduleExactNotifications();
      return canSchedule ?? false;
    }
    return false;
  }
}