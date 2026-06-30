import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budget_app/core/format.dart';
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/dashboard/providers.dart';
import 'package:budget_app/features/epargne/providers.dart';

const _moisFr = [
  '',
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BUDGET', style: AppTextStyles.sectionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            color: AppColors.muted,
            tooltip: 'Aide',
            onPressed: () => context.push('/aide'),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, size: 20),
            color: AppColors.muted,
            tooltip: 'Perso (privé)',
            onPressed: () => context.push('/perso'),
          ),
          IconButton(
            icon: const Icon(Icons.replay, size: 20),
            color: AppColors.muted,
            tooltip: 'Récurrents',
            onPressed: () => context.push('/recurrents'),
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            color: AppColors.muted,
            tooltip: 'Catégories',
            onPressed: () => context.push('/categories'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            color: AppColors.muted,
            tooltip: 'Déconnexion',
            onPressed: () {
              ref.read(authRepoProvider).logout();
              ref.invalidate(currentUserProvider);
              ref.invalidate(currentHouseholdProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.background,
        elevation: 0,
        onPressed: () => context.push('/transactions/new'),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _VisionHeader(),
                SizedBox(height: 32),
                _PositionHero(),
                SizedBox(height: 32),
                Divider(height: 1),
                SizedBox(height: 24),
                _TripleGrid(),
                SizedBox(height: 32),
                Divider(height: 1),
                SizedBox(height: 24),
                _VentilationSection(),
                SizedBox(height: 32),
                Divider(height: 1),
                SizedBox(height: 24),
                _FiscalSection(),
                SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisionHeader extends StatelessWidget {
  const _VisionHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VISION DU MOIS', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text(
          '${_moisFr[now.month]} ${now.year}',
          style: AppTextStyles.body.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _PositionHero extends ConsumerWidget {
  const _PositionHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProjeteeProvider);
    final estimee = ref.watch(epargneEstimeeProvider);
    final isNegative = position < 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('POSITION PROJETÉE FIN DE MOIS', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        AmountText(
          position,
          withSign: true,
          style: AppTextStyles.hero.copyWith(
            color: isNegative ? AppColors.accent : AppColors.ink,
          ),
        ),
        if (estimee != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/epargne'),
            child: Row(
              children: [
                Text(
                  'Épargne ',
                  style: AppTextStyles.body.copyWith(color: AppColors.muted),
                ),
                AmountText(
                  estimee,
                  style: AppTextStyles.body.copyWith(color: AppColors.muted),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.muted),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/epargne'),
            child: Row(
              children: [
                Text(
                  'Renseigner mon épargne',
                  style: AppTextStyles.body.copyWith(color: AppColors.accent),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.accent),
              ],
            ),
          ),
        ],
    );
  }
}

class _TripleGrid extends ConsumerWidget {
  const _TripleGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenusRealises = ref.watch(realiseRevenusProvider);
    final revenusPrevus = ref.watch(prevuRevenusProvider);
    final depensesRealisees = ref.watch(realiseDepensesProvider);
    final depensesPrevues = ref.watch(prevuDepensesProvider);

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _GridCell(
              label: 'REVENUS',
              value: revenusRealises + revenusPrevus,
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.hairlineLight,
          ),
          Expanded(
            child: _GridCell(label: 'RÉALISÉ', value: depensesRealisees),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.hairlineLight,
          ),
          Expanded(
            child: _GridCell(label: 'PRÉVU', value: depensesPrevues),
          ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          AmountText(value),
        ],
      ),
    );
  }
}

class _VentilationSection extends ConsumerWidget {
  const _VentilationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buckets = ref.watch(ventilationParCategorieProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('PAR RUBRIQUE', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 16),
        if (buckets.isEmpty)
          Text(
            'Aucune rubrique budgétée.',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          )
        else
          for (int i = 0; i < buckets.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _CategoryBar(
              bucket: buckets[i],
              onTap: () => context.push(
                '/categories/${buckets[i].category.id}',
              ),
            ),
          ],
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.bucket, required this.onTap});

  final CategorieBucket bucket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final budget = bucket.category.budgetMensuel ?? 0;
    final realise = bucket.realise;
    final isOver = budget > 0 && realise > budget;
    final ratio = budget > 0 ? (realise / budget).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bucket.category.nom,
                  style: AppTextStyles.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${formatCHF(realise)} / ${formatCHF(budget)} CHF',
                style: AppTextStyles.body.copyWith(
                  color: isOver ? AppColors.accent : AppColors.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 4,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    color: AppColors.barTrack,
                  ),
                  Container(
                    width: constraints.maxWidth * ratio,
                    color: isOver ? AppColors.accent : AppColors.ink,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiscalSection extends ConsumerWidget {
  const _FiscalSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agregats = ref.watch(fiscaleAggregatProvider).take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('DÉDUCTIONS FISCALES', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text(
          'Cumul annuel',
          style: AppTextStyles.body.copyWith(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (agregats.isEmpty)
          Text(
            'Aucune déduction fiscale enregistrée.',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          )
        else
          for (int i = 0; i < agregats.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _FiscalRow(agregat: agregats[i]),
          ],
      ],
    );
  }
}

class _FiscalRow extends StatelessWidget {
  const _FiscalRow({required this.agregat});

  final FiscaleAggregat agregat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(agregat.poste, style: AppTextStyles.body),
          ),
          AmountText(agregat.total),
        ],
      ),
    );
  }
}
