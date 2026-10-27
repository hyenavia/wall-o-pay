import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('Categories')),
          bottom: TabBar(
            tabs: [
              Tab(text: context.tr('Expense')),
              Tab(text: context.tr('Income')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showCategoryForm(context),
          icon: const Icon(Icons.add),
          label: Text(context.tr('New category')),
        ),
        body: const TabBarView(
          children: [
            _CategoryList(type: TxType.expense),
            _CategoryList(type: TxType.income),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.type});

  final TxType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(context.tr('Could not load data: {error}', {'error': e})),
      ),
      data: (all) {
        final list = all.where((c) => c.type == type).toList();
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.category_outlined,
            message: context.tr('No categories yet.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final c = list[i];
            final color = Color(c.colorValue);
            return ListTile(
              onTap: () => showCategoryForm(context, category: c),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(iconFor(c.icon), color: color),
              ),
              title: Text(context.tr(c.name)),
              trailing: const Icon(Icons.edit_outlined, size: 20),
            );
          },
        );
      },
    );
  }
}

/// Form tambah kategori, atau ubah jika [category] diisi.
Future<void> showCategoryForm(BuildContext context, {Category? category}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CategoryForm(category: category),
  );
}

class CategoryForm extends ConsumerStatefulWidget {
  const CategoryForm({super.key, this.category});

  final Category? category;

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> {
  late final TextEditingController _name;
  late TxType _type;
  late String _icon;
  late int _color;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _type = c?.type ?? TxType.expense;
    _icon = c?.icon ?? 'more';
    _color = c?.colorValue ?? categoryColors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.tr('Category name cannot be empty.'));
      return;
    }
    final db = ref.read(databaseProvider);
    final c = widget.category;
    if (c == null) {
      await db.addCategory(name: name, type: _type, icon: _icon, colorValue: _color);
    } else {
      await db.updateCategory(c.id, name: name, icon: _icon, colorValue: _color);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr(
          'Delete category "{name}"?',
          {'name': context.tr(widget.category!.name)},
        )),
        content: Text(context.tr(
          'Existing transactions in this category are kept, but it will no longer appear as a choice.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).deleteCategory(widget.category!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isNew = widget.category == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isNew) ...[
              SegmentedButton<TxType>(
                segments: [
                  ButtonSegment(value: TxType.expense, label: Text(context.tr('Expense'))),
                  ButtonSegment(value: TxType.income, label: Text(context.tr('Income'))),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: appInput(context, label: context.tr('Category name')),
            ),
            const SizedBox(height: 16),
            Text(context.tr('Icon'), style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in categoryIcons.entries)
                  ChoiceChip(
                    showCheckmark: false,
                    label: Icon(e.value, size: 20),
                    selected: _icon == e.key,
                    onSelected: (_) => setState(() => _icon = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(context.tr('Color'), style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in categoryColors)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: _color == c
                            ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                            : null,
                      ),
                      child: _color == c
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: Text(context.tr('Save'))),
            if (!isNew)
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(context.tr('Delete category')),
              ),
          ],
        ),
      ),
    );
  }
}
