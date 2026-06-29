import 'package:flutter/material.dart';
import 'package:budget_app/core/theme.dart';

// ─── Text style helpers ───────────────────────────────────────────────────────

// Bold ink span — inherit font from parent TextSpan.
const _b = TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0A0A0A));

TextStyle _body() => AppTextStyles.body.copyWith(
      fontSize: 15.5,
      color: const Color(0xFF2A2A2A),
      height: 1.55,
    );

Widget _p(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text, style: _body()),
    );

Widget _pRich(List<InlineSpan> spans) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text.rich(TextSpan(style: _body(), children: spans)),
    );

Widget _tip(String boldPrefix, String rest) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
      ),
      child: Text.rich(
        TextSpan(
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: const Color(0xFF333333),
            height: 1.5,
          ),
          children: [
            TextSpan(text: boldPrefix, style: _b),
            TextSpan(text: rest),
          ],
        ),
      ),
    );

// ─── Section ─────────────────────────────────────────────────────────────────

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.numero,
    required this.kicker,
    required this.titre,
    required this.children,
  });

  final int numero;
  final String kicker;
  final String titre;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 34),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Center(
                child: Text(
                  '$numero',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(kicker.toUpperCase(), style: AppTextStyles.sectionTitle),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          titre,
          style: AppTextStyles.hero.copyWith(
            fontSize: 22,
            letterSpacing: 22 * -0.02,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 28),
        const Divider(color: AppColors.hairlineLight),
      ],
    );
  }
}

// ─── Glossaire ────────────────────────────────────────────────────────────────

class _Def extends StatelessWidget {
  const _Def({required this.term, required this.desc, this.formula});

  final String term;
  final List<InlineSpan> desc;
  final List<InlineSpan>? formula;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 8),
                    child: Container(width: 10, height: 10, color: AppColors.accent),
                  ),
                  Expanded(
                    child: Text(
                      term,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 18, top: 6),
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14.5,
                      color: const Color(0xFF3A3A3A),
                      height: 1.5,
                    ),
                    children: desc,
                  ),
                ),
              ),
              if (formula != null)
                Padding(
                  padding: const EdgeInsets.only(left: 18, top: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.hairlineStrong),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          height: 1.6,
                        ),
                        children: formula,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.hairlineLight),
      ],
    );
  }
}

