import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budget_app/core/format.dart';
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/models/transaction.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/transactions/providers.dart';
import 'package:budget_app/features/transactions/numeric_keypad.dart';
import 'package:budget_app/features/dashboard/fiscal_labels.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.transactionId});

  /// null → mode création, non-null → mode édition.
  final String? transactionId;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  String _rawAmount = '';
  CategoryType _selectedType = CategoryType.depense;
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();
  String? _auteurId;
  String _categorieFiscale = 'non_deductible';
  bool _fiscalExpanded = false;
  bool _fiscalManuallyTouched = false;
  final _noteController = TextEditingController();
  bool _saving = false;

  String? _editId;
  String? _household;
  String? _recurrentSourceId;
  bool _loadingTx = false;

  bool get _isEdit => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadingTx = true;
      _loadTransaction();
    } else {
      _auteurId = ref.read(currentUserProvider)?.id;
    }
  }

  Future<void> _loadTransaction() async {
    try {
      final tx = await ref
          .read(transactionsRepoProvider)
          .getById(widget.transactionId!);
      if (!mounted) return;
      final categories = ref.read(categoriesStreamProvider).valueOrNull ?? [];
      var type = CategoryType.depense;
      for (final c in categories) {
        if (c.id == tx.categorieId) {
          type = c.type;
          break;
        }
      }
      setState(() {
        _editId = tx.id;
        _household = tx.household;
        _rawAmount = tx.montant.truncateToDouble() == tx.montant
            ? tx.montant.toInt().toString()
            : tx.montant.toStringAsFixed(2);
        _selectedType = type;
        _selectedCategoryId = tx.categorieId;
        _date = tx.date;
        _auteurId = tx.auteurId;
        _categorieFiscale = tx.categorieFiscale ?? 'non_deductible';
        _fiscalManuallyTouched = tx.categorieFiscale != null;
        _recurrentSourceId = tx.recurrentSourceId;
        _noteController.text = tx.note ?? '';
        _loadingTx = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTx = false);
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
        onChanged: (val) => setState(() => _rawAmount = val),
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
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionner une catégorie.')),
      );
      return;
    }
    final auteurId = _auteurId;
    if (auteurId == null || auteurId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sélectionner un auteur.')));
      return;
    }

    setState(() => _saving = true);
    try {
      String householdId;
      if (_isEdit && _household != null) {
        householdId = _household!;
      } else {
        final household = await ref.read(currentHouseholdProvider.future);
        if (!mounted) return;
        if (household == null) return;
        householdId = household.id;
      }

      final note = _noteController.text.trim();
      final tx = TransactionModel(
        id: _editId ?? '',
        household: householdId,
        montant: amount,
        date: _date,
        categorieId: _selectedCategoryId!,
        auteurId: auteurId,
        note: note.isEmpty ? null : note,
        categorieFiscale: _selectedType == CategoryType.depense
            ? _categorieFiscale
            : null,
        recurrentSourceId: _recurrentSourceId,
      );
      if (_isEdit) {
        await ref.read(transactionsRepoProvider).update(tx);
      } else {
        await ref.read(transactionsRepoProvider).create(tx);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction enregistrée'),
          duration: Duration(seconds: 3),
        ),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'enregistrement"),
          backgroundColor: AppColors.accent,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final id = widget.transactionId!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette transaction ?'),
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
      await ref.read(transactionsRepoProvider).delete(id);
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    double height = 44,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
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
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final filteredCats =
        categories.where((c) => c.type == _selectedType).toList()
          ..sort((a, b) => a.nom.compareTo(b.nom));
    final members = ref.watch(householdMembersProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'MODIFIER LA TRANSACTION' : 'NOUVELLE TRANSACTION',
          style: AppTextStyles.sectionTitle,
        ),
      ),
      body: _isEdit && _loadingTx
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isEdit) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: OutlinedButton(
                      onPressed: _saving ? null : _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        side: const BorderSide(color: AppColors.accent),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        foregroundColor: AppColors.accent,
                      ),
                      child: Text(
                        'Supprimer la transaction',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  if (_recurrentSourceId != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Text(
                        "Issue d'un récurrent — la définition récurrente "
                        "n'est pas affectée par cette modification.",
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  const Divider(height: 20),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Bloc 1 — Montant
                            Center(
                              child: GestureDetector(
                                onTap: _openKeypad,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        formatRawAmount(_rawAmount),
                                        style: AppTextStyles.hero.copyWith(
                                          fontSize: 54,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                          color: _rawAmount.isEmpty
                                              ? AppColors.muted
                                              : AppColors.ink,
                                        ),
                                      ),
                                      Text(
                                        'CHF',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.muted,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 24),

                            // Bloc 2 — Sens
                            Row(
                              children: [
                                Expanded(
                                  child: _pill(
                                    label: 'Dépense',
                                    selected:
                                        _selectedType == CategoryType.depense,
                                    onTap: () => setState(() {
                                      _selectedType = CategoryType.depense;
                                      _selectedCategoryId = null;
                                      _fiscalManuallyTouched = false;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _pill(
                                    label: 'Revenu',
                                    selected:
                                        _selectedType == CategoryType.revenu,
                                    onTap: () => setState(() {
                                      _selectedType = CategoryType.revenu;
                                      _selectedCategoryId = null;
                                      _categorieFiscale = 'non_deductible';
                                      _fiscalExpanded = false;
                                      _fiscalManuallyTouched = false;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Bloc 3 — Catégorie
                            Text(
                              'CATÉGORIE',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: filteredCats.map((cat) {
                                final selected = cat.id == _selectedCategoryId;
                                return GestureDetector(
                                  onTap: () {
                                    final newId = selected ? null : cat.id;
                                    setState(() {
                                      _selectedCategoryId = newId;
                                      if (newId != null &&
                                          !_fiscalManuallyTouched) {
                                        final df = cat.categorieFiscaleDefault;
                                        if (df != null) _categorieFiscale = df;
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.ink
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: AppColors.hairlineStrong,
                                      ),
                                    ),
                                    child: Text(
                                      cat.nom,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? AppColors.background
                                            : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            // Bloc 4 — Date
                            const Divider(height: 1),
                            InkWell(
                              onTap: _pickDate,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Date', style: AppTextStyles.body),
                                    Text(
                                      formatDateShortFr(_date),
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 24),

                            // Bloc 5 — Auteur
                            Text('QUI ?', style: AppTextStyles.sectionTitle),
                            const SizedBox(height: 12),
                            if (members.isEmpty)
                              Text(
                                'Chargement...',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.muted,
                                ),
                              )
                            else
                              Row(
                                children: [
                                  for (int i = 0; i < members.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    Expanded(
                                      child: _pill(
                                        label: members[i].displayName,
                                        selected: members[i].id == _auteurId,
                                        onTap: () => setState(
                                          () => _auteurId = members[i].id,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                            // Bloc 6 — Catégorie fiscale (dépense only, repliable)
                            if (_selectedType == CategoryType.depense) ...[
                              const SizedBox(height: 20),
                              InkWell(
                                onTap: () => setState(
                                  () => _fiscalExpanded = !_fiscalExpanded,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _categorieFiscale == 'non_deductible'
                                          ? 'Catégorie fiscale'
                                          : (fiscalPosteLabel(
                                                  _categorieFiscale,
                                                ) ??
                                                'Catégorie fiscale'),
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 13,
                                        color:
                                            _categorieFiscale ==
                                                'non_deductible'
                                            ? AppColors.muted
                                            : AppColors.ink,
                                      ),
                                    ),
                                    Icon(
                                      _fiscalExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      size: 18,
                                      color: AppColors.muted,
                                    ),
                                  ],
                                ),
                              ),
                              if (_fiscalExpanded) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: fiscalCodes.map((code) {
                                    final selected = code == _categorieFiscale;
                                    final label = code == 'non_deductible'
                                        ? 'Non déductible'
                                        : (fiscalPosteLabel(code) ?? code);
                                    return GestureDetector(
                                      onTap: () => setState(() {
                                        _categorieFiscale = code;
                                        _fiscalExpanded = false;
                                        _fiscalManuallyTouched = true;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppColors.ink
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: AppColors.hairlineStrong,
                                          ),
                                        ),
                                        child: Text(
                                          label,
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: selected
                                                ? AppColors.background
                                                : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                            const SizedBox(height: 20),

                            // Bloc 7 — Note
                            TextFormField(
                              controller: _noteController,
                              maxLines: 3,
                              style: AppTextStyles.body,
                              decoration: InputDecoration(
                                hintText: 'Note (optionnel)',
                                hintStyle: AppTextStyles.body.copyWith(
                                  color: AppColors.muted,
                                ),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(
                                    color: AppColors.hairlineStrong,
                                  ),
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(
                                    color: AppColors.hairlineStrong,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(
                                    color: AppColors.ink,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Bloc 8 — Boutons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.pop(),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      side: const BorderSide(
                                        color: AppColors.hairlineStrong,
                                      ),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      foregroundColor: AppColors.ink,
                                    ),
                                    child: const Text('Annuler'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
