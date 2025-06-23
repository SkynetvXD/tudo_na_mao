import 'package:flutter/material.dart';
import '../models/checklist_item.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'custom_card.dart';

class ChecklistStatusWidget extends StatelessWidget {
  final List<ChecklistItem> items;
  final String? nextAlarmInfo;
  final bool hasConfiguration;

  const ChecklistStatusWidget({
    Key? key,
    required this.items,
    this.nextAlarmInfo,
    this.hasConfiguration = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uncheckedCount = items.where((item) => !item.isChecked).length;
    final totalCount = items.length;
    final isComplete = uncheckedCount == 0 && totalCount > 0;
    
    if (totalCount == 0 && hasConfiguration) {
      return _buildEmptyListWarning();
    }
    
    if (totalCount == 0) {
      return _buildEmptyState();
    }
    
    if (isComplete) {
      return _buildCompleteStatus();
    }
    
    return _buildProgressStatus(uncheckedCount, totalCount);
  }

  Widget _buildEmptyState() {
    return StatusCard(
      title: 'Lista vazia',
      subtitle: 'Adicione itens à sua lista para começar',
      icon: Icons.checklist,
      backgroundColor: Colors.grey[100]!,
      iconColor: Colors.grey[400]!,
      textColor: Colors.grey[600]!,
      animated: false,
    );
  }

  Widget _buildEmptyListWarning() {
    return StatusCard(
      title: 'Atenção!',
      subtitle: 'Você não tem itens na lista!\nAdicione seus itens essenciais.',
      icon: Icons.warning,
      backgroundColor: AppTheme.errorRed.withOpacity(0.1),
      iconColor: AppTheme.errorRed,
      textColor: AppTheme.errorRed,
      actions: [
        Text(
          nextAlarmInfo ?? '',
          style: TextStyles.caption.copyWith(
            color: AppTheme.errorRed.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStatus() {
    return StatusCard(
      title: 'Tudo pronto! 🎉',
      subtitle: 'Você pode sair tranquilo!',
      icon: Icons.check_circle,
      backgroundColor: AppTheme.successGreen.withOpacity(0.1),
      iconColor: AppTheme.successGreen,
      textColor: AppTheme.successGreen,
      actions: nextAlarmInfo != null
          ? [
              Text(
                nextAlarmInfo!,
                style: TextStyles.caption.copyWith(
                  color: AppTheme.successGreen.withOpacity(0.8),
                ),
              ),
            ]
          : null,
    );
  }

  Widget _buildProgressStatus(int uncheckedCount, int totalCount) {
    final progress = (totalCount - uncheckedCount) / totalCount;
    
    return StatusCard(
      title: 'Faltam $uncheckedCount ${uncheckedCount == 1 ? 'item' : 'itens'}',
      subtitle: '${totalCount - uncheckedCount} de $totalCount completos',
      icon: Icons.pending_actions,
      backgroundColor: AppTheme.warningOrange.withOpacity(0.1),
      iconColor: AppTheme.warningOrange,
      textColor: AppTheme.warningOrange,
      actions: [
        Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.warningOrange.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warningOrange),
            ),
            if (nextAlarmInfo != null) ...[
              SizedBox(height: 8),
              Text(
                nextAlarmInfo!,
                style: TextStyles.caption.copyWith(
                  color: AppTheme.warningOrange.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class AlarmStatusWidget extends StatelessWidget {
  final bool isEnabled;
  final String? nextAlarmTime;
  final VoidCallback? onTap;

  const AlarmStatusWidget({
    Key? key,
    required this.isEnabled,
    this.nextAlarmTime,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      isClickable: onTap != null,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isEnabled ? AppTheme.primaryBlue : Colors.grey[400]!)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEnabled ? Icons.alarm_on : Icons.alarm_off,
              color: isEnabled ? AppTheme.primaryBlue : Colors.grey[400],
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnabled ? 'Alarme ativo' : 'Alarme desativado',
                  style: TextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? AppTheme.textDark : Colors.grey[500],
                  ),
                ),
                if (nextAlarmTime != null) ...[
                  SizedBox(height: 4),
                  Text(
                    nextAlarmTime!,
                    style: TextStyles.body2.copyWith(
                      color: isEnabled ? AppTheme.primaryBlue : Colors.grey[400],
                    ),
                  ),
                ] else if (isEnabled) ...[
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
          if (onTap != null)
            Icon(
              Icons.settings,
              size: 20,
              color: Colors.grey[400],
            ),
        ],
      ),
    );
  }
}

class QuickStatsWidget extends StatelessWidget {
  final List<ChecklistItem> items;
  final bool hasConfiguration;

  const QuickStatsWidget({
    Key? key,
    required this.items,
    this.hasConfiguration = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completedCount = items.where((item) => item.isChecked).length;
    final totalCount = items.length;
    final pendingCount = totalCount - completedCount;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            totalCount.toString(),
            Icons.list,
            AppTheme.primaryBlue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completos',
            completedCount.toString(),
            Icons.check_circle,
            AppTheme.successGreen,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pendentes',
            pendingCount.toString(),
            Icons.pending,
            AppTheme.warningOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyles.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemProgressWidget extends StatelessWidget {
  final List<ChecklistItem> items;
  final bool showPercentage;

  const ItemProgressWidget({
    Key? key,
    required this.items,
    this.showPercentage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SizedBox.shrink();
    }

    final completedCount = items.where((item) => item.isChecked).length;
    final totalCount = items.length;
    final progress = completedCount / totalCount;
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso',
              style: TextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showPercentage)
              Text(
                '$percentage%',
                style: TextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getProgressColor(progress),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
        ),
        SizedBox(height: 4),
        Text(
          '$completedCount de $totalCount itens completos',
          style: TextStyles.caption,
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress == 1.0) {
      return AppTheme.successGreen;
    } else if (progress >= 0.7) {
      return AppTheme.primaryBlue;
    } else if (progress >= 0.3) {
      return AppTheme.warningOrange;
    } else {
      return AppTheme.errorRed;
    }
  }
}