import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TimePickerWidget extends StatelessWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final String? label;
  final bool enabled;

  const TimePickerWidget({
    Key? key,
    required this.time,
    required this.onTimeChanged,
    this.label,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyles.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
        ],
        InkWell(
          onTap: enabled ? () => _showTimePicker(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: enabled ? Colors.white : Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: enabled ? AppTheme.primaryBlue : Colors.grey[400],
                  size: 24,
                ),
                SizedBox(width: 16),
                Expanded(
                  child:                   Text(
                    _formatTime(context, time),
                    style: TextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppTheme.textDark : Colors.grey[500],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: enabled ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != time) {
      onTimeChanged(picked);
    }
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time);
  }
}

class TimeRangePickerWidget extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;
  final String? startLabel;
  final String? endLabel;
  final bool enabled;

  const TimeRangePickerWidget({
    Key? key,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    this.startLabel,
    this.endLabel,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TimePickerWidget(
            time: startTime,
            onTimeChanged: onStartTimeChanged,
            label: startLabel ?? 'Início',
            enabled: enabled,
          ),
        ),
        SizedBox(width: 16),
        Container(
          padding: EdgeInsets.only(top: startLabel != null ? 30 : 0),
          child: Icon(
            Icons.arrow_forward,
            color: AppTheme.primaryBlue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: TimePickerWidget(
            time: endTime,
            onTimeChanged: onEndTimeChanged,
            label: endLabel ?? 'Fim',
            enabled: enabled,
          ),
        ),
      ],
    );
  }
}

class CompactTimePickerWidget extends StatelessWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final bool enabled;
  final double? width;

  const CompactTimePickerWidget({
    Key? key,
    required this.time,
    required this.onTimeChanged,
    this.enabled = true,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      child: InkWell(
        onTap: enabled ? () => _showTimePicker(context) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled ? AppTheme.primaryBlue : Colors.grey[300]!,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: enabled ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.grey[50],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: enabled ? AppTheme.primaryBlue : Colors.grey[400],
              ),
              SizedBox(width: 6),
              Text(
                _formatTime(context, time),
                style: TextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppTheme.primaryBlue : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != time) {
      onTimeChanged(picked);
    }
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}