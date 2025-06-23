import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/checklist_item.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/alarm_service.dart';
import '../widgets/custom_card.dart';
import '../widgets/status_widget.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<ChecklistItem> items = [];
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isAlarmPlaying = false;
  bool _isLoading = true;
  
  // Configurações de horário
  TimeOfDay? _exitTime;
  int _alarmMinutesBefore = AppConstants.defaultAlarmMinutesBefore;
  bool _hasConfiguration = false;
  String? _nextAlarmInfo;
  
  // Animações
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _loadData();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }

  Future<void> _initializeServices() async {
    try {
      await NotificationService.getInstance();
    } catch (e) {
      print('Erro ao inicializar serviços: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      await _loadItems();
      await _loadSettings();
      await _loadNextAlarmInfo();
    } catch (e) {
      print('Erro ao carregar dados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  Future<void> _loadItems() async {
    final storageService = await StorageService.getInstance();
    final loadedItems = await storageService.getChecklistItems();
    setState(() {
      items = loadedItems;
    });
  }

  Future<void> _loadSettings() async {
    final storageService = await StorageService.getInstance();
    final exitTime = await storageService.getExitTime();
    final alarmMinutesBefore = await storageService.getAlarmMinutesBefore();
    
    setState(() {
      _exitTime = exitTime;
      _alarmMinutesBefore = alarmMinutesBefore;
      _hasConfiguration = exitTime != null;
    });
  }

  Future<void> _loadNextAlarmInfo() async {
    if (!_hasConfiguration) return;
    
    try {
      final alarmService = AlarmService.getInstance();
      final nextAlarmFormatted = await alarmService.getNextAlarmTimeFormatted();
      setState(() {
        _nextAlarmInfo = nextAlarmFormatted;
      });
    } catch (e) {
      print('Erro ao carregar próximo alarme: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
              SizedBox(height: 16),
              Text(
                'Carregando...',
                style: TextStyles.body1,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Configurações',
          ),
          if (items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _resetChecklist,
              tooltip: 'Resetar lista',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Status Card
            Container(
              margin: EdgeInsets.all(16),
              child: ChecklistStatusWidget(
                items: items,
                nextAlarmInfo: _nextAlarmInfo,
                hasConfiguration: _hasConfiguration,
              ),
            ),
            
            // Add Item Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _buildAddItemSection(),
            ),
            
            SizedBox(height: 16),
            
            // Items List
            Expanded(
              child: _buildItemsList(),
            ),
          ],
        ),
      ),
      
      // Floating Action Button (Alarm)
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAddItemSection() {
    return CustomCard(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Adicionar item (ex: Carteira, Chaves...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _addItem(),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          SizedBox(width: 12),
          Container(
            height: 48,
            child: ElevatedButton(
              onPressed: _addItem,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Adicione itens à sua lista',
              style: TextStyles.heading3.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ex: Carteira, Chaves, Celular...',
              style: TextStyles.body2,
            ),
            SizedBox(height: 24),
            _buildQuickAddButtons(),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        return _buildItemCard(index);
      },
    );
  }

  Widget _buildQuickAddButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.commonItems.take(6).map((item) {
        return ActionChip(
          label: Text(
            item,
            style: TextStyle(fontSize: 12),
          ),
          onPressed: () => _addQuickItem(item),
          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
          labelStyle: TextStyle(color: AppTheme.primaryBlue),
          side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
        );
      }).toList(),
    );
  }

  Widget _buildItemCard(int index) {
    final item = items[index];
    
    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      margin: EdgeInsets.only(bottom: 8),
      child: CustomCard(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Checkbox(
            value: item.isChecked,
            onChanged: (_) => _toggleItem(index),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isChecked 
                  ? TextDecoration.lineThrough 
                  : TextDecoration.none,
              color: item.isChecked 
                  ? Colors.grey[600] 
                  : AppTheme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isChecked)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successGreen,
                  size: 20,
                ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppTheme.errorRed),
                onPressed: () => _removeItem(index),
                iconSize: 20,
              ),
            ],
          ),
          onTap: () => _toggleItem(index),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isAlarmPlaying ? _pulseAnimation.value : 1.0,
          child: FloatingActionButton.extended(
            onPressed: isAlarmPlaying ? _stopAlarm : _playAlarm,
            backgroundColor: isAlarmPlaying ? AppTheme.errorRed : AppTheme.primaryBlue,
            icon: Icon(
              isAlarmPlaying ? Icons.stop : Icons.alarm,
              color: Colors.white,
            ),
            label: Text(
              isAlarmPlaying ? 'Parar' : 'Alarme',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _addQuickItem(text);
      _controller.clear();
    }
  }

  Future<void> _addQuickItem(String name) async {
    try {
      final storageService = await StorageService.getInstance();
      final newItem = ChecklistItem(name: name);
      
      setState(() {
        items.add(newItem);
      });
      
      await storageService.saveChecklistItems(items);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Item "$name" adicionado!'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          duration: AppConstants.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      print('Erro ao adicionar item: $e');
      _showErrorSnackBar('Erro ao adicionar item');
    }
  }

  Future<void> _removeItem(int index) async {
    if (index < 0 || index >= items.length) return;
    
    final removedItem = items[index];
    
    try {
      setState(() {
        items.removeAt(index);
      });
      
      final storageService = await StorageService.getInstance();
      await storageService.saveChecklistItems(items);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item "${removedItem.name}" removido'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => _undoRemoveItem(index, removedItem),
          ),
          duration: AppConstants.undoSnackBarDuration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      print('Erro ao remover item: $e');
      _showErrorSnackBar('Erro ao remover item');
    }
  }

  Future<void> _undoRemoveItem(int index, ChecklistItem item) async {
    try {
      setState(() {
        items.insert(index, item);
      });
      
      final storageService = await StorageService.getInstance();
      await storageService.saveChecklistItems(items);
    } catch (e) {
      print('Erro ao desfazer remoção: $e');
    }
  }

  Future<void> _toggleItem(int index) async {
    if (index < 0 || index >= items.length) return;
    
    try {
      setState(() {
        items[index].isChecked = !items[index].isChecked;
      });
      
      final storageService = await StorageService.getInstance();
      await storageService.saveChecklistItems(items);
      
      // Verificar se todos os itens estão marcados
      if (items.every((item) => item.isChecked)) {
        _showCompletionDialog();
      }
    } catch (e) {
      print('Erro ao alterar item: $e');
      _showErrorSnackBar('Erro ao alterar item');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.celebration, color: AppTheme.successGreen, size: 28),
              SizedBox(width: 8),
              Text(
                'Parabéns!',
                style: TextStyle(color: AppTheme.successGreen),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.successGreen,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                'Você pegou tudo!\nPode sair tranquilo! 🎉',
                textAlign: TextAlign.center,
                style: TextStyles.body1,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetChecklist();
              },
              child: Text('Resetar Lista'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    
    // Mostrar notificação de sucesso
    _showSuccessNotification();
  }

  Future<void> _showSuccessNotification() async {
    try {
      final notificationService = await NotificationService.getInstance();
      await notificationService.showSuccessNotification();
    } catch (e) {
      print('Erro ao mostrar notificação de sucesso: $e');
    }
  }

  Future<void> _resetChecklist() async {
    try {
      setState(() {
        for (var item in items) {
          item.isChecked = false;
        }
      });
      
      final storageService = await StorageService.getInstance();
      await storageService.saveChecklistItems(items);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 8),
              Text('Lista resetada!'),
            ],
          ),
          backgroundColor: AppTheme.primaryBlue,
          duration: AppConstants.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      print('Erro ao resetar checklist: $e');
      _showErrorSnackBar('Erro ao resetar lista');
    }
  }

  Future<void> _playAlarm() async {
    if (isAlarmPlaying) return;
    
    try {
      setState(() {
        isAlarmPlaying = true;
      });
      
      _pulseController.repeat(reverse: true);
      
      final notificationService = await NotificationService.getInstance();
      await notificationService.showManualAlarm();
      
      // Parar alarme automaticamente após 30 segundos
      Future.delayed(AppConstants.alarmDuration, () {
        if (mounted && isAlarmPlaying) {
          _stopAlarm();
        }
      });
    } catch (e) {
      print('Erro ao tocar alarme: $e');
      _showErrorSnackBar('Erro ao ativar alarme');
    }
  }

  void _stopAlarm() {
    setState(() {
      isAlarmPlaying = false;
    });
    _pulseController.stop();
    _pulseController.reset();
    audioPlayer.stop();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    ).then((_) {
      // Recarregar dados após voltar das configurações
      _loadSettings();
      _loadNextAlarmInfo();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }
}