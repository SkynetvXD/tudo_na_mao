import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_card.dart';
import '../widgets/time_picker_widget.dart';
import '../widgets/day_selector_widget.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay _exitTime = TimeOfDay(
    hour: AppConstants.defaultExitHour,
    minute: AppConstants.defaultExitMinute,
  );
  int _alarmMinutesBefore = AppConstants.defaultAlarmMinutesBefore;
  bool _enableDailyAlarm = true;
  List<bool> _selectedDays = List.from(AppConstants.defaultSelectedDays);
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _nextAlarmInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Informações',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Status do Alarme
                _buildAlarmStatusCard(),
                
                SizedBox(height: 16),
                
                // Configurações de Horário
                _buildTimeSettingsCard(),
                
                SizedBox(height: 16),
                
                // Configurações de Alarme
                _buildAlarmSettingsCard(),
                
                SizedBox(height: 16),
                
                // Configurações de Dias
                _buildDaysSettingsCard(),
                
                SizedBox(height: 16),
                
                // Configurações Avançadas
                _buildAdvancedSettingsCard(),
                
                SizedBox(height: 24),
                
                // Botões de Ação
                _buildActionButtons(),
                
                SizedBox(height: 16),
                
                // Informações do App
                _buildAppInfoCard(),
              ],
            ),
    );
  }

  Widget _buildAlarmStatusCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _enableDailyAlarm ? Icons.alarm_on : Icons.alarm_off,
                color: _enableDailyAlarm ? AppTheme.successGreen : Colors.grey[400],
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Status do Alarme',
                style: TextStyles.heading3,
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _enableDailyAlarm 
                  ? AppTheme.successGreen.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _enableDailyAlarm 
                    ? AppTheme.successGreen 
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _enableDailyAlarm ? Icons.check_circle : Icons.schedule,
                  color: _enableDailyAlarm 
                      ? AppTheme.successGreen 
                      : Colors.grey[500],
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _enableDailyAlarm ? 'Alarme ativo' : 'Alarme desativado',
                        style: TextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _enableDailyAlarm 
                              ? AppTheme.textDark 
                              : Colors.grey[500],
                        ),
                      ),
                      if (_nextAlarmInfo != null && _enableDailyAlarm) ...[
                        SizedBox(height: 4),
                        Text(
                          _nextAlarmInfo!,
                          style: TextStyles.body2.copyWith(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ] else if (_enableDailyAlarm) ...[
                        SizedBox(height: 4),
                        Text(
                          'Configure o horário de saída',
                          style: TextStyles.body2.copyWith(
                            color: AppTheme.warningOrange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSettingsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: AppTheme.primaryBlue, size: 24),
              SizedBox(width: 12),
              Text(
                'Horário de Saída',
                style: TextStyles.heading3,
              ),
            ],
          ),
          SizedBox(height: 16),
          TimePickerWidget(
            time: _exitTime,
            onTimeChanged: (time) {
              setState(() {
                _exitTime = time;
              });
              _updateNextAlarmInfo();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmSettingsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alarm, color: AppTheme.warningOrange, size: 24),
              SizedBox(width: 12),
              Text(
                'Configurações do Alarme',
                style: TextStyles.heading3,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Switch para ativar/desativar alarme
          SwitchListTile(
            title: Text(
              'Ativar alarme diário',
              style: TextStyles.body1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Tocar alarme automaticamente nos dias selecionados',
              style: TextStyles.body2,
            ),
            value: _enableDailyAlarm,
            onChanged: (value) {
              setState(() {
                _enableDailyAlarm = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          
          SizedBox(height: 16),
          
          // Slider para antecedência
          Text(
            'Antecedência do alarme',
            style: TextStyles.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Slider(
            value: _alarmMinutesBefore.toDouble(),
            min: AppConstants.minAlarmMinutesBefore.toDouble(),
            max: AppConstants.maxAlarmMinutesBefore.toDouble(),
            divisions: (AppConstants.maxAlarmMinutesBefore - AppConstants.minAlarmMinutesBefore) ~/ 5,
            label: '$_alarmMinutesBefore min',
            onChanged: (value) {
              setState(() {
                _alarmMinutesBefore = value.toInt();
              });
              _updateNextAlarmInfo();
            },
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.warningOrange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alarme tocará $_alarmMinutesBefore minutos antes de ${_exitTime.format(context)}',
                    style: TextStyles.body2.copyWith(
                      color: AppTheme.warningOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSettingsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: AppTheme.successGreen, size: 24),
              SizedBox(width: 12),
              Text(
                'Dias da semana',
                style: TextStyles.heading3,
              ),
            ],
          ),
          SizedBox(height: 16),
          DaysQuickSelectWidget(
            selectedDays: _selectedDays,
            onDaysChanged: (days) {
              setState(() {
                _selectedDays = days;
              });
              _updateNextAlarmInfo();
            },
          ),
          SizedBox(height: 12),
          DaysSummaryWidget(selectedDays: _selectedDays),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: AppTheme.primaryBlue, size: 24),
              SizedBox(width: 12),
              Text(
                'Configurações Avançadas',
                style: TextStyles.heading3,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          ListTile(
            leading: Icon(Icons.science, color: AppTheme.primaryBlue),
            title: Text('Testar Alarme Normal'),
            subtitle: Text('Testar notificação de alarme padrão'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _testNormalAlarm,
            contentPadding: EdgeInsets.zero,
          ),
          
          Divider(),
          
          ListTile(
            leading: Icon(Icons.warning, color: AppTheme.errorRed),
            title: Text('Testar Alarme de Emergência'),
            subtitle: Text('Testar notificação quando não há lista'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _testEmergencyAlarm,
            contentPadding: EdgeInsets.zero,
          ),
          
          Divider(),
          
          ListTile(
            leading: Icon(Icons.notifications_active, color: AppTheme.warningOrange),
            title: Text('Permissões de Notificação'),
            subtitle: Text('Verificar e configurar permissões'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _checkNotificationPermissions,
            contentPadding: EdgeInsets.zero,
          ),
          
          Divider(),
          
          ListTile(
            leading: Icon(Icons.delete_sweep, color: AppTheme.errorRed),
            title: Text('Limpar Todos os Dados'),
            subtitle: Text('Resetar app para configuração inicial'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showClearDataDialog,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Salvando...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Salvar Configurações',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _resetToDefaults,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Restaurar Padrões',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoCard() {
    return CustomCard(
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.grey[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Informações',
                style: TextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• O alarme tocará automaticamente nos dias e horários configurados\n'
            '• Se você não tiver itens na lista, o alarme tocará ${AppConstants.emergencyAlarmMinutesBefore} minutos antes da saída\n'
            '• Quando todos os itens estiverem marcados, você receberá uma confirmação\n'
            '• Para melhor funcionamento, desative a otimização de bateria para este app',
            style: TextStyles.body2.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      final storageService = await StorageService.getInstance();
      
      final exitTime = await storageService.getExitTime();
      final alarmMinutesBefore = await storageService.getAlarmMinutesBefore();
      final enableDailyAlarm = await storageService.isDailyAlarmEnabled();
      final selectedDays = await storageService.getSelectedDays();
      
      setState(() {
        if (exitTime != null) _exitTime = exitTime;
        _alarmMinutesBefore = alarmMinutesBefore;
        _enableDailyAlarm = enableDailyAlarm;
        _selectedDays = selectedDays;
        _isLoading = false;
      });
      
      await _updateNextAlarmInfo();
      await _loadAlarmStatus();
    } catch (e) {
      debugPrint('Erro ao carregar configurações: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNextAlarmInfo() async {
    try {
      final alarmService = AlarmService.getInstance();
      final nextAlarmFormatted = await alarmService.getNextAlarmTimeFormatted();
      setState(() {
        _nextAlarmInfo = nextAlarmFormatted;
      });
    } catch (e) {
      debugPrint('Erro ao atualizar próximo alarme: $e');
    }
  }

  Future<void> _loadAlarmStatus() async {
    try {
      final alarmService = AlarmService.getInstance();
      await alarmService.getAlarmStatus();
      // Status carregado mas não usado atualmente
    } catch (e) {
      debugPrint('Erro ao carregar status do alarme: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      // Validar configurações
      final errors = await _validateSettings();
      if (errors.isNotEmpty) {
        _showValidationErrors(errors);
        return;
      }
      
      final storageService = await StorageService.getInstance();
      final alarmService = AlarmService.getInstance();
      
      // Salvar configurações
      final success = await storageService.saveAllSettings(
        exitTime: _exitTime,
        alarmMinutesBefore: _alarmMinutesBefore,
        isDailyAlarmEnabled: _enableDailyAlarm,
        selectedDays: _selectedDays,
      );
      
      if (!success) {
        throw Exception('Falha ao salvar configurações');
      }
      
      // Reconfigurar alarmes
      if (_enableDailyAlarm) {
        await alarmService.setupAlarms();
      } else {
        await alarmService.cancelAllAlarms();
      }
      
      // Atualizar informações
      await _updateNextAlarmInfo();
      await _loadAlarmStatus();
      
      // Mostrar confirmação
      _showSuccessSnackBar('Configurações salvas com sucesso!');
      
    } catch (e) {
      debugPrint('Erro ao salvar configurações: $e');
      _showErrorSnackBar('Erro ao salvar configurações: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<List<String>> _validateSettings() async {
    final errors = <String>[];
    
    // Validar dias selecionados
    if (!_selectedDays.any((day) => day)) {
      errors.add('Selecione pelo menos um dia da semana');
    }
    
    // Validar antecedência do alarme
    if (_alarmMinutesBefore < AppConstants.minAlarmMinutesBefore ||
        _alarmMinutesBefore > AppConstants.maxAlarmMinutesBefore) {
      errors.add('Antecedência deve estar entre ${AppConstants.minAlarmMinutesBefore} e ${AppConstants.maxAlarmMinutesBefore} minutos');
    }
    
    // Verificar permissões
    try {
      final notificationService = await NotificationService.getInstance();
      final notificationsEnabled = await notificationService.areNotificationsEnabled();
      if (!notificationsEnabled) {
        errors.add('Notificações não estão habilitadas');
      }
    } catch (e) {
      debugPrint('Erro ao verificar permissões: $e');
    }
    
    return errors;
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restaurar Padrões'),
        content: Text(
          'Tem certeza que deseja restaurar todas as configurações para os valores padrão?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performResetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
            ),
            child: Text('Restaurar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performResetToDefaults() {
    setState(() {
      _exitTime = TimeOfDay(
        hour: AppConstants.defaultExitHour,
        minute: AppConstants.defaultExitMinute,
      );
      _alarmMinutesBefore = AppConstants.defaultAlarmMinutesBefore;
      _enableDailyAlarm = true;
      _selectedDays = List.from(AppConstants.defaultSelectedDays);
    });
    
    _updateNextAlarmInfo();
    _showSuccessSnackBar('Configurações restauradas para os padrões');
  }

  Future<void> _testNormalAlarm() async {
    try {
      final alarmService = AlarmService.getInstance();
      await alarmService.testAlarm(isEmergency: false);
      _showSuccessSnackBar('Teste de alarme normal enviado!');
    } catch (e) {
      debugPrint('Erro ao testar alarme normal: $e');
      _showErrorSnackBar('Erro ao testar alarme');
    }
  }

  Future<void> _testEmergencyAlarm() async {
    try {
      final alarmService = AlarmService.getInstance();
      await alarmService.testAlarm(isEmergency: true);
      _showSuccessSnackBar('Teste de alarme de emergência enviado!');
    } catch (e) {
      debugPrint('Erro ao testar alarme de emergência: $e');
      _showErrorSnackBar('Erro ao testar alarme');
    }
  }

  Future<void> _checkNotificationPermissions() async {
    try {
      final notificationService = await NotificationService.getInstance();
      final notificationsEnabled = await notificationService.areNotificationsEnabled();
      final canScheduleExact = await notificationService.canScheduleExactNotifications();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permissões de Notificação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPermissionRow(
                'Notificações habilitadas',
                notificationsEnabled,
              ),
              SizedBox(height: 8),
              _buildPermissionRow(
                'Alarmes exatos permitidos',
                canScheduleExact,
              ),
              SizedBox(height: 16),
              Text(
                'Para o funcionamento correto do app, todas as permissões devem estar habilitadas.',
                style: TextStyles.body2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Erro ao verificar permissões: $e');
      _showErrorSnackBar('Erro ao verificar permissões');
    }
  }

  Widget _buildPermissionRow(String label, bool isEnabled) {
    return Row(
      children: [
        Icon(
          isEnabled ? Icons.check_circle : Icons.cancel,
          color: isEnabled ? AppTheme.successGreen : AppTheme.errorRed,
          size: 20,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyles.body2,
          ),
        ),
      ],
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text('Limpar Dados'),
          ],
        ),
        content: Text(
          'Esta ação irá:\n\n'
          '• Remover todas as configurações\n'
          '• Apagar todos os itens da lista\n'
          '• Cancelar todos os alarmes\n'
          '• Resetar o app para o estado inicial\n\n'
          'Esta ação não pode ser desfeita!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performClearData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: Text('Limpar Tudo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performClearData() async {
    try {
      final storageService = await StorageService.getInstance();
      final alarmService = AlarmService.getInstance();
      
      // Cancelar todos os alarmes
      await alarmService.cancelAllAlarms();
      
      // Limpar todos os dados
      await storageService.clearAllData();
      
      _showSuccessSnackBar('Todos os dados foram limpos');
      
      // Voltar para a tela anterior
      if (mounted) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      debugPrint('Erro ao limpar dados: $e');
      _showErrorSnackBar('Erro ao limpar dados');
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Como Funciona'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alarmes Automáticos:',
              style: TextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• O app verifica a cada ${AppConstants.workManagerCheckInterval} minutos se é hora do alarme\n'
              '• Se você tem uma lista, o alarme toca na antecedência configurada\n'
              '• Se não tem lista, o alarme toca ${AppConstants.emergencyAlarmMinutesBefore} minutos antes como emergência',
              style: TextStyles.body2,
            ),
            SizedBox(height: 16),
            Text(
              'Dicas:',
              style: TextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Mantenha as notificações habilitadas\n'
              '• Desative a otimização de bateria para este app\n'
              '• Teste os alarmes regularmente',
              style: TextStyles.body2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _showValidationErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed),
            SizedBox(width: 8),
            Text('Erro de Validação'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors.map((error) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: AppTheme.errorRed)),
                Expanded(child: Text(error)),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        duration: AppConstants.snackBarDuration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}