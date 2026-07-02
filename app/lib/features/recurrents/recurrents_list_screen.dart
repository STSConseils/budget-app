import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budget_app/core/format.dart';
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/models/recurrent.dart';
import 'package:budget_app/models/transaction.dart';
import 'package:budget_app/models/user_brief.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/recurrents/providers.dart';
import 'package:budget_app/features/recurrents/recurrent_status.dart';
import 'package:budget_app/features/transactions/providers.dart';
import 'package:budget_app/features/transactions/numeric_keypad.dart';

class RecurrentsListScreen extends ConsumerStatefulWidget {
  const RecurrentsListScreen({super.key});

  @override
  ConsumerState<RecurrentsListScreen> createState() =>
      _RecurrentsListScreenState();
}

class _RecurrentsListScreenState extends ConsumerState<RecurrentsListScreen> {
  Sens _filter = Sens.depense;

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(recurrentsAvecStatutProvider);
    final cats = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final catMap = {for (final c in cats) c.id: c};
    final members =
        ref.watch(householdMembersProvider).valueOrNull ?? [];

    final toPayItems = allItems
        .where((e) =>
            e.info.status == RecurrentStatus.aPayer ||
            e.info.status == RecurrentStatus.enRetard)
        .toList();
    final toPayCount = toPayItems.length;
    final toPayTotal =
        toPayItems.fold(0.0, (sum, e) => sum + e.rec.montant);

