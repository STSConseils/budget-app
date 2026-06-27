import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_app/core/format.dart';
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/models/epargne.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/epargne/providers.dart';
import 'package:budget_app/features/transactions/numeric_keypad.dart';

void _showRecalageSheet(BuildContext context, {Epargne? initial}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    builder: (_) => _RecalageSheet(initial: initial),
  );
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class EpargneScreen extends ConsumerWidget {
  const EpargneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(epargneStatsProvider);
    final history = ref.watch(epargneHistoryProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('ÉPARGNE', style: AppTextStyles.sectionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            color: AppColors.muted,
            tooltip: 'Nouveau relevé',
            onPressed: () => _showRecalageSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroBloc(stats: stats),
                const SizedBox(height: 32),
                const Divider(height: 1),
                const SizedBox(height: 24),
                if (history.length >= 2) ...[
                  Text('ÉVOLUTION', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: _SavingsChart(
                      history: history,
                      estimee: stats.estimee,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                ],
                Text('RELEVÉS', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 16),
                if (history.isEmpty)
                  Text(
                    'Aucun relevé. Ajoutez votre premier recalage via le + en haut.',
                    style: AppTextStyles.body.copyWith(color: AppColors.muted),
                  )
                else
                  for (final snap in history.reversed)
                    _SnapshotRow(
                      snapshot: snap,
                      onTap: () => _showRecalageSheet(context, initial: snap),
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

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroBloc extends StatelessWidget {
  const _HeroBloc({required this.stats});
  final EpargneStats stats;

  @override
  Widget build(BuildContext context) {
    final estimee = stats.estimee;
    final dernierReel = stats.dernierReel;
    final flux = stats.fluxDepuis;
    final dateRecalage = stats.dateRecalage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ÉPARGNE ESTIMÉE', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        estimee != null
            ? AmountText(estimee, style: AppTextStyles.hero)
            : Text(
                '—',
                style: AppTextStyles.hero.copyWith(color: AppColors.muted),
              ),
        if (dernierReel != null) ...[
          const SizedBox(height: 20),
          const Divider(height: 1),
          _StatRow(
            label: 'Dernier relevé réel',
            value: '${formatCHF(dernierReel)} CHF',
            sub: dateRecalage != null
                ? 'au ${formatDateShortFr(dateRecalage)}'
                : null,
          ),
          if (flux != null) ...[
            const Divider(height: 1),
            _StatRow(
              label: 'Flux depuis le relevé',
              value: '${formatCHF(flux, withSign: true)} CHF',
              valueColor: flux < 0 ? AppColors.accent : AppColors.ink,
            ),
          ],
        ],
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body),
                if (sub != null)
                  Text(
                    sub!,
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTextStyles.amount.copyWith(
              color: valueColor ?? AppColors.ink,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart ───────────────────────────────────────────────────────────────────

class _SavingsChart extends StatelessWidget {
  const _SavingsChart({required this.history, this.estimee});
  final List<Epargne> history;
  final double? estimee;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SavingsPainter(
        history: history,
        estimee: estimee,
      ),
    );
  }
}

class _SavingsPainter extends CustomPainter {
  const _SavingsPainter({required this.history, this.estimee});

  final List<Epargne> history;
  final double? estimee;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final now = DateTime.now();

    final dates = history.map((e) => e.date).toList();
    final soldes = history.map((e) => e.solde).toList();

    final DateTime maxDate = estimee != null
        ? (now.isAfter(dates.last) ? now : dates.last)
        : dates.last;

    final allSoldes = [...soldes, ?estimee];
    double minS = allSoldes.reduce(math.min);
    double maxS = allSoldes.reduce(math.max);

    if (minS == maxS) {
      minS -= 1000;
      maxS += 1000;
    }

    final sRange = maxS - minS;
    final paddedMin = minS - sRange * 0.12;
    final paddedMax = maxS + sRange * 0.08;
    final paddedRange = paddedMax - paddedMin;

    final totalDays = maxDate.difference(dates.first).inDays;

    double toX(DateTime d) {
      if (totalDays == 0) return size.width;
      return (d.difference(dates.first).inDays / totalDays) * size.width;
    }

    double toY(double v) =>
        size.height - ((v - paddedMin) / paddedRange) * size.height;

    // Build main line points
    final pts = [
      for (final snap in history) Offset(toX(snap.date), toY(snap.solde)),
    ];

    // Fill under main line
    final fillPath = Path()
      ..moveTo(pts.first.dx, size.height)
      ..lineTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(pts.last.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = AppColors.barTrack
        ..style = PaintingStyle.fill,
    );

    // Main line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Dots on each snapshot
    final dotPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.fill;
    for (final p in pts) {
      canvas.drawCircle(p, 3.5, dotPaint);
    }

    // Estimated projection
    if (estimee != null) {
      final estPt = Offset(toX(now), toY(estimee!));
      final lastPt = pts.last;

      if ((estPt.dx - lastPt.dx).abs() > 2) {
        _drawDashedLine(
          canvas,
          lastPt,
          estPt,
          Paint()
            ..color = AppColors.accent.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }

      canvas.drawCircle(
        estPt,
        4.5,
        Paint()
          ..color = AppColors.background
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        estPt,
        4.5,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint,
      {double dash = 5, double gap = 4}) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;
    final nx = dx / dist;
    final ny = dy / dist;

    var drawn = 0.0;
    var drawing = true;
    while (drawn < dist) {
      final segLen = drawing ? dash : gap;
      final end = math.min(drawn + segLen, dist);
      if (drawing) {
        canvas.drawLine(
          Offset(from.dx + nx * drawn, from.dy + ny * drawn),
          Offset(from.dx + nx * end, from.dy + ny * end),
          paint,
        );
      }
      drawn += segLen;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_SavingsPainter old) =>
      old.history != history || old.estimee != estimee;
}

// ─── Snapshot row ─────────────────────────────────────────────────────────────

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({required this.snapshot, required this.onTap});
  final Epargne snapshot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        snapshot.libelle.isNotEmpty ? snapshot.libelle : 'Recalage';
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTextStyles.body),
                      Text(
                        formatDateShortFr(snapshot.date),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                AmountText(snapshot.solde),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.muted),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

// ─── Bottom sheet (recalage) ──────────────────────────────────────────────────

class _RecalageSheet extends ConsumerStatefulWidget {
  const _RecalageSheet({this.initial});
  final Epargne? initial;

  @override
  ConsumerState<_RecalageSheet> createState() => _RecalageSheetState();
}

class _RecalageSheetState extends ConsumerState<_RecalageSheet> {
  final _libelleController = TextEditingController();
  String _rawAmount = '';
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final snap = widget.initial!;
      _libelleController.text = snap.libelle;
      final m = snap.solde;
      _rawAmount =
          m.truncateToDouble() == m ? m.toInt().toString() : m.toStringAsFixed(2);
      _date = snap.date;
    }
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 31)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_rawAmount);
    if (amount == null || amount <= 0) {
      _snack('Saisir un montant valide.');
      return;
    }

    setState(() => _saving = true);
    try {
      final household = await ref.read(currentHouseholdProvider.future);
      if (!mounted || household == null) return;

      final snap = Epargne(
        id: widget.initial?.id ?? '',
        household: widget.initial?.household ?? household.id,
        date: _date,
        libelle: _libelleController.text.trim(),
        solde: amount,
      );

      final repo = ref.read(epargneRepoProvider);
      if (_isEdit) {
        await repo.update(snap);
      } else {
        await repo.create(snap);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
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
        title: const Text('Supprimer ce relevé ?'),
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
      await ref.read(epargneRepoProvider).delete(widget.initial!.id);
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'MODIFIER RELEVÉ' : 'NOUVEAU RELEVÉ',
                    style: AppTextStyles.sectionTitle,
                  ),
                  if (_isEdit)
                    TextButton(
                      onPressed: _saving ? null : _confirmDelete,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent),
                      child: const Text('Supprimer'),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Date
              Text('DATE', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.hairlineStrong)),
                  ),
                  child: Row(
                    children: [
                      Text(formatDateShortFr(_date), style: AppTextStyles.body),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Libellé
              Text('LIBELLÉ', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              TextField(
                controller: _libelleController,
                maxLength: 60,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Ex : Recalage juin',
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

              // Solde réel
              Text('SOLDE RÉEL', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _openKeypad,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.hairlineStrong)),
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
              const SizedBox(height: 32),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side:
                            const BorderSide(color: AppColors.hairlineStrong),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
