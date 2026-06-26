import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budget_app/core/format.dart';
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/categories/icon_picker.dart';

class CategoriesListScreen extends ConsumerStatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  ConsumerState<CategoriesListScreen> createState() =>
      _CategoriesListScreenState();
}

class _CategoriesListScreenState extends ConsumerState<CategoriesListScreen> {
  CategoryType _filter = CategoryType.depense;

  @override
  Widget build(BuildContext context) {
    final allCats = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final cats = allCats
        .where((c) => c.type == _filter)
        .toList()
      ..sort((a, b) => a.nom.compareTo(b.nom));

    return Scaffold(
      appBar: AppBar(
        title: Text('CATÉGORIES', style: AppTextStyles.sectionTitle),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.background,
        elevation: 0,
        onPressed: () => context.push('/categories/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TypePill(
                    label: 'DÉPENSES',
                    selected: _filter == CategoryType.depense,
                    onTap: () =>
                        setState(() => _filter = CategoryType.depense),
                  ),
                  const SizedBox(width: 8),
                  _TypePill(
                    label: 'REVENUS',
                    selected: _filter == CategoryType.revenu,
                    onTap: () =>
                        setState(() => _filter = CategoryType.revenu),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Expanded(
            child: cats.isEmpty
                ? Center(
                    child: Text(
                      'Aucune catégorie.',
                      style:
                          AppTextStyles.body.copyWith(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    itemCount: cats.length,
                    separatorBuilder: (_, index) => const Divider(
                      height: 1,
                      color: AppColors.hairlineLight,
                    ),
                    itemBuilder: (_, i) {
                      final cat = cats[i];
                      return InkWell(
                        onTap: () =>
                            context.push('/categories/${cat.id}/edit'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: cat.couleur != null
                                      ? hexColor(cat.couleur!)
                                      : AppColors.muted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (cat.icone != null &&
                                  kCategoryIcons.containsKey(cat.icone)) ...[
                                Icon(
                                  kCategoryIcons[cat.icone!]!,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cat.nom, style: AppTextStyles.body),
                                    if (cat.budgetMensuel != null)
                                      Text(
                                        '${formatCHF(cat.budgetMensuel!)} CHF / mois',
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          border: Border.all(color: AppColors.hairlineStrong),
        ),
        child: Text(
          label,
          style: AppTextStyles.sectionTitle.copyWith(
            color: selected ? AppColors.background : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
