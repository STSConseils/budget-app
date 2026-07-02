import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budget_app/core/format.dart';
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/transactions/providers.dart';
import 'package:budget_app/features/dashboard/fiscal_labels.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(transactionsByCategoryProvider(categoryId));
    final cats = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final members = ref.watch(householdMembersProvider).valueOrNull ?? [];
    final memberMap = {for (final u in members) u.id: u};

    final catMatches = cats.where((c) => c.id == categoryId);
    final category = catMatches.isEmpty ? null : catMatches.first;

    final realise = txs.fold(0.0, (sum, t) => sum + t.montant);
    final budget = category?.budgetMensuel;

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.nom ?? '', style: AppTextStyles.sectionTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Résumé
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AmountText(
                  realise,
                  style: AppTextStyles.amount.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  budget != null
                      ? 'RÉALISÉ CE MOIS-CI · BUDGET ${formatCHF(budget)} CHF'
                      : 'RÉALISÉ CE MOIS-CI',
                  style: AppTextStyles.sectionTitle,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste des transactions
          Expanded(
            child: txs.isEmpty
                ? Center(
                    child: Text(
                      'Aucune transaction ce mois-ci.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: txs.length,
                    separatorBuilder: (_, index) => const Divider(
                      height: 1,
                      color: AppColors.hairlineLight,
                    ),
                    itemBuilder: (_, i) {
                      final t = txs[i];
                      final authorName =
                          memberMap[t.auteurId]?.displayName ?? t.auteurId;
                      final hasFiscal =
                          t.categorieFiscale != null &&
                          t.categorieFiscale != 'non_deductible';
                      return InkWell(
                        onTap: () => context.push('/transactions/${t.id}/edit'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Col gauche
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.note ?? '—',
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${formatDateShortFr(t.date)} · $authorName',
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Col droite
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${formatCHF(t.montant)} CHF',
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  if (hasFiscal) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.hairlineLight,
                                        ),
                                      ),
                                      child: Text(
                                        fiscalPosteLabel(t.categorieFiscale!) ??
                                            t.categorieFiscale!,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 10,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(width: 8),
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

          // Bouton historique (désactivé)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.hairlineStrong),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                "Voir tout l'historique",
                style: AppTextStyles.body.copyWith(color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
