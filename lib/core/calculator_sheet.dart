/// Komponen kalkulator mini berbentuk bottom sheet untuk membantu pengguna
/// menghitung nominal transaksi (+, -, ×, ÷) sebelum dimasukkan ke form.
library;

import 'package:flutter/material.dart';

import 'format.dart';
import 'l10n.dart';
import 'theme.dart';

/// Membuka bottom sheet kalkulator mini untuk menghitung nominal transaksi.
/// Mengembalikan nilai hasil perhitungan akhir berupa integer nominal Rupiah.
Future<int?> showCalculatorSheet(
  BuildContext context, {
  int? initialValue,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CalculatorSheet(initialValue: initialValue),
  );
}

/// Widget utama kalkulator mini yang menyimpan state angka input dan operasi aritmatika.
class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key, this.initialValue});

  final int? initialValue;

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _currentInput = '';
  int? _storedValue;
  String? _pendingOp;
  String _formulaText = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue! > 0) {
      _currentInput = widget.initialValue.toString();
      _formulaText = formatThousands(widget.initialValue!);
    }
  }

  int get _currentVal => int.tryParse(_currentInput) ?? 0;

  int _compute(int a, int b, String op) {
    switch (op) {
      case '+':
        return (a + b).clamp(0, 999999999999);
      case '-':
        return (a - b).clamp(0, 999999999999);
      case '×':
        return (a * b).clamp(0, 999999999999);
      case '÷':
        if (b == 0) return a;
        return (a / b).round().clamp(0, 999999999999);
      default:
        return b;
    }
  }

  int get _displayResult {
    if (_storedValue != null && _pendingOp != null) {
      final b = _currentInput.isNotEmpty ? _currentVal : _storedValue!;
      return _compute(_storedValue!, b, _pendingOp!);
    }
    return _currentVal;
  }

  void _updateFormula() {
    final sb = StringBuffer();
    if (_storedValue != null) {
      sb.write(formatThousands(_storedValue!));
    }
    if (_pendingOp != null) {
      sb.write(' $_pendingOp ');
    }
    if (_currentInput.isNotEmpty) {
      sb.write(formatThousands(int.tryParse(_currentInput) ?? 0));
    }
    _formulaText = sb.toString();
  }

  void _onDigit(String d) {
    setState(() {
      if (_currentInput.length >= 12) return;
      if (_currentInput == '0') {
        _currentInput = d;
      } else {
        _currentInput += d;
      }
      _updateFormula();
    });
  }

  void _onTripleZero() {
    setState(() {
      if (_currentInput.isEmpty || _currentInput == '0') {
        _currentInput = '0';
      } else if (_currentInput.length <= 9) {
        _currentInput += '000';
      }
      _updateFormula();
    });
  }

  void _onOperator(String op) {
    setState(() {
      if (_currentInput.isNotEmpty) {
        if (_storedValue != null && _pendingOp != null) {
          _storedValue = _compute(_storedValue!, _currentVal, _pendingOp!);
        } else {
          _storedValue = _currentVal;
        }
        _currentInput = '';
      } else {
        _storedValue ??= 0;
      }
      _pendingOp = op;
      _updateFormula();
    });
  }

  void _onEquals() {
    setState(() {
      if (_storedValue != null && _pendingOp != null) {
        final b = _currentInput.isNotEmpty ? _currentVal : _storedValue!;
        final res = _compute(_storedValue!, b, _pendingOp!);
        _currentInput = res.toString();
        _storedValue = null;
        _pendingOp = null;
        _formulaText = formatThousands(res);
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_currentInput.isNotEmpty) {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      } else if (_pendingOp != null) {
        _pendingOp = null;
        if (_storedValue != null) {
          _currentInput = _storedValue.toString();
          _storedValue = null;
        }
      }
      _updateFormula();
    });
  }

  void _onClear() {
    setState(() {
      if (_currentInput.isNotEmpty) {
        _currentInput = '';
      } else {
        _storedValue = null;
        _pendingOp = null;
      }
      _updateFormula();
    });
  }

  void _onApply() {
    final finalResult = _displayResult;
    Navigator.pop(context, finalResult);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.themeColors;
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.calculate_outlined, color: colors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  context.tr('Calculator'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Display Screen
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formulaText.isEmpty ? '0' : _formulaText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: muted,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      rupiah(_displayResult),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.income,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Keypad Grid
            Column(
              children: [
                // Row 1: C, ⌫, ÷, ×
                Row(
                  children: [
                    _calcBtn(
                      label: 'C',
                      onPressed: _onClear,
                      color: AppColors.expense.withValues(alpha: 0.15),
                      textColor: AppColors.expense,
                    ),
                    const SizedBox(width: 8),
                    _calcBtn(
                      icon: Icons.backspace_outlined,
                      onPressed: _onBackspace,
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    _calcBtn(
                      label: '÷',
                      onPressed: () => _onOperator('÷'),
                      color: colors.heroBackground.withValues(alpha: 0.25),
                      textColor: colors.primary,
                      isOperator: true,
                    ),
                    const SizedBox(width: 8),
                    _calcBtn(
                      label: '×',
                      onPressed: () => _onOperator('×'),
                      color: colors.heroBackground.withValues(alpha: 0.25),
                      textColor: colors.primary,
                      isOperator: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: 7, 8, 9, -
                Row(
                  children: [
                    _calcBtn(label: '7', onPressed: () => _onDigit('7')),
                    const SizedBox(width: 8),
                    _calcBtn(label: '8', onPressed: () => _onDigit('8')),
                    const SizedBox(width: 8),
                    _calcBtn(label: '9', onPressed: () => _onDigit('9')),
                    const SizedBox(width: 8),
                    _calcBtn(
                      label: '-',
                      onPressed: () => _onOperator('-'),
                      color: colors.heroBackground.withValues(alpha: 0.25),
                      textColor: colors.primary,
                      isOperator: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 3: 4, 5, 6, +
                Row(
                  children: [
                    _calcBtn(label: '4', onPressed: () => _onDigit('4')),
                    const SizedBox(width: 8),
                    _calcBtn(label: '5', onPressed: () => _onDigit('5')),
                    const SizedBox(width: 8),
                    _calcBtn(label: '6', onPressed: () => _onDigit('6')),
                    const SizedBox(width: 8),
                    _calcBtn(
                      label: '+',
                      onPressed: () => _onOperator('+'),
                      color: colors.heroBackground.withValues(alpha: 0.25),
                      textColor: colors.primary,
                      isOperator: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 4: 1, 2, 3, =
                Row(
                  children: [
                    _calcBtn(label: '1', onPressed: () => _onDigit('1')),
                    const SizedBox(width: 8),
                    _calcBtn(label: '2', onPressed: () => _onDigit('2')),
                    const SizedBox(width: 8),
                    _calcBtn(label: '3', onPressed: () => _onDigit('3')),
                    const SizedBox(width: 8),
                    _calcBtn(
                      label: '=',
                      onPressed: _onEquals,
                      color: colors.heroBackground,
                      textColor: Colors.white,
                      isOperator: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 5: 0, 000, Use Amount
                Row(
                  children: [
                    _calcBtn(label: '0', onPressed: () => _onDigit('0')),
                    const SizedBox(width: 8),
                    _calcBtn(
                      label: '000',
                      onPressed: _onTripleZero,
                      textColor: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _onApply,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: const Icon(Icons.check, size: 20),
                          label: Text(
                            context.tr('Use Amount'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcBtn({
    String? label,
    IconData? icon,
    required VoidCallback onPressed,
    Color? color,
    Color? textColor,
    bool isOperator = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.surfaceContainerHighest.withValues(alpha: 0.28);
    final fg = textColor ?? scheme.onSurface;

    return Expanded(
      child: SizedBox(
        height: 52,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: fg, size: 20)
                  : Text(
                      label ?? '',
                      style: TextStyle(
                        fontSize: isOperator ? 22 : 18,
                        fontWeight: isOperator ? FontWeight.w700 : FontWeight.w600,
                        color: fg,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
