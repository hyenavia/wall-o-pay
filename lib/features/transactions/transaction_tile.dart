import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/tables.dart' show TxType;

/// Satu baris transaksi: ikon kategori, judul, subjudul, nominal, dan keterangan kecil.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.entry,
    required this.category,
    required this.trailingNote,
    this.onTap,
  });

  final TransactionEntry entry;
  final Category? category;
  final String trailingNote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = entry.type == TxType.income;
    final catName = categoryName(context, category);
    final color = Color(category?.colorValue ?? 0xFF607D8B);
    final title = entry.note.isEmpty ? catName : entry.note;
    final subtitle =
        entry.note.isEmpty
            ? context.tr(isIncome ? 'Income' : 'Expense')
            : catName;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CategoryBadge(icon: iconFor(category?.icon ?? 'more'), color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${rupiah(entry.amount)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isIncome ? AppColors.income : AppColors.expense,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trailingNote,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Beberapa baris transaksi dalam satu kartu, dipisah garis tipis.
class TransactionGroupCard extends StatelessWidget {
  const TransactionGroupCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      indent: 70,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) divider,
            children[i],
          ],
        ],
      ),
    );
  }
}
