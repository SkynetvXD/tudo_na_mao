import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class InitialSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const InitialSetupScreen({super.key, required this.onSetupComplete});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  TimeOfDay _departureTime = const TimeOfDay(hour: 7, minute: 0);
  int _reminderMinutes = 30;

  Future<void> _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Salvar horário formatado corretamente
    final formattedTime = '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';
    await prefs.setString('departure_time', formattedTime);
    await prefs.setInt('reminder_minutes', _reminderMinutes);
    
    // Configurar notificação
    await NotificationService.scheduleDailyReminder(
      _departureTime,
      _reminderMinutes,
    );
    
    widget.onSetupComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Logo e título
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      size: 80,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tudo na Mão',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nunca mais esqueça seus itens importantes!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.blue.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Configuração do horário
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Que horas você costuma sair de casa?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _departureTime,
                          );
                          if (time != null) {
                            setState(() {
                              _departureTime = time;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 12),
                              Text(
                                _departureTime.format(context),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Configuração do lembrete
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quando quer ser lembrado?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<int>(
                        value: _reminderMinutes,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.notifications),
                        ),
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 minutos antes')),
                          DropdownMenuItem(value: 30, child: Text('30 minutos antes')),
                          DropdownMenuItem(value: 45, child: Text('45 minutos antes')),
                          DropdownMenuItem(value: 60, child: Text('1 hora antes')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _reminderMinutes = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Botão continuar
              ElevatedButton(
                onPressed: _saveConfiguration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Começar a usar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}