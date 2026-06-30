import 'package:flutter/material.dart';
import 'package:budget_app/core/format.dart';
import 'package:budget_app/core/theme.dart';

class NumericKeypad extends StatefulWidget {
  const NumericKeypad({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.onDone,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final VoidCallback onDone;

  @override
  State<NumericKeypad> createState() => _NumericKeypadState();
}

class _NumericKeypadState extends State<NumericKeypad> {
  late String _raw;

  @override
  void initState() {
    super.initState();
    _raw = widget.initial;
  }

  void _tap(String key) {
    final next = _compute(key);
    if (next == _raw) return;
    setState(() => _raw = next);
    widget.onChanged(next);
  }

  String _compute(String key) {
    if (key == '⌫') {
      return _raw.isEmpty ? '' : _raw.substring(0, _raw.length - 1);
    }
    if (key == '.') {
      if (_raw.contains('.')) return _raw;
      return _raw.isEmpty ? '0.' : '$_raw.';
    }
    if (_raw.contains('.') && _raw.split('.').last.length >= 2) return _raw;
    return _raw + key;
  }

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
    final hasDecimal = _raw.contains('.');

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    formatRawAmount(_raw),
                    style: AppTextStyles.hero,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'CHF',
                    style: AppTextStyles.body.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.0,
            ),
            itemCount: keys.length,
            itemBuilder: (_, i) {
              final key = keys[i];
              final disabled = key == '.' && hasDecimal;
              return InkWell(
                onTap: disabled ? null : () => _tap(key),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.hairlineLight,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    key,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: disabled ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: ElevatedButton(
              onPressed: widget.onDone,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text('Valider', style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),),
            ),
          ),
        ],
      ),
    );
  }
}
