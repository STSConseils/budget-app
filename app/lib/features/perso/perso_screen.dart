import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_app/core/format.dart';
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/models/perso_entry.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/perso/providers.dart';
import 'package:budget_app/features/transactions/numeric_keypad.dart';

const _moisFr = [
  '',
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

void _showEntrySheet(BuildContext context, {PersoEntry? initial}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    builder: (_) => _PersoEntrySheet(initial: initial),
  );
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class PersoScreen extends ConsumerWidget {
  const PersoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(persoEntriesStreamProvider).valueOrNull ?? [];
    final totalMois = ref.watch(persoTotalMoisProvider);
    final totalAnnee = ref.watch(persoTotalAnneeProvider);
    final cats = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final catMap = {for (final c in cats) c.id: c};
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PERSO', style: AppTextStyles.sectionTitle),
            Text(
              'PRIVÉ · VISIBLE UNIQUEMENT PAR TOI',
              style: AppTextStyles.body.copyWith(
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.background,
        elevation: 0,
        onPressed: () => _showEntrySheet(context),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Bloc 1 — Héros total mois ──────────────────────────
                Text(
                  'DÉPENSES PERSO · ${_moisFr[now.month].toUpperCase()}',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: formatCHF(totalMois),
                    style: AppTextStyles.hero.copyWith(fontSize: 38),
                    children: [
                      TextSpan(
                        text: ' CHF',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.muted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total ${now.year} : ${formatCHF(totalAnnee)} CHF',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.hairlineStrong),
                const SizedBox(height: 24),

                // ── Bloc 2 — Journal ───────────────────────────────────
                Text('JOURNAL', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Aucune dépense perso enregistrée.',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final entry in entries)
                    _EntryRow(
                      entry: entry,
                      catName: catMap[entry.categorieId]?.nom,
                      onTap: () => _showEntrySheet(context, initial: entry),
                    ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Entry row ───────────────────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.onTap,
    this.catName,
  });

  final PersoEntry entry;
  final String? catName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = entry.note?.isNotEmpty == true ? entry.note! : '—';
    final subParts = [formatDateShortFr(entry.date)];
    if (catName != null) subParts.add(catName!);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subParts.join(' · '),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${formatCHF(entry.montant)} CHF',
                  style: AppTextStyles.amount.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
          ),
        ),
        const Divider(height: 1, color: AppColors.hairlineLight),
      ],
    );
  }
}

// ─── Bottom sheet (ajout / édition) ──────────────────────────────────────────

class _PersoEntrySheet extends ConsumerStatefulWidget {
  const _PersoEntrySheet({this.initial});
  final PersoEntry? initial;

  @override
  ConsumerState<_PersoEntrySheet> createState() => _PersoEntrySheetState();
}

class _PersoEntrySheetState extends ConsumerState<_PersoEntrySheet> {
  final _noteController = TextEditingController();
  String _rawAmount = '';
  DateTime _date = DateTime.now();
  String? _categorieId;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final e = widget.initial!;
      _noteController.text = e.note ?? '';
      final m = e.montant;
      _rawAmount = m.truncateToDouble() == m
          ? m.toInt().toString()
          : m.toStringAsFixed(2);
      _date = e.date;
      _categorieId = e.categorieId;
    }
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
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_rawAmount);
    if (amount == null || amount <= 0) {
      _snack('Saisir un montant valide.');
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final entry = PersoEntry(
        id: widget.initial?.id ?? '',
        ownerId: user.id,
        montant: amount,
        date: _date,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        categorieId: _categorieId,
      );

      final repo = ref.read(persoLedgerRepoProvider);
      if (_isEdit) {
        await repo.update(entry);
      } else {
        await repo.create(entry);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Enregistré'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (mounted) _snack("Erreur lors de l'enregistrement", isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette entrée ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(persoLedgerRepoProvider).delete(widget.initial!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _snack('Erreur lors de la suppression', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.accent : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final depenseCats = cats
        .where((c) => c.type == CategoryType.depense)
        .toList()
      ..sort((a, b) => a.nom.compareTo(b.nom));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'MODIFIER DÉPENSE PERSO' : 'NOUVELLE DÉPENSE PERSO',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 20),

              // ── Montant ──────────────────────────────────────────────
              Text('MONTANT', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _openKeypad,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.hairlineStrong),
                    ),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: formatRawAmount(_rawAmount),
                      style: AppTextStyles.amount.copyWith(
                        fontSize: 22,
                        color: _rawAmount.isEmpty
                            ? AppColors.muted
                            : AppColors.ink,
                      ),
                      children: [
                        TextSpan(
                          text: ' CHF',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Date ─────────────────────────────────────────────────
              Text('DATE', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.hairlineStrong),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        formatDateShortFr(_date),
                        style: AppTextStyles.body,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Catégorie (optionnelle) ───────────────────────────────
              Text('CATÉGORIE (OPTIONNELLE)', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _CatChip(
                    label: '(aucune)',
                    selected: _categorieId == null,
                    onTap: () => setState(() => _categorieId = null),
                  ),
                  for (final cat in depenseCats)
                    _CatChip(
                      label: cat.nom,
                      selected: _categorieId == cat.id,
                      onTap: () => setState(() => _categorieId = cat.id),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Note ─────────────────────────────────────────────────
              Text('NOTE (OPTIONNELLE)', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLength: 120,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Note (optionnel)',
                  hintStyle:
                      AppTextStyles.body.copyWith(color: AppColors.muted),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.hairlineStrong),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.hairlineStrong),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.ink, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 28),

              // ── Supprimer (édition) ───────────────────────────────────
              if (_isEdit) ...[
                OutlinedButton(
                  onPressed: _saving ? null : _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.accent),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    foregroundColor: AppColors.accent,
                  ),
                  child: const Text('Supprimer cette entrée'),
                ),
                const SizedBox(height: 10),
              ],

              // ── Enregistrer ───────────────────────────────────────────
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enregistrer'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          border: Border.all(color: AppColors.hairlineStrong),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.background : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