// ─── Étape numérotée ──────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  const _Step({required this.numero, required this.text});

  final int numero;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$numero',
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  color: const Color(0xFF2A2A2A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Maquettes du tableau de bord ────────────────────────────────────────────

class _MockPosition extends StatelessWidget {
  const _MockPosition();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.hairlineStrong),
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('POSITION PROJETÉE FIN DE MOIS', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              text: "53’780",
              style: AppTextStyles.hero.copyWith(fontSize: 38),
              children: [
                TextSpan(
                  text: ' CHF',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: AppTextStyles.body.copyWith(
                fontSize: 12.5,
                color: const Color(0xFF555555),
              ),
              children: const [
                TextSpan(text: 'Épargne estimée '),
                TextSpan(
                  text: '~53’800',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' · jusqu’à la fin du mois'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockTriple extends StatelessWidget {
  const _MockTriple();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.hairlineStrong),
      ),
      margin: const EdgeInsets.symmetric(vertical: 18),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _cell('REVENUS', "12’400"),
            _cell('RÉALISÉ', "6’820"),
            _cell('PRÉVU', '185', last: true),
          ],
        ),
      ),
    );
  }

  Widget _cell(String label, String value, {bool last = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: last
            ? null
            : const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.hairlineLight)),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 9,
                letterSpacing: 0.54,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTextStyles.amount.copyWith(
                fontSize: 16,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockBars extends StatelessWidget {
  const _MockBars();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.hairlineStrong),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      margin: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          _barRow('Alimentation', '890', "1’200", 890 / 1200, false),
          const SizedBox(height: 16),
          _barRow('Sorties', '560', '500', 1.0, true),
        ],
      ),
    );
  }

  Widget _barRow(String label, String spent, String budget, double ratio, bool over) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                text: '$spent ',
                style: AppTextStyles.amount.copyWith(
                  fontSize: 13.5,
                  color: over ? AppColors.accent : AppColors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                children: [
                  TextSpan(
                    text: '/ $budget',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 4,
          child: LayoutBuilder(
            builder: (_, constraints) => Stack(
              children: [
                Container(color: AppColors.barTrack, width: constraints.maxWidth),
                Container(
                  color: over ? AppColors.accent : AppColors.ink,
                  width: constraints.maxWidth * ratio,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AideScreen extends StatelessWidget {
  const AideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AIDE', style: AppTextStyles.sectionTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── En-tête ──────────────────────────────────────────
                const SizedBox(height: 40),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Floozee',
                      style: AppTextStyles.hero.copyWith(
                        fontSize: 46,
                        letterSpacing: 46 * -0.03,
                      ),
                      children: [
                        TextSpan(
                          text: '.',
                          style: AppTextStyles.hero.copyWith(
                            fontSize: 46,
                            letterSpacing: 46 * -0.03,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'NOTRE BUDGET, ENSEMBLE',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        color: const Color(0xFF333333),
                        height: 1.55,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Salut ! Floozee, c’est notre app pour gérer le budget de la maison à deux. '
                              'Avant de voir comment l’utiliser, le plus utile est de comprendre ',
                        ),
                        TextSpan(text: 'l’idée derrière', style: _b),
                        const TextSpan(text: ' et '),
                        TextSpan(text: 'ce que veulent dire les chiffres', style: _b),
                        const TextSpan(
                          text: ' que tu vois à l’écran. '
                              'Une fois que c’est clair, le reste coule de source.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(color: AppColors.ink, thickness: 2),

                // ── 1 — À quoi sert Floozee ──────────────────────────
                _GuideSection(
                  numero: 1,
                  kicker: 'L’idée en deux mots',
                  titre: 'À quoi sert Floozee',
                  children: [
                    _pRich([
                      const TextSpan(
                        text: 'Floozee répond à une seule question, en permanence : ',
                      ),
                      TextSpan(
                        text: '« où en est-on financièrement, là, maintenant ? »',
                        style: _b,
                      ),
                      const TextSpan(text: ' — et surtout '),
                      TextSpan(
                        text: '« où en sera-t-on à la fin du mois ? »',
                        style: _b,
                      ),
                    ]),
                    _pRich([
                      const TextSpan(
                        text: 'Pour ça, l’app fait une chose toute simple : elle suit ce qui ',
                      ),
                      TextSpan(text: 'entre', style: _b),
                      const TextSpan(text: ' (nos revenus) et ce qui '),
                      TextSpan(text: 'sort', style: _b),
                      const TextSpan(
                        text: ' (nos dépenses), les range par thème, et les met en regard de nos ',
                      ),
                      TextSpan(text: 'économies', style: _b),
                      const TextSpan(
                        text: '. Comme on partage le même budget, ',
                      ),
                      TextSpan(
                        text: 'tout ce que l’un de nous note, l’autre le voit tout de suite',
                        style: _b,
                      ),
                      const TextSpan(
                        text: '. On a chacun notre accès (e-mail + mot de passe), '
                            'mais une seule et même vision commune.',
                      ),
                    ]),
                  ],
                ),

                // ── 2 — Comprendre les chiffres ──────────────────────
                _GuideSection(
                  numero: 2,
                  kicker: 'Le vocabulaire',
                  titre: 'Comprendre les chiffres',
                  children: [
                    _p(
                      'Voici ce que représente chaque chiffre que tu croiseras dans l’app. '
                      'C’est la partie la plus importante du guide — le reste n’est que des boutons.',
                    ),
                    _Def(
                      term: 'Les revenus',
                      desc: [
                        const TextSpan(text: 'Tout l’argent qui '),
                        TextSpan(text: 'entre', style: _b),
                        const TextSpan(
                          text: ' ce mois-ci : nos salaires, les allocations familiales. '
                              'C’est ce sur quoi on peut compter pour le mois.',
                        ),
                      ],
                    ),
                    _Def(
                      term: 'Les dépenses',
                      desc: [
                        const TextSpan(text: 'Tout l’argent qui '),
                        TextSpan(text: 'sort', style: _b),
                        const TextSpan(text: ' : courses, factures, sorties, essence… Chaque dépense est rangée dans une '),
                        TextSpan(text: 'rubrique', style: _b),
                        const TextSpan(text: ' (voir plus bas) pour qu’on voie où part l’argent.'),
                      ],
                    ),
                    _Def(
                      term: '« Réalisé »',
                      desc: [
                        const TextSpan(text: 'Ce qui est '),
                        TextSpan(text: 'déjà fait à ce jour', style: _b),
                        const TextSpan(
                          text: ' : les dépenses qu’on a réellement effectuées '
                              'depuis le début du mois. C’est du concret, pas une prévision.',
                        ),
                      ],
                    ),
                    _Def(
                      term: '« Prévu » (à venir)',
                      desc: [
                        const TextSpan(text: 'Ce qui va '),
                        TextSpan(text: 'encore tomber d’ici la fin du mois', style: _b),
                        const TextSpan(
                          text: ' mais qu’on n’a pas encore payé — typiquement un abonnement '
                              'ou une facture qui revient chaque mois et qu’on n’a pas encore confirmé.',
                        ),
                      ],
                    ),
                    _Def(
                      term: 'La position projetée fin de mois',
                      desc: [
                        TextSpan(text: 'Le chiffre le plus important.', style: _b),
                        const TextSpan(text: ' Ce n’est pas ce qu’on a aujourd’hui, mais une '),
                        TextSpan(text: 'projection', style: _b),
                        const TextSpan(
                          text: ' : là où on en sera une fois que tout le mois aura été payé. '
                              'S’il est positif, on termine le mois dans le vert.',
                        ),
                      ],
                      formula: [
                        const TextSpan(text: 'En clair :\n'),
                        TextSpan(text: 'nos économies', style: _b),
                        const TextSpan(text: ' + '),
                        TextSpan(text: 'ce qui rentre encore', style: _b),
                        const TextSpan(text: ' — '),
                        TextSpan(text: 'ce qui sort encore', style: _b),
                      ],
                    ),
                    _Def(
                      term: 'Le budget (d’une rubrique)',
                      desc: [
                        const TextSpan(text: 'La '),
                        TextSpan(text: 'limite qu’on s’est fixée', style: _b),
                        const TextSpan(
                          text: ' pour une catégorie sur le mois '
                              '(par exemple 1’200 pour l’alimentation). '
                              'Ça permet de voir d’un coup d’œil si on est dans les clous ou si on déborde.',
                        ),
                      ],
                    ),
                    _Def(
                      term: 'L’épargne estimée',
                      desc: [
                        TextSpan(text: 'Combien on a de côté', style: _b),
                        const TextSpan(
                          text: ', estimé en direct. Le chiffre monte quand de l’argent rentre, '
                              'et baisse quand on dépense. De temps en temps on le '
                              '« recale » sur le vrai solde de la banque '
                              '(voir la section Épargne).',
                        ),
                      ],
                    ),
                    _Def(
                      term: '« Déductible » (impôts)',
                      desc: [
                        const TextSpan(text: 'Une dépense qu’on pourra '),
                        TextSpan(text: 'retirer de notre revenu imposable', style: _b),
                        const TextSpan(text: ', et qui nous fera donc '),
                        TextSpan(text: 'payer moins d’impôts', style: _b),
                        const TextSpan(
                          text: ' : garde d’enfants, frais médicaux, 3e pilier, '
                              'intérêts de l’hypothèque… L’app les additionne toute l’année.',
                        ),
                      ],
                    ),
                  ],
                ),

                // ── 3 — Le tableau de bord ────────────────────────────
                _GuideSection(
                  numero: 3,
                  kicker: 'L’écran principal',
                  titre: 'Le tableau de bord',
                  children: [
                    _pRich([
                      const TextSpan(
                        text: 'C’est la page d’accueil, et elle rassemble tous les chiffres '
                            'qu’on vient de définir. En haut, le ',
                      ),
                      TextSpan(text: 'grand chiffre', style: _b),
                      const TextSpan(
                        text: ' : la position projetée fin de mois. '
                            'Noir = tout va bien, rouge = on dépasse.',
                      ),
                    ]),
                    const _MockPosition(),
                    _pRich([
                      const TextSpan(text: 'Juste en dessous, les '),
                      TextSpan(text: 'trois chiffres du mois', style: _b),
                      const TextSpan(
                        text: ' : ce qui rentre, ce qui est déjà dépensé '
                            '(« réalisé »), et ce qu’il reste à payer '
                            '(« prévu »).',
                      ),
                    ]),
                    const _MockTriple(),
                    _pRich([
                      const TextSpan(text: 'Plus bas, chaque '),
                      TextSpan(text: 'rubrique', style: _b),
                      const TextSpan(
                        text: ' montre ce qu’on a dépensé par rapport à son budget. La barre passe au ',
                      ),
                      const TextSpan(
                        text: 'rouge',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' si on a dépassé.'),
                    ]),
                    const _MockBars(),
                    _tip(
                      'Astuce :',
                      ' tape sur une rubrique pour voir le détail de toutes les dépenses '
                      'qui la composent, et qui les a faites.',
                    ),
                  ],
                ),

                // ── 4 — Ajouter une dépense ───────────────────────────
                _GuideSection(
                  numero: 4,
                  kicker: 'Au quotidien',
                  titre: 'Ajouter une dépense',
                  children: [
                    _pRich([
                      const TextSpan(
                        text: 'C’est le geste qu’on fera le plus souvent, et c’est fait pour aller vite. Le bouton rond ',
                      ),
                      TextSpan(text: '+', style: _b),
                      const TextSpan(text: ' en bas à droite ouvre la saisie :'),
                    ]),
                    const SizedBox(height: 4),
                    const _Step(numero: 1, text: 'Tape le montant sur le clavier de chiffres.'),
                    const _Step(numero: 2, text: 'Choisis la catégorie d’un seul tap.'),
                    const _Step(numero: 3, text: 'Indique qui a payé — toi ou moi.'),
                    const _Step(numero: 4, text: 'Valide. C’est tout !'),
                    const SizedBox(height: 8),
                    _p(
                      'La date est déjà à aujourd’hui, et tu peux ajouter une note si tu veux. '
                      'En quelques secondes c’est noté, et je le vois de mon côté.',
                    ),
                  ],
                ),

                // ── 5 — Les catégories ────────────────────────────────
                _GuideSection(
                  numero: 5,
                  kicker: 'L’organisation',
                  titre: 'Les catégories',
                  children: [
                    _pRich([
                      const TextSpan(text: 'Ce sont nos '),
                      TextSpan(text: 'rubriques de dépenses', style: _b),
                      const TextSpan(
                        text: ' : Logement, Alimentation, Garde enfants, Transport, Sorties… '
                            'Elles servent à ranger les dépenses pour voir où part l’argent — '
                            'et c’est à elles qu’on attribue un budget mensuel.',
                      ),
                    ]),
                    _pRich([
                      const TextSpan(text: 'Elles sont déjà prêtes, mais tu peux '),
                      TextSpan(text: 'en créer une', style: _b),
                      const TextSpan(
                        text: ' toi-même (avec sa couleur et son icône) et lui donner un ',
                      ),
                      TextSpan(text: 'budget', style: _b),
                      const TextSpan(text: ', depuis le bouton réglages en haut de l’écran.'),
                    ]),
                  ],
                ),

                // ── 6 — Les récurrents ────────────────────────────────
                _GuideSection(
                  numero: 6,
                  kicker: 'Ce qui revient chaque mois',
                  titre: 'Les paiements récurrents',
                  children: [
                    _pRich([
                      const TextSpan(
                        text: 'Certaines choses reviennent tous les mois : l’',
                      ),
                      TextSpan(text: 'hypothèque', style: _b),
                      const TextSpan(text: ', les '),
                      TextSpan(text: 'assurances', style: _b),
                      const TextSpan(text: ', la '),
                      TextSpan(text: 'crèche', style: _b),
                      const TextSpan(text: ', les abonnements… et aussi nos '),
                      TextSpan(text: 'salaires', style: _b),
                      const TextSpan(
                        text: '. Pas besoin de les retaper : ils sont enregistrés une fois pour toutes.',
                      ),
                    ]),
                    _pRich([
                      const TextSpan(
                        text: 'Quand l’un de ces paiements tombe, il suffit de le ',
                      ),
                      TextSpan(text: 'confirmer comme « payé »', style: _b),
                      const TextSpan(
                        text: ' d’un tap. Il passe alors du « prévu » au '
                            '« réalisé », et le tableau de bord se met à jour. '
                            'Si un paiement attendu n’a pas encore été confirmé, '
                            'l’app te le signale — pratique pour ne rien oublier.',
                      ),
                    ]),
                  ],
                ),

                // ── 7 — L'épargne ─────────────────────────────────────
                _GuideSection(
                  numero: 7,
                  kicker: 'Nos économies',
                  titre: 'L’épargne',
                  children: [
                    _pRich([
                      const TextSpan(text: 'L’app affiche en permanence une '),
                      TextSpan(text: 'estimation de nos économies', style: _b),
                      const TextSpan(
                        text: ', qui bouge en temps réel : chaque rentrée d’argent '
                            'la fait monter, chaque dépense la fait descendre.',
                      ),
                    ]),
                    _pRich([
                      const TextSpan(
                        text: 'Comme l’app ne voit pas directement notre compte en banque, '
                            'on lui donne un coup de pouce de temps en temps : on regarde le ',
                      ),
                      TextSpan(text: 'vrai solde', style: _b),
                      const TextSpan(text: ' de notre compte d’épargne et on le '),
                      TextSpan(text: '« recale »', style: _b),
                      const TextSpan(
                        text: ' dans l’app. Ça remet les compteurs à la réalité. '
                            'Une fois par mois suffit largement.',
                      ),
                    ]),
                    _tip(
                      'En clair :',
                      ' au quotidien le chiffre est une bonne estimation, et le recalage '
                      'occasionnel le garde fidèle à la réalité.',
                    ),
                  ],
                ),

                // ── 8 — Les impôts ────────────────────────────────────
                _GuideSection(
                  numero: 8,
                  kicker: 'Bon à savoir',
                  titre: 'Les impôts',
                  children: [
                    _pRich([
                      const TextSpan(
                        text: 'Certaines dépenses se déduisent des impôts '
                            '(frais de garde, frais médicaux, 3e pilier, '
                            'intérêts hypothécaires…). Quand on en saisit une, on peut la ',
                      ),
                      TextSpan(text: 'marquer comme déductible', style: _b),
                      const TextSpan(text: '.'),
                    ]),
                    _pRich([
                      const TextSpan(
                        text: 'L’app additionne tout ça au fil de l’année, et le tableau de bord montre le ',
                      ),
                      TextSpan(text: 'total qu’on pourra déduire', style: _b),
                      const TextSpan(
                        text: '. Au moment de remplir la déclaration, on aura déjà les '
                            'chiffres sous la main — fini de tout rechercher en fin d’année.',
                      ),
                    ]),
                  ],
                ),

                // ── Pied de page ─────────────────────────────────────
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Et voilà — une fois les chiffres compris, le reste est un jeu d’enfant 🙂',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF555555),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Floozee · notre budget à deux',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                const SizedBox(height: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
