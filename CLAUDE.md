# CLAUDE.md — App Budget familial

> Fichier de contexte lu par Claude Code à chaque session.
> À placer à la **racine du dépôt** (`C:\dev\budget-app\CLAUDE.md`).
> Règle d'or : on construit **un module à la fois**, proprement isolé. On ne touche pas à ce qui marche déjà.

---

## 1. Le projet en une phrase

Application **web** de gestion de budget familial pour deux personnes (un couple), avec dashboard temps réel, frais récurrents, catégories personnalisables, suivi des salaires et de l'épargne, et un **ledger personnel privé** propre à chaque utilisateur.

---

## 2. Stack & versions

- **Frontend** : Flutter **web uniquement** (pas de mobile)
- **Gestion d'état** : **Riverpod** (`flutter_riverpod`), providers déclarés à la main (pas de codegen / build_runner)
- **Routing** : `go_router` (URLs propres pour le web)
- **Backend** : PocketBase **v0.39.3** (instance dédiée, port 8092, sous-domaine `budget.jorapp.org`)
- **Polices** : `google_fonts` (Archivo)
- **Formatage** : `intl`

Dépendances à utiliser (pas d'autres librairies d'état) :
```yaml
flutter_riverpod: ^2.5.0
go_router: ^14.0.0
pocketbase: ^0.22.0
google_fonts: ^6.2.0
intl: ^0.19.0
```

---

## 3. Architecture — feature-first

Comme le projet JorAppLab : chaque fonctionnalité est un dossier isolé sous `features/`. Le code partagé vit dans `core/`, `models/`, `repositories/`.

```
budget-app/
├── CLAUDE.md            ← ce fichier
├── pb_migrations/       ← schéma PocketBase (source de vérité, versionné)
├── server/             ← .service, nginx conf, deploy.sh
└── app/                 ← projet Flutter
    └── lib/
        ├── main.dart    ← ProviderScope + MaterialApp.router
        ├── core/
        │   ├── pb.dart      ← client PocketBase (same-origin)
        │   ├── theme.dart   ← thème Design A
        │   ├── router.dart  ← go_router
        │   └── format.dart  ← formatage CHF & dates
        ├── models/      ← Category, Transaction, Recurrent, Revenu, Epargne, PersoEntry
        ├── repositories/← un repository par collection (expose des providers Riverpod)
        └── features/
            ├── auth/
            ├── dashboard/
            ├── transactions/
            ├── recurrents/
            ├── categories/
            ├── revenus_epargne/
            └── perso/
```

---

## 4. Accès backend — same-origin (NON NÉGOCIABLE pour la portabilité)

Le front est servi par nginx **au même origine** que l'API (`/api/` est proxyé vers PocketBase local). L'app ne doit **jamais** coder en dur l'URL du serveur : elle dérive l'origine à l'exécution. C'est ce qui rend la migration vers un Raspberry Pi triviale (zéro rebuild).

`core/pb.dart` :
```dart
import 'package:pocketbase/pocketbase.dart';

// Same-origin en prod ; API distante en dev local.
final String _baseUrl = Uri.base.origin.contains('localhost')
    ? 'https://budget.jorapp.org'
    : Uri.base.origin;

final pb = PocketBase(_baseUrl);
```

Règles :
- Jamais d'IP ni de host en dur ailleurs que dans ce fichier.
- Le temps réel passe par les **subscriptions PocketBase**, exposées via des `StreamProvider`.

---

## 5. Design system — « Concept A : Suisse / Grille »

Style typographique international : grille stricte, hairlines, gros chiffres, **un seul accent rouge**. Sobre et lisible. À implémenter dans `core/theme.dart` et à respecter dans tous les écrans.

**Couleurs**
| Rôle | Hex |
|---|---|
| Fond | `#F4F3EF` |
| Encre (texte principal) | `#0A0A0A` |
| Accent (rouge) | `#E23A1E` |
| Texte atténué | `#888888` |
| Hairline forte | `#D4D3CD` |
| Hairline légère | `#E3E2DC` |
| Fond de barre | `#DEDED7` |

**Typographie** (Archivo via google_fonts)
- Gros chiffres / héros : Archivo **800**, tracking serré (`-0.02em`), très grande taille
- Titres de section : Archivo **700**, 11px, MAJUSCULES, letter-spacing `0.12em`, couleur atténuée
- Corps : Archivo 400–600
- Tous les montants : **chiffres tabulaires** (`fontFeatures: [FontFeature.tabularFigures()]`)

