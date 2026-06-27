import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budget_app/core/format.dart';
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/models/recurrent.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/transactions/providers.dart';
import 'package:budget_app/features/transactions/numeric_keypad.dart';

class RecurrentFormScreen extends ConsumerStatefulWidget {
  const RecurrentFormScreen({super.key, this.recurrentId});

  /// null → mode création, non-null → mode édition.
  final String? recurrentId;

  @override
  ConsumerState<RecurrentFormScreen> createState() =>
      _RecurrentFormScreenState();
}

class _RecurrentFormScreenState
    extends ConsumerState<RecurrentFormScreen> {
  final _libelleController = TextEditingController();

  String _rawAmount = '';
  Sens _sens = Sens.depense;
  bool _sensLocked = false;
  String? _categorieId;
  Frequence _frequence = Frequence.mensuel;
  int _jourDuMois = 1;
  String? _personneId;
  bool _actif = true;
  bool _saving = false;

  String? _householdId;
  String? _editId;

  bool get _isEdit => widget.recurrentId != null;

  @override
  void initState() {
    super.initState();
    _personneId = ref.read(currentUserProvider)?.id;

    if (_isEdit) {
      final recs =
          ref.read(recurrentsAllStreamProvider).valueOrNull ?? [];
      Recurrent? match;
      for (final r in recs) {
        if (r.id == widget.recurrentId) {
          match = r;
          break;
        }
      }
      if (match != null) _initFromRecurrent(match);
    }
  }

  void _initFromRecurrent(Recurrent rec) {
    _editId = rec.id;
    _householdId = rec.household;
    _libelleController.text = rec.libelle;
    final m = rec.montant;
    _rawAmount = m.truncateToDouble() == m
        ? m.toInt().toString()
        : m.toStringAsFixed(2);
    _sens = rec.sens;
    _sensLocked = true;
    _categorieId = rec.categorieId;
    _frequence = rec.frequence;
    _jourDuMois = rec.jourDuMois;
    _personneId = rec.personneId;
    _actif = rec.actif;
  }

  @override
  void dispose() {
    _libelleController.dispose();
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

  Future<void> _save() async {
    final libelle = _libelleController.text.trim();
    if (libelle.isEmpty) {
      _snack('Le libellé est requis.');
      return;
    }
    final amount = double.tryParse(_rawAmount);
    if (amount == null || amount <= 0) {
      _snack('Saisir un montant valide.');
      return;
    }
    if (_categorieId == null) {
      _snack('Sélectionner une catégorie.');
      return;
    }

    setState(() => _saving = true);
    try {
      String householdId;
      if (_isEdit && _householdId != null) {
        householdId = _householdId!;
      } else {
        final h = await ref.read(currentHouseholdProvider.future);
        if (!mounted || h == null) return;
        householdId = h.id;
      }

      final rec = Recurrent(
        id: _editId ?? '',
        household: householdId,
        libelle: libelle,
        montant: amount,
        sens: _sens,
        frequence: _frequence,
        jourDuMois: _jourDuMois,
        categorieId: _categorieId!,
        actif: _actif,
        personneId: _personneId,
      );

      if (_isEdit) {
        await ref.read(recurrentsRepoProvider).update(rec);
      } else {
        await ref.read(recurrentsRepoProvider).create(rec);
      }

      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (mounted) {
        _snack("Erreur lors de l'enregistrement",
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final id = widget.recurrentId!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce récurrent ?'),
        content: const Text(
          'Les transactions passées qui en sont issues seront conservées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.accent),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(recurrentsRepoProvider).delete(id);
      if (!mounted) return;
      context.pop();
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

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          border: Border.all(
            color: onTap == null
                ? AppColors.hairlineLight
                : AppColors.hairlineStrong,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: selected
                ? AppColors.background
                : (onTap == null ? AppColors.muted : AppColors.ink),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesStreamProvider).valueOrNull ?? [];
    final filteredCats = categories
        .where((c) =>
            c.type ==
            (_sens == Sens.depense
                ? CategoryType.depense
                : CategoryType.revenu))
        .toList()
      ..sort((a, b) => a.nom.compareTo(b.nom));

    final members =
        ref.watch(householdMembersProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'MODIFIER RÉCURRENT' : 'NOUVEAU RÉCURRENT',
          style: AppTextStyles.sectionTitle,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Bouton suppression (édition seulement) ────────────────
          if (_isEdit) ...[
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                  'Supprimer le récurrent',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
            const Divider(height: 20),
          ],

          // ── Contenu scrollable ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bloc 1 — Sens
                      Text('SENS', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _pill(
                              label: 'Dépense',
                              selected: _sens == Sens.depense,
                              onTap: _sensLocked
                                  ? null
                                  : () => setState(() {
                                        _sens = Sens.depense;
                                        _categorieId = null;
                                      }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _pill(
                              label: 'Revenu',
                              selected: _sens == Sens.revenu,
                              onTap: _sensLocked
                                  ? null
                                  : () => setState(() {
                                        _sens = Sens.revenu;
                                        _categorieId = null;
                                      }),
                            ),
                          ),
                        ],
                      ),
                      if (_sensLocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Le sens ne peut pas être modifié.',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Bloc 2 — Libellé
                      Text('LIBELLÉ', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _libelleController,
                        maxLength: 60,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Ex : Hypothèque',
                          hintStyle: AppTextStyles.body
                              .copyWith(color: AppColors.muted),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                                color: AppColors.hairlineStrong),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                                color: AppColors.hairlineStrong),
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

                      // Bloc 3 — Montant
                      Text('MONTANT', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _openKeypad,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 0),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.hairlineStrong),
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
                                  style: AppTextStyles.body.copyWith(
                                      color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bloc 4 — Catégorie
                      Text('CATÉGORIE', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: filteredCats.map((cat) {
                          final selected = cat.id == _categorieId;
                          return GestureDetector(
                            onTap: () => setState(() =>
                                _categorieId =
                                    selected ? null : cat.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.ink
                                    : Colors.transparent,
                                border: Border.all(
                                    color: AppColors.hairlineStrong),
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

                      // Bloc 5 — Fréquence
                      Text('FRÉQUENCE', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _pill(
                              label: 'Mensuel',
                              selected:
                                  _frequence == Frequence.mensuel,
                              onTap: () => setState(
                                  () => _frequence = Frequence.mensuel),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _pill(
                              label: 'Trimestriel',
                              selected:
                                  _frequence == Frequence.trimestriel,
                              onTap: () => setState(() =>
                                  _frequence = Frequence.trimestriel),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _pill(
                              label: 'Annuel',
                              selected:
                                  _frequence == Frequence.annuel,
                              onTap: () => setState(
                                  () => _frequence = Frequence.annuel),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bloc 6 — Jour du mois
                      Text('JOUR DU MOIS',
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '$_jourDuMois',
                          style: AppTextStyles.amount
                              .copyWith(fontSize: 24),
                        ),
                      ),
                      SliderTheme(
                        data: const SliderThemeData(
                          activeTrackColor: AppColors.ink,
                          inactiveTrackColor: AppColors.hairlineStrong,
                          thumbColor: AppColors.ink,
                          overlayColor: Colors.transparent,
                          trackHeight: 2.0,
                        ),
                        child: Slider(
                          min: 1.0,
                          max: 31.0,
                          divisions: 30,
                          value: _jourDuMois.toDouble(),
                          onChanged: (v) =>
                              setState(() => _jourDuMois = v.round()),
                        ),
                      ),
                      Text(
                        "Si le jour n'existe pas dans le mois (ex. 31 "
                        "février), l'échéance tombe le dernier jour.",
                        style: AppTextStyles.body.copyWith(
                            fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 24),

                      // Bloc 7 — Personne
                      Text(
                        _sens == Sens.depense
                            ? 'PAYÉ PAR'
                            : 'PERÇU PAR',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 8),
                      if (members.isNotEmpty)
                        Row(
                          children: [
                            for (int i = 0; i < members.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _pill(
                                  label: members[i].displayName,
                                  selected:
                                      _personneId == members[i].id,
                                  onTap: () => setState(
                                      () => _personneId = members[i].id),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Expanded(
                              child: _pill(
                                label: '(personne)',
                                selected: _personneId == null,
                                onTap: () =>
                                    setState(() => _personneId = null),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Bloc 8 — Actif
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Actif', style: AppTextStyles.body),
                          Switch(
                            value: _actif,
                            activeThumbColor: AppColors.ink,
                            onChanged: (v) =>
                                setState(() => _actif = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Bloc 9 — Boutons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _saving ? null : () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize:
                                    const Size.fromHeight(48),
                                side: const BorderSide(
                                    color: AppColors.hairlineStrong),
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
