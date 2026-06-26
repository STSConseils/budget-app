import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budget_app/core/format.dart';
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/categories/icon_picker.dart';
import 'package:budget_app/features/dashboard/fiscal_labels.dart';

const _kColors = [
  '#1F4D7A', '#5B8DEF', '#4A9B8E', '#7AA877',
  '#2E7D32', '#E0C97E', '#C89B6A', '#A8754F',
  '#E08A7E', '#CF8F7E', '#9B86B8', '#8A6A8A',
];

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.categoryId});

  final String? categoryId;

  @override
  ConsumerState<CategoryFormScreen> createState() =>
      _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _nomController = TextEditingController();
  final _budgetController = TextEditingController();
  CategoryType _selectedType = CategoryType.depense;
  bool _typeFixed = false;
  String? _selectedColor;
  String? _selectedIcon;
  String? _fiscalDefault;
  bool _saving = false;

  bool get _isEdit => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final cats = ref.read(categoriesStreamProvider).valueOrNull ?? [];
      final matches = cats.where((c) => c.id == widget.categoryId!);
      if (matches.isNotEmpty) _initFromCategory(matches.first);
    }
  }

  void _initFromCategory(Category cat) {
    _nomController.text = cat.nom;
    _selectedType = cat.type;
    _typeFixed = true;
    _selectedColor = cat.couleur;
    _selectedIcon = cat.icone;
    if (cat.budgetMensuel != null) {
      _budgetController.text = cat.budgetMensuel!.toStringAsFixed(0);
    }
    _fiscalDefault = cat.categorieFiscaleDefault;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nom = _nomController.text.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis.')),
      );
      return;
    }

    final budgetStr = _budgetController.text.trim();
    double? budget;
    if (budgetStr.isNotEmpty) {
      budget = double.tryParse(budgetStr.replaceAll(',', '.'));
      if (budget == null || budget <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Montant budget invalide.')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      if (!_isEdit) {
        final household = await ref.read(currentHouseholdProvider.future);
        if (!mounted) return;
        if (household == null) return;

        await ref.read(categoriesRepoProvider).create(Category(
              id: '',
              household: household.id,
              nom: nom,
              type: _selectedType,
              couleur: _selectedColor,
              icone: _selectedIcon,
              budgetMensuel: budget,
              categorieFiscaleDefault:
                  _selectedType == CategoryType.depense ? _fiscalDefault : null,
            ));
      } else {
        final cats = ref.read(categoriesStreamProvider).valueOrNull ?? [];
        final matches = cats.where((c) => c.id == widget.categoryId!);
        if (matches.isEmpty) return;
        final existing = matches.first;

        await ref.read(categoriesRepoProvider).update(Category(
              id: widget.categoryId!,
              household: existing.household,
              nom: nom,
              type: existing.type,
              couleur: _selectedColor,
              icone: _selectedIcon,
              budgetMensuel: budget,
              categorieFiscaleDefault:
                  existing.type == CategoryType.depense ? _fiscalDefault : null,
            ));
      }
      if (!mounted) return;
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
    final catId = widget.categoryId!;
    var dialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Vérification en cours…'),
          ],
        ),
      ),
    );

    try {
      final txCount =
          await ref.read(transactionsRepoProvider).countByCategory(catId);
      final recCount =
          await ref.read(recurrentsRepoProvider).countByCategory(catId);
      final persoCount =
          await ref.read(persoLedgerRepoProvider).countByCategory(catId);

      if (!mounted) return;
      Navigator.of(context).pop();
      dialogOpen = false;

      final total = txCount + recCount + persoCount;

      if (total > 0) {
        final parts = <String>[];
        if (txCount > 0) {
          parts.add('$txCount transaction${txCount > 1 ? 's' : ''}');
        }
        if (recCount > 0) {
          parts.add('$recCount récurrent${recCount > 1 ? 's' : ''}');
        }
        if (persoCount > 0) {
          parts.add('$persoCount entrée${persoCount > 1 ? 's' : ''} perso');
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Impossible de supprimer'),
            content: Text('Catégorie utilisée par : ${parts.join(', ')}.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer cette catégorie ?'),
            content: const Text('Cette action est irréversible.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          await ref.read(categoriesRepoProvider).delete(catId);
          if (mounted) context.pop();
        }
      }
    } catch (_) {
      if (mounted) {
        if (dialogOpen) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la vérification'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    }
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
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

  String _fiscalLabel(String? code) {
    if (code == null) return '(aucune)';
    if (code == 'non_deductible') return 'Non déductible';
    return fiscalPosteLabel(code) ?? code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'MODIFIER LA CATÉGORIE' : 'NOUVELLE CATÉGORIE',
          style: AppTextStyles.sectionTitle,
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.accent,
              tooltip: 'Supprimer',
              onPressed: _saving ? null : _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nom
                Text('NOM', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                TextField(
                  controller: _nomController,
                  maxLength: 40,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Ex : Alimentation',
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
                const SizedBox(height: 24),

                // Type
                Text('TYPE', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _pill(
                        label: 'Dépense',
                        selected: _selectedType == CategoryType.depense,
                        onTap: _typeFixed
                            ? null
                            : () => setState(
                                () => _selectedType = CategoryType.depense),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _pill(
                        label: 'Revenu',
                        selected: _selectedType == CategoryType.revenu,
                        onTap: _typeFixed
                            ? null
                            : () => setState(
                                () => _selectedType = CategoryType.revenu),
                      ),
                    ),
                  ],
                ),
                if (_typeFixed)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Le type ne peut pas être modifié.',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Couleur
                Text('COULEUR', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kColors.map((hex) {
                    final isSelected = hex == _selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: hexColor(hex),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: AppColors.ink, width: 2.5)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Icône
                Text('ICÔNE', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kCategoryIcons.entries.map((entry) {
                    final isSelected = entry.key == _selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() =>
                          _selectedIcon = isSelected ? null : entry.key),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.ink : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.ink
                                : AppColors.hairlineStrong,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          size: 20,
                          color: isSelected
                              ? AppColors.background
                              : AppColors.muted,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Budget mensuel
                Text(
                  'BUDGET MENSUEL (optionnel)',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _budgetController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: 'CHF',
                    hintStyle:
                        AppTextStyles.body.copyWith(color: AppColors.muted),
                    suffixStyle:
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

                // Catégorie fiscale par défaut (dépense seulement)
                if (_selectedType == CategoryType.depense) ...[
                  const SizedBox(height: 24),
                  Text(
                    'CATÉGORIE FISCALE PAR DÉFAUT',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pré-rempli automatiquement sur les nouvelles transactions.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <String?>[null, ...fiscalCodes].map((code) {
                      final isSelected = code == _fiscalDefault;
                      return GestureDetector(
                        onTap: () => setState(() => _fiscalDefault = code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.ink : Colors.transparent,
                            border:
                                Border.all(color: AppColors.hairlineStrong),
                          ),
                          child: Text(
                            _fiscalLabel(code),
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.background
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 32),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => context.pop(),
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
    );
  }
}
