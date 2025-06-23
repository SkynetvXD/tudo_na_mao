import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class DaySelectorWidget extends StatefulWidget {
  final List<bool> selectedDays;
  final ValueChanged<List<bool>> onDaysChanged;
  final bool enabled;
  final double? itemSize;

  const DaySelectorWidget({
    Key? key,
    required this.selectedDays,
    required this.onDaysChanged,
    this.enabled = true,
    this.itemSize,
  }) : super(key: key);

  @override
  _DaySelectorWidgetState createState() => _DaySelectorWidgetState();
}

class _DaySelectorWidgetState extends State<DaySelectorWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(7, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 150),
        vsync: this,
      );
    });

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    // Animar dias selecionados inicialmente
    for (int i = 0; i < widget.selectedDays.length; i++) {
      if (widget.selectedDays[i]) {
        _animationControllers[i].forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        return _buildDayButton(index);
      }),
    );
  }

  Widget _buildDayButton(int index) {
    final isSelected = widget.selectedDays[index];
    final size = widget.itemSize ?? 44.0;

    return GestureDetector(
      onTap: widget.enabled ? () => _toggleDay(index) : null,
      child: AnimatedBuilder(
        animation: _scaleAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimations[index].value,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.successGreen
                    : (widget.enabled ? Colors.grey[200] : Colors.grey[100]),
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(
                        color: widget.enabled ? Colors.grey[300]! : Colors.grey[200]!,
                        width: 1,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.successGreen.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  AppConstants.weekDays[index],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (widget.enabled ? Colors.grey[600] : Colors.grey[400]),
                    fontWeight: FontWeight.bold,
                    fontSize: size < 40 ? 10 : 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleDay(int index) {
    if (!widget.enabled) return;

    final newSelectedDays = List<bool>.from(widget.selectedDays);
    newSelectedDays[index] = !newSelectedDays[index];

    // Animar a mudança
    if (newSelectedDays[index]) {
      _animationControllers[index].forward();
    } else {
      _animationControllers[index].reverse();
    }

    widget.onDaysChanged(newSelectedDays);
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class CompactDaySelectorWidget extends StatelessWidget {
  final List<bool> selectedDays;
  final ValueChanged<List<bool>> onDaysChanged;
  final bool enabled;

  const CompactDaySelectorWidget({
    Key? key,
    required this.selectedDays,
    required this.onDaysChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DaySelectorWidget(
      selectedDays: selectedDays,
      onDaysChanged: onDaysChanged,
      enabled: enabled,
      itemSize: 32.0,
    );
  }
}

class DaysSummaryWidget extends StatelessWidget {
  final List<bool> selectedDays;
  final TextStyle? textStyle;

  const DaysSummaryWidget({
    Key? key,
    required this.selectedDays,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedDays.where((day) => day).length;
    
    if (selectedCount == 0) {
      return Text(
        'Nenhum dia selecionado',
        style: textStyle ?? TextStyles.body2.copyWith(
          color: AppTheme.errorRed,
        ),
      );
    }
    
    if (selectedCount == 7) {
      return Text(
        'Todos os dias',
        style: textStyle ?? TextStyles.body2.copyWith(
          color: AppTheme.successGreen,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    
    // Verificar se são dias úteis (seg-sex)
    final weekdays = selectedDays.sublist(0, 5);
    final weekends = selectedDays.sublist(5, 7);
    
    if (weekdays.every((day) => day) && weekends.every((day) => !day)) {
      return Text(
        'Dias úteis',
        style: textStyle ?? TextStyles.body2.copyWith(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    
    if (weekends.every((day) => day) && weekdays.every((day) => !day)) {
      return Text(
        'Finais de semana',
        style: textStyle ?? TextStyles.body2.copyWith(
          color: AppTheme.warningOrange,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    
    // Listar dias específicos
    final selectedDayNames = <String>[];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        selectedDayNames.add(AppConstants.weekDays[i]);
      }
    }
    
    return Text(
      selectedDayNames.join(', '),
      style: textStyle ?? TextStyles.body2.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class DaysQuickSelectWidget extends StatelessWidget {
  final List<bool> selectedDays;
  final ValueChanged<List<bool>> onDaysChanged;
  final bool enabled;

  const DaysQuickSelectWidget({
    Key? key,
    required this.selectedDays,
    required this.onDaysChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DaySelectorWidget(
          selectedDays: selectedDays,
          onDaysChanged: onDaysChanged,
          enabled: enabled,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickSelectButton(
                'Dias úteis',
                Icons.work,
                () => _selectWeekdays(),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildQuickSelectButton(
                'Todos',
                Icons.calendar_month,
                () => _selectAll(),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildQuickSelectButton(
                'Limpar',
                Icons.clear,
                () => _clearAll(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickSelectButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled ? AppTheme.primaryBlue : Colors.grey[400],
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: enabled ? AppTheme.primaryBlue : Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectWeekdays() {
    final newSelectedDays = [true, true, true, true, true, false, false];
    onDaysChanged(newSelectedDays);
  }

  void _selectAll() {
    final newSelectedDays = List.filled(7, true);
    onDaysChanged(newSelectedDays);
  }

  void _clearAll() {
    final newSelectedDays = List.filled(7, false);
    onDaysChanged(newSelectedDays);
  }
}