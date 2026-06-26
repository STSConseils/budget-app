import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:budget_app/core/theme.dart';

const _monthsFr = [
  '',
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

final _numberFormat = NumberFormat('#,##0', 'en_US');

/// Formats [value] with Swiss apostrophe thousands separator.
/// Examples: 12400 → "12'400", -3240 → "-3'240", +3240 withSign → "+3'240".
String formatCHF(num value, {bool withSign = false}) {
  final abs = value.abs().round();
  final swiss = _numberFormat.format(abs).replaceAll(',', "'");
  if (value < 0) return '-$swiss';
  if (withSign && value > 0) return '+$swiss';
  return swiss;
}

/// Formats a raw amount string with Swiss apostrophe, preserving partial decimals.
/// Examples: "1250" → "1'250", "1250." → "1'250.", "1250.5" → "1'250.5", "" → "0".
String formatRawAmount(String raw) {
  if (raw.isEmpty) return '0';
  final dotIdx = raw.indexOf('.');
  final intStr = dotIdx == -1 ? raw : raw.substring(0, dotIdx);
  final decStr = dotIdx == -1 ? '' : raw.substring(dotIdx);
  final intVal = int.tryParse(intStr.isEmpty ? '0' : intStr) ?? 0;
  return _numberFormat.format(intVal).replaceAll(',', "'") + decStr;
}

/// Formats a date in short French: "24 juin" or "24 juin 26" for past years.
String formatDateShortFr(DateTime d) {
  final now = DateTime.now();
  final month = _monthsFr[d.month];
  if (d.year == now.year) return '${d.day} $month';
  final shortYear = (d.year % 100).toString().padLeft(2, '0');
  return '${d.day} $month $shortYear';
}

/// Parses a hex color string (e.g. "#E23A1E") into a Flutter Color.
Color hexColor(String hex) =>
    Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

/// Renders a formatted amount with an attenuated "CHF" suffix.
class AmountText extends StatelessWidget {
  const AmountText(
    this.value, {
    super.key,
    this.withSign = false,
    this.style,
  });

  final num value;
  final bool withSign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? AppTextStyles.amount;
    final suffixSize = (base.fontSize ?? 20) * 0.65;
    return Text.rich(
      TextSpan(
        text: formatCHF(value, withSign: withSign),
        style: base,
        children: [
          TextSpan(
            text: ' CHF',
            style: base.copyWith(
              color: AppColors.muted,
              fontSize: suffixSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
