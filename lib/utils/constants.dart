class AppConstants {
  // SharedPreferences Keys
  static const String keyFirstTime = 'first_time';
  static const String keyChecklistItems = 'checklist_items';
  static const String keyExitHour = 'exit_hour';
  static const String keyExitMinute = 'exit_minute';
  static const String keyAlarmMinutesBefore = 'alarm_minutes_before';
  static const String keyEnableDailyAlarm = 'enable_daily_alarm';
  static const String keySelectedDays = 'selected_days';
  
  // Notification Channels
  static const String emergencyAlarmChannelId = 'emergency_alarm_channel';
  static const String emergencyAlarmChannelName = 'Alarme de Emergência';
  static const String emergencyAlarmChannelDescription = 'Alarme quando não há lista configurada';
  
  static const String normalAlarmChannelId = 'normal_alarm_channel';
  static const String normalAlarmChannelName = 'Alarme Normal';
  static const String normalAlarmChannelDescription = 'Alarme para verificar a lista';
  
  static const String manualAlarmChannelId = 'manual_alarm_channel';
  static const String manualAlarmChannelName = 'Alarme Manual';
  static const String manualAlarmChannelDescription = 'Alarme ativado manualmente';
  
  // WorkManager Tasks
  static const String dailyAlarmTaskName = 'daily_alarm_task';
  static const String dailyAlarmTaskId = 'daily_alarm';
  
  // Default Values
  static const int defaultExitHour = 7;
  static const int defaultExitMinute = 0;
  static const int defaultAlarmMinutesBefore = 30;
  static const int emergencyAlarmMinutesBefore = 10;
  static const int maxAlarmMinutesBefore = 60;
  static const int minAlarmMinutesBefore = 5;
  static const int workManagerCheckInterval = 15; // minutos
  
  // Notification IDs
  static const int emergencyNotificationId = 1;
  static const int normalNotificationId = 2;
  static const int manualNotificationId = 3;
  
  // Week Days
  static const List<String> weekDays = [
    'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'
  ];
  
  static const List<String> weekDaysFull = [
    'Segunda-feira',
    'Terça-feira', 
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo'
  ];
  
  // Default selected days (Monday to Friday)
  static const List<bool> defaultSelectedDays = [
    true, true, true, true, true, false, false
  ];
  
  // App Info
  static const String appName = 'Tudo na Mão';
  static const String appSlogan = 'Nunca mais esqueça nada!';
  
  // Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration alarmDuration = Duration(seconds: 30);
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const Duration undoSnackBarDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Common Item Suggestions
  static const List<String> commonItems = [
    'Carteira',
    'Chaves',
    'Celular',
    'Documentos',
    'Óculos',
    'Fone de ouvido',
    'Carregador',
    'Guarda-chuva',
    'Medicamentos',
    'Máscara',
  ];
}