**Principes visuels**
- Séparateurs = hairlines 1px, jamais d'ombres portées.
- Barres de progression budget vs réel : fond `#DEDED7`, remplissage encre `#0A0A0A`, et **rouge `#E23A1E` uniquement en cas de dépassement**.
- Beaucoup de blanc, alignement sur grille, pas d'arrondis marqués.

**Format des montants** (`core/format.dart`)
- Séparateur de milliers = **apostrophe suisse** : `12'400`
- Suffixe `CHF` en plus petit et atténué.
- Exemple cible : `+3'240 CHF`.

---

## 6. Modèle de données (collections PocketBase)

Détaillé et créé via migrations au prompt 2. Vue d'ensemble :

| Collection | Champs clés | Accès |
|---|---|---|
| `users` | (auth) — deux comptes : toi + ta femme | — |
| `categories` | `nom`, `type` (depense\|revenu), `couleur` (hex), `icone`, `budget_mensuel` (opt.) | partagé |
| `transactions` | `montant`, `date`, `categorie` (rel), `auteur` (rel users), `note` | **partagé** (dépenses/revenus communs) |
| `recurrents` | `libelle`, `montant`, `frequence` (mensuel\|trimestriel\|annuel), `categorie` (rel), `prochaine_echeance`, `actif` | partagé |
| `revenus` | `personne` (rel users), `libelle`, `montant`, `type` (salaire\|allocation\|autre) | partagé |
| `epargne` | `date`, `libelle` (compte), `solde` | partagé |
| `perso_ledger` | `owner` (rel users), `montant`, `date`, `note`, `categorie` (opt.) | **PRIVÉ — voir ci-dessous** |

**Confidentialité (ledger parallèle).** `perso_ledger` est strictement privé : ses règles API (List / View / Create / Update / Delete) sont scoped au propriétaire :
```
owner = @request.auth.id
```
→ le compte de l'autre personne ne reçoit jamais ces enregistrements, **y compris en temps réel**. Le ledger perso n'alimente QUE la vue de son propriétaire et reste totalement absent de toutes les vues et agrégats communs. La privacy est imposée **côté serveur**, jamais par un simple filtre dans l'UI.

---

## 7. Calculs du dashboard (logique métier)

- **Position projetée fin de mois** = `solde épargne actuel + (revenus du mois − dépenses réalisées − dépenses prévues restantes)`
- **Par rubrique** = somme des transactions du mois par catégorie, comparée au `budget_mensuel`
- **Dépenses prévues restantes** = échéances de récurrents du mois pas encore confirmées comme payées
- Ces valeurs dérivées sont des **providers calculés** Riverpod qui se recombinent à partir des `StreamProvider` sources (recalcul automatique au temps réel).
- Le ledger perso n'entre **jamais** dans ces calculs communs.

---

## 8. Conventions de code

- **Riverpod** : un `StreamProvider` par collection (souscription temps réel) ; les valeurs dérivées sont des `Provider` qui lisent d'autres providers ; UI en `ConsumerWidget` / `ConsumerStatefulWidget`.
- **Repositories** : classes simples (un fichier par collection dans `repositories/`), exposées via un `Provider`. Toute la logique d'accès PocketBase y est centralisée — pas d'appel `pb.collection(...)` dispersé dans les widgets.
- **Models** : classes Dart immuables avec `fromRecord(RecordModel)` / `toJson()`.
- Pas de secret ni d'identifiant en dur dans le code (déjà couvert par `.gitignore`).
- Français pour l'UI, l'anglais reste possible pour le code (noms de variables).

---

## 9. Workflow build & déploiement

- **Build** (Flutter installé côté Windows) : en **PowerShell**
  ```powershell
  cd C:\dev\budget-app\app
  flutter build web --release
  ```
- **Déploiement** : en **WSL** (rsync seulement)
  ```bash
  rsync -avz --delete /mnt/c/dev/budget-app/app/build/web/ root@46.101.242.21:/var/www/budget/
  ```
- **Migrations PocketBase** : les fichiers de `pb_migrations/` sont déposés dans `/opt/pb-budget/pb_migrations/` sur le serveur ; elles s'appliquent au démarrage de l'instance.

---

## 10. Méthode de travail avec Claude Code

- **Un prompt = un module.** Ne pas anticiper sur les modules suivants.
- Toujours respecter la structure de dossiers et le design system ci-dessus.
- Ne pas introduire de nouvelle dépendance d'état (pas de Provider classique, pas de Bloc, pas de GetX).
- À la fin de chaque module : code qui compile (`flutter analyze` propre) avant de passer au suivant.
