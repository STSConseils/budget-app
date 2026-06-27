import 'package:flutter/material.dart';
import 'package:budget_app/core/theme.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _p(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          fontSize: 15.5,
          color: const Color(0xFF2A2A2A),
          height: 1.55,
        ),
      ),
    );

Widget _astuce(String text) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppColors.accent, width: 3),
        ),
      ),
      child: Text(
        'Astuce : $text',
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          color: const Color(0xFF2A2A2A),
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
      ),
    );

// ─── Section widget ───────────────────────────────────────────────────────────

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
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Floozee',
                      style: AppTextStyles.hero.copyWith(fontSize: 40),
                      children: [
                        TextSpan(
                          text: '.',
                          style: AppTextStyles.hero.copyWith(
                            fontSize: 40,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'NOTRE BUDGET, ENSEMBLE',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                const SizedBox(height: 20),
                _p(
                  'Bienvenue ! Floozee, c\'est notre app pour gérer le '
                  'budget de la maison à deux. L\'idée est simple : tout ce '
                  'que l\'un de nous note, l\'autre le voit tout de suite. '
                  'Pas de tableur compliqué — juste une vision claire de où '
                  'on en est. Voici comment ça marche.',
                ),
                const Divider(color: AppColors.ink, thickness: 2),

                // ── Section 1 ─────────────────────────────────────────
                _GuideSection(
                  numero: 1,
                  kicker: 'Pour commencer',
                  titre: 'Se connecter',
                  children: [
                    _p(
                      'Tu as ton propre accès : ton e-mail et ton mot de '
                      'passe. Une fois connectée, tu y restes — pas besoin '
                      'de le retaper à chaque fois. On a chacun notre '
                      'compte, mais on partage le même budget.',
                    ),
                  ],
                ),

                // ── Section 2 ─────────────────────────────────────────
                _GuideSection(
                  numero: 2,
                  kicker: 'L\'écran principal',
                  titre: 'Le tableau de bord',
                  children: [
                    _p(
                      'C\'est la page d\'accueil. En haut, le grand chiffre '
                      'est l\'info la plus importante : où on en sera à la '
                      'fin du mois, une fois tout payé. S\'il est noir, '
                      'tout va bien ; s\'il est rouge, c\'est qu\'on '
                      'dépasse.',
                    ),
                    _p(
                      'Juste en dessous, trois colonnes résument le mois : '
                      'ce qui rentre, ce qui est déjà dépensé, et ce qu\'il '
                      'reste à payer.',
                    ),
                    _p(
                      'Plus bas, chaque rubrique (Alimentation, Logement, '
                      'Enfants…) montre ce qu\'on a dépensé par rapport au '
                      'budget prévu. La petite barre passe au rouge si on a '
                      'dépassé le budget de cette rubrique.',
                    ),
                    _astuce(
                      'tape sur une rubrique pour voir le détail de toutes '
                      'les dépenses qui la composent.',
                    ),
                  ],
                ),

                // ── Section 3 ─────────────────────────────────────────
                _GuideSection(
                  numero: 3,
                  kicker: 'Les dépenses',
                  titre: 'Saisir une transaction',
                  children: [
                    _p(
                      'Le bouton + en bas à droite du tableau de bord ouvre '
                      'le formulaire de saisie. Tu y indiques le montant, '
                      'la catégorie, la date, et si c\'est une dépense ou '
                      'un revenu.',
                    ),
                    _p(
                      'Après enregistrement, la transaction apparaît '
                      'immédiatement dans le tableau de bord et met à jour '
                      'tous les totaux en temps réel. L\'autre peut la voir '
                      'au même instant, sans recharger.',
                    ),
                    _astuce(
                      'tape sur n\'importe quelle rubrique du tableau de '
                      'bord pour voir la liste complète de ses transactions '
                      'et en modifier une si besoin.',
                    ),
                  ],
                ),

                // ── Section 4 ─────────────────────────────────────────
                _GuideSection(
                  numero: 4,
                  kicker: 'Chaque mois',
                  titre: 'Les charges fixes',
                  children: [
                    _p(
                      'Les récurrents, c\'est tout ce qu\'on paie '
                      'régulièrement : loyer, assurances, abonnements… '
                      'Tu les crées une seule fois dans l\'écran récurrents '
                      '(icône ↺ en haut du tableau de bord).',
                    ),
                    _p(
                      'Chaque mois, ils apparaissent avec leur statut : '
                      'À payer, En retard ou Payé. Pour confirmer qu\'une '
                      'charge a été réglée, appuie sur « Confirmer payé » '
                      '— ça crée automatiquement la transaction '
                      'correspondante dans le budget du mois.',
                    ),
                    _astuce(
                      'les récurrents trimestriels ou annuels n\'apparaissent '
                      'que les mois où ils sont dus. En dehors, ils sont '
                      'simplement masqués de la liste.',
                    ),
                  ],
                ),

                // ── Section 5 ─────────────────────────────────────────
                _GuideSection(
                  numero: 5,
                  kicker: 'L\'organisation',
                  titre: 'Les catégories et les budgets',
                  children: [
                    _p(
                      'Les catégories permettent de classer dépenses et '
                      'revenus. Tu peux en créer, en modifier ou en '
                      'supprimer depuis l\'icône ⚙ du tableau de bord.',
                    ),
                    _p(
                      'Pour chaque catégorie de dépense, tu peux définir '
                      'un budget mensuel. Une fois ce budget renseigné, '
                      'la barre de progression dans le tableau de bord '
                      'indique visuellement où on en est. Elle passe au '
                      'rouge dès qu\'on dépasse.',
                    ),
                    _astuce(
                      'si une catégorie n\'a pas de budget mensuel défini, '
                      'elle n\'apparaît pas dans les rubriques du tableau '
                      'de bord — mais les transactions qui lui sont '
                      'rattachées sont quand même comptabilisées dans les '
                      'totaux.',
                    ),
                  ],
                ),

                // ── Section 6 ─────────────────────────────────────────
                _GuideSection(
                  numero: 6,
                  kicker: 'Notre patrimoine',
                  titre: 'Suivre l\'épargne',
                  children: [
                    _p(
                      'L\'écran Épargne est accessible en tapant sur le '
                      'chiffre d\'épargne affiché sous la position projetée '
                      'dans le tableau de bord. Il montre une estimation de '
                      'notre épargne en temps réel.',
                    ),
                    _p(
                      'Le principe : on entre de temps en temps un relevé '
                      'bancaire réel (le « recalage ») avec le solde exact '
                      'et la date. L\'app calcule ensuite automatiquement '
                      'les flux depuis ce relevé — revenus moins dépenses '
                      '— pour estimer la valeur actuelle. La courbe '
                      'visualise l\'évolution dans le temps.',
                    ),
                    _astuce(
                      'pour ajouter un relevé réel, tape le + en haut de '
                      'l\'écran Épargne. Plus les recalages sont fréquents, '
                      'plus l\'estimation est précise.',
                    ),
                  ],
                ),

                // ── Pied de page ─────────────────────────────────────
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'C\'est tout ! L\'app se met à jour en temps réel dès '
                    'qu\'on fait quelque chose. Pas besoin de recharger.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
