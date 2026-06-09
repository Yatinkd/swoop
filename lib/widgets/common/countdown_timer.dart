import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/plan_formatters.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime target;
  final bool compact;

  const CountdownTimer({
    super.key,
    required this.target,
    this.compact = false,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late String _text;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _update());
  }

  void _update() {
    if (!mounted) return;
    setState(() => _text = PlanFormatters.formatCountdown(widget.target));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: AppTextStyles.caption.copyWith(
        fontSize: widget.compact ? 11 : 12,
        color: AppColors.text,
      ),
    );
  }
}