    final items =
        allItems.where((e) => e.rec.sens == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('RÉCURRENTS', style: AppTextStyles.sectionTitle),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.background,
        elevation: 0,
        onPressed: () => context.push('/recurrents/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Bandeau d'en-tête ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.hairlineStrong),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('À PAYER CE MOIS',
                            style: AppTextStyles.sectionTitle),
                        const SizedBox(height: 6),
                        Text(
                          '$toPayCount',
                          style: AppTextStyles.amount
                              .copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.hairlineLight,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MONTANT',
                              style: AppTextStyles.sectionTitle),
                          const SizedBox(height: 6),
                          AmountText(
                            toPayTotal,
                            style: AppTextStyles.amount
                                .copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Onglets pills ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypePill(
                  label: 'DÉPENSES',
                  selected: _filter == Sens.depense,
                  onTap: () => setState(() => _filter = Sens.depense),
                ),
                const SizedBox(width: 8),
                _TypePill(
                  label: 'REVENUS',
                  selected: _filter == Sens.revenu,
                  onTap: () => setState(() => _filter = Sens.revenu),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // ── Liste ──────────────────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Aucun récurrent.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: AppColors.hairlineLight,
                    ),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return _RecurrentTile(
                        item: item,
                        catMap: catMap,
                        onEdit: () => context.push(
                          '/recurrents/${item.rec.id}/edit',
                        ),
                        onConfirmPay: () => _showConfirmPaymentSheet(
                          context,
                          item.rec,
                          item.info,
                          catMap,
                          members,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showConfirmPaymentSheet(
    BuildContext context,
    Recurrent rec,
    RecurrentStatusInfo info,
    Map<String, Category> catMap,
    List<UserBrief> members,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _ConfirmPaymentSheet(
          rec: rec,
          info: info,
          catMap: catMap,
          members: members,
        ),
      ),
    );
  }
}

// ─── Type pill ───────────────────────────────────────────────────────────────

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

// ─── Tile récurrent ──────────────────────────────────────────────────────────

String _freqLabel(Frequence f) => switch (f) {
      Frequence.mensuel => 'mensuel',
      Frequence.trimestriel => 'trimestriel',
      Frequence.annuel => 'annuel',
    };

class _RecurrentTile extends StatelessWidget {
  const _RecurrentTile({
    required this.item,
    required this.catMap,
    required this.onEdit,
    required this.onConfirmPay,
  });

  final RecurrentAvecStatut item;
  final Map<String, Category> catMap;
  final VoidCallback onEdit;
  final VoidCallback onConfirmPay;

  Widget _badge(RecurrentStatusInfo info) {
    final badgeStyle = AppTextStyles.sectionTitle.copyWith(
      fontSize: 10,
      letterSpacing: 0.8,
    );
    switch (info.status) {
      case RecurrentStatus.paye:
        return Text('PAYÉ',
            style: badgeStyle.copyWith(color: AppColors.muted));
      case RecurrentStatus.aPayer:
        final n = info.joursRestants ?? 0;
        return Text('DANS $n J',
            style: badgeStyle.copyWith(color: AppColors.ink));
      case RecurrentStatus.enRetard:
        return Text('EN RETARD',
            style: badgeStyle.copyWith(color: AppColors.accent));
      case RecurrentStatus.inactif:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = item.rec;
    final info = item.info;
    final catName = catMap[rec.categorieId]?.nom ?? '';
    final showConfirm = info.status == RecurrentStatus.aPayer ||
        info.status == RecurrentStatus.enRetard;

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Colonne gauche ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          rec.libelle,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!rec.actif) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          color: AppColors.hairlineLight,
                          child: Text(
                            'INACTIF',
                            style: AppTextStyles.sectionTitle.copyWith(
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_freqLabel(rec.frequence)} · jour ${rec.jourDuMois} · $catName',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Colonne droite ────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCHF(rec.montant),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (info.status != RecurrentStatus.inactif) ...[
                  const SizedBox(height: 4),
                  _badge(info),
                ],
                if (showConfirm) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onConfirmPay,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      color: const Color.fromARGB(255, 241, 5, 5),
                      child: Text(
                        'Confirmer payé',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 244, 243, 239),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom sheet confirmation paiement ──────────────────────────────────────

class _ConfirmPaymentSheet extends ConsumerStatefulWidget {
  const _ConfirmPaymentSheet({
    required this.rec,
    required this.info,
    required this.catMap,
    required this.members,
  });

  final Recurrent rec;
  final RecurrentStatusInfo info;
  final Map<String, Category> catMap;
  final List<UserBrief> members;

  @override
  ConsumerState<_ConfirmPaymentSheet> createState() =>
      _ConfirmPaymentSheetState();
}

class _ConfirmPaymentSheetState
    extends ConsumerState<_ConfirmPaymentSheet> {
  late String _rawAmount;
  late DateTime _date;
  String? _auteurId;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.rec.montant;
    _rawAmount = m.truncateToDouble() == m
        ? m.toInt().toString()
        : m.toStringAsFixed(2);
    _date = DateTime.now();
    _auteurId = widget.rec.personneId ??
        ref.read(currentUserProvider)?.id ??
        (widget.members.isNotEmpty ? widget.members.first.id : null);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _openKeypad() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => NumericKeypad(
        initial: _rawAmount,
        onChanged: (v) => setState(() => _rawAmount = v),
        onDone: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_rawAmount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisir un montant valide.')),
      );
      return;
    }
    if (_auteurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionner un auteur.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final household =
          await ref.read(currentHouseholdProvider.future);
      if (!mounted || household == null) return;

      final cat = widget.catMap[widget.rec.categorieId];
      final note = _noteController.text.trim();
      final tx = TransactionModel(
        id: '',
        household: household.id,
        montant: amount,
        date: _date,
        categorieId: widget.rec.categorieId,
        auteurId: _auteurId!,
        note: note.isEmpty ? null : note,
        recurrentSourceId: widget.rec.id,
        categorieFiscale: cat?.categorieFiscaleDefault,
      );
      await ref.read(transactionsRepoProvider).create(tx);
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Paiement enregistré')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'enregistrement"),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _pillButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          border: Border.all(color: AppColors.hairlineStrong),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: selected ? AppColors.background : AppColors.ink,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.catMap[widget.rec.categorieId];
    final catName = cat?.nom ?? '';
    final echeance = widget.info.prochaineEcheance;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('CONFIRMER LE PAIEMENT',
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),

            // Récap
            Text(
              widget.rec.libelle,
              style: AppTextStyles.body.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (echeance != null) ...[
              const SizedBox(height: 4),
              Text(
                '$catName · Prévu pour le ${formatDateShortFr(echeance)}',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Montant
            InkWell(
              onTap: _openKeypad,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Montant', style: AppTextStyles.body),
                    Text.rich(
                      TextSpan(
                        text: formatRawAmount(_rawAmount),
                        style: AppTextStyles.amount.copyWith(fontSize: 22),
                        children: [
                          TextSpan(
                            text: ' CHF',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Date
            InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date du paiement', style: AppTextStyles.body),
                    Text(
                      formatDateShortFr(_date),
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Auteur
            Text('QUI ?', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            if (widget.members.isNotEmpty)
              Row(
                children: [
                  for (int i = 0; i < widget.members.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _pillButton(
                        label: widget.members[i].displayName,
                        selected: _auteurId == widget.members[i].id,
                        onTap: () => setState(
                            () => _auteurId = widget.members[i].id),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 20),

            // Note
            TextFormField(
              controller: _noteController,
              style: AppTextStyles.body.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Note (optionnel)',
                hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.muted, fontSize: 14),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide:
                      BorderSide(color: AppColors.hairlineStrong),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide:
                      BorderSide(color: AppColors.hairlineStrong),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide:
                      BorderSide(color: AppColors.ink, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton enregistrer
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Enregistrer le paiement',
                      style: AppTextStyles.bodyStrong,
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
