import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/alarm_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/time_picker_widget.dart';
import '../widgets/day_selector_widget.dart';
import '../widgets/custom_card.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> 
    with TickerProviderStateMixin {
  TimeOfDay _exitTime = TimeOfDay(
    hour: AppConstants.defaultExitHour,
    minute: AppConstants.defaultExitMinute,
  );
  int _alarmMinutesBefore = AppConstants.defaultAlarmMinutesBefore;
  bool _enableDailyAlarm = true;
  List<bool> _selectedDays = List.from(AppConstants.defaultSelectedDays);
  
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimations() {
    Future.delayed(Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                
                // Header
                _buildHeader(),
                
                SizedBox(height: 40),
                
                // Exit Time Card
                CustomCard(
                  child: _buildExitTimeSection(),
                ),
                
                SizedBox(height: 20),
                
                // Alarm Advance Card
                CustomCard(
                  child: _buildAlarmAdvanceSection(),
                ),
                
                SizedBox(height: 20),
                
                // Days Selection Card
                CustomCard(
                  child: _buildDaysSelectionSection(),
                ),
                
                SizedBox(height: 20),
                
                // Daily Alarm Toggle Card
                CustomCard(
                  child: _buildDailyAlarmSection(),
                ),
                
                SizedBox(height: 40),
                
                // Action Buttons
                _buildActionButtons(),
                
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 64,
              color: AppTheme.primaryBlue,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Vamos configurar seu horário!',
            style: TextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Configure quando você sai de casa para receber lembretes automáticos',
            style: TextStyles.body2.copyWith(
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExitTimeSection() {
    return Column(
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
          },
        ),
      ],
    );
  }

  Widget _buildAlarmAdvanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.alarm, color: AppTheme.warningOrange, size: 24),
            SizedBox(width: 12),
            Text(
              'Lembrete com antecedência',
              style: TextStyles.heading3,
            ),
          ],
        ),
        SizedBox(height: 16),
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
    );
  }

  Widget _buildDaysSelectionSection() {
    return Column(
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
        DaySelectorWidget(
          selectedDays: _selectedDays,
          onDaysChanged: (days) {
            setState(() {
              _selectedDays = days;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDailyAlarmSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_active, color: AppTheme.primaryBlue, size: 24),
            SizedBox(width: 12),
            Text(
              'Alarme Automático',
              style: TextStyles.heading3,
            ),
          ],
        ),
        SizedBox(height: 8),
        SwitchListTile(
          title: Text(
            'Ativar alarme diário',
            style: TextStyles.body1,
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
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Salvar e Continuar',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _skipConfiguration,
            child: Text(
              'Pular configuração',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = await StorageService.getInstance();
      final alarmService = AlarmService.getInstance();
      
      // Validar configurações
      final errors = await _validateSettings();
      if (errors.isNotEmpty) {
        _showErrorDialog(errors);
        return;
      }
      
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
      
      // Configurar alarmes
      if (_enableDailyAlarm) {
        await alarmService.setupAlarms();
      }
      
      // Mostrar confirmação
      _showSuccessSnackBar();
      
      // Navegar para home
      await Future.delayed(Duration(seconds: 1));
      _navigateToHome();
      
    } catch (e) {
      print('Erro ao salvar configurações: $e');
      _showErrorSnackBar('Erro ao salvar configurações: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _skipConfiguration() async {
    if (_isLoading) return;
    
    try {
      final storageService = await StorageService.getInstance();
      await storageService.setFirstTime(false);
      _navigateToHome();
    } catch (e) {
      print('Erro ao pular configuração: $e');
      _navigateToHome(); // Navegar mesmo com erro
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
    
    return errors;
  }

  void _showErrorDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Configurações salvas com sucesso!'),
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

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}