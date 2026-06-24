/// <reference path="../pb_data/types.d.ts" />

// Init du schéma : foyers, catégories, transactions, récurrents,
// revenus, épargne, ledger perso. Tout est scoped par foyer
// (household), sauf perso_ledger qui est scoped par propriétaire.

migrate(
  (app) => {
    // ---------------------------------------------------------------
    // 0) Référence à la collection auth "users"
    // ---------------------------------------------------------------
    const usersCol = app.findCollectionByNameOrId("users");
    const usersId = usersCol.id;

    // ---------------------------------------------------------------
    // 1) households — un foyer regroupe plusieurs utilisateurs
    // ---------------------------------------------------------------
    const households = new Collection({
      type: "base",
      name: "households",
      // Un utilisateur ne voit que les foyers dont il fait partie.
      listRule:   "members.id ?= @request.auth.id",
      viewRule:   "members.id ?= @request.auth.id",
      // La création d'un foyer reste possible pour tout utilisateur
      // authentifié (v1 : un seul foyer ; v2 : UI d'onboarding).
      createRule: '@request.auth.id != ""',
      updateRule: "members.id ?= @request.auth.id",
      deleteRule: "members.id ?= @request.auth.id",
      fields: [
        { name: "nom", type: "text", required: true },
        {
          name: "members",
          type: "relation",
          required: true,
          maxSelect: 10,
          collectionId: usersId,
          cascadeDelete: false,
        },
        { name: "created", type: "autodate", onCreate: true },
        { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      ],
    });
    app.save(households);
    const householdsId = app.findCollectionByNameOrId("households").id;

    // Helper : règle d'accès "même foyer que moi"
    const householdRule =
      "household.members.id ?= @request.auth.id";

    // ---------------------------------------------------------------
    // 2) categories
    // ---------------------------------------------------------------
    const categories = new Collection({
      type: "base",
      name: "categories",
      listRule:   householdRule,
      viewRule:   householdRule,
      createRule: householdRule,
      updateRule: householdRule,
      deleteRule: householdRule,
      fields: [
        {
          name: "household",
          type: "relation",
          required: true,
          maxSelect: 1,
          collectionId: householdsId,
          cascadeDelete: true,
        },
        { name: "nom", type: "text", required: true },
        {
          name: "type",
          type: "select",
          required: true,
          maxSelect: 1,
          values: ["depense", "revenu"],
        },
        { name: "couleur", type: "text" },
        { name: "icone", type: "text" },
        { name: "budget_mensuel", type: "number" },
        { name: "created", type: "autodate", onCreate: true },
        { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      ],
    });
    app.save(categories);
    const categoriesId = app.findCollectionByNameOrId("categories").id;

    // ---------------------------------------------------------------
    // 3) recurrents — définition d'un frais récurrent
    //    Les paiements effectifs sont enregistrés dans transactions
    //    (avec recurrent_source pointant vers cette définition).
    // ---------------------------------------------------------------
    const recurrents = new Collection({
      type: "base",
      name: "recurrents",
      listRule:   householdRule,
      viewRule:   householdRule,
      createRule: householdRule,
      updateRule: householdRule,
      deleteRule: householdRule,
      fields: [
        {
          name: "household",
          type: "relation",
          required: true,
          maxSelect: 1,
          collectionId: householdsId,
          cascadeDelete: true,
        },
        { name: "libelle", type: "text", required: true },
        { name: "montant", type: "number", required: true },
        {
          name: "frequence",
          type: "select",
          required: true,
          maxSelect: 1,
          values: ["mensuel", "trimestriel", "annuel"],
        },
        // Jour du mois où l'échéance tombe (1-31).
        { name: "jour_du_mois", type: "number", required: true, min: 1, max: 31 },
        {
          name: "categorie",
          type: "relation",
          required: true,
          maxSelect: 1,
          collectionId: categoriesId,
          cascadeDelete: false,
        },
        // Qui prend en charge ce frais par défaut.
        {
          name: "paye_par",
          type: "relation",
          required: false,
          maxSelect: 1,
          collectionId: usersId,
          cascadeDelete: false,
        },
        { name: "actif", type: "bool" },
        { name: "created", type: "autodate", onCreate: true },
        { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      ],
    });
    app.save(recurrents);
    const recurrentsId = app.findCollectionByNameOrId("recurrents").id;

    // ---------------------------------------------------------------
    // 4) transactions — dépenses et revenus réalisés
    //    Trace des paiements récurrents via recurrent_source.
    // ---------------------------------------------------------------
    const transactions = new Collection({
      type: "base",
      name: "transactions",
      listRule:   householdRule,
      viewRule:   householdRule,
      createRule: householdRule,
      updateRule: householdRule,
      deleteRule: householdRule,
      fields: [
        {
          name: "household",
          type: "relation",
          required: true,
          maxSelect: 1,
          collectionId: householdsId,
          cascadeDelete: true,
        },
        { name: "montant", type: "number", required: true },
        { name: "date", type: "date", required: true },
        {
          name: "categorie",
          type: "relation",
          required: true,
          maxSelect: 1,
          collectionId: categoriesId,
          cascadeDelete: false,
        },
        {
          name: "auteur",
          type: "relation",
          required: true,
          maxSelect: 1,
          collectionId: usersId,
          cascadeDelete: false,
        },
        { name: "note", type: "text" },
        // Lien optionnel vers le récurrent d'origine si cette
        // transaction est la confirmation d'une échéance.
        {
          name: "recurrent_source",
          type: "relation",
          required: false,
          maxSelect: 1,
          collectionId: recurrentsId,
          cascadeDelete: false,
        },
        { name: "created", type: "autodate", onCreate: true },
        { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      ],
    });
    app.save(transactions);

    // ---------------------------------------------------------------
    // 5) revenus — salaires et autres entrées récurrentes
    // ---------------------------------------------------------------
    const revenus = new Collection({
      type: "base",
      name: "revenus",
      listRule:   householdRule,
      viewRule:   householdRule,
      createRule: householdRule,
      updateRule: householdRule,
      deleteRule: householdRule,
      fields: [
        {
          name: "household",
          type: "relation",
          required: true,
          maxSelect: 1,
          collectionId: householdsId,
          cascadeDelete: true,
        },
        {
          name: "personne",
          type: "relation",
          required: true,
          maxSelect: 1,
          collectionId: usersId,
          cascadeDelete: false,
        },
        { name: "libelle", type: "text", required: true },
        { name: "montant", type: "number", required: true },
        {
          name: "type",
          type: "select",
          required: true,
          maxSelect: 1,
          values: ["salaire", "allocation", "autre"],
        },
        { name: "created", type: "autodate", onCreate: true },
        { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      ],
    });
    app.save(revenus);

    // ---------------------------------------------------------------
    // 6) epargne — snapshots datés des soldes
    // ---------------------------------------------------------------
    const epargne = new Collection({
      type: "base",
      name: "epargne",
      listRule:   householdRule,
      viewRule:   householdRule,
      createRule: householdRule,
      updateRule: householdRule,
      deleteRule: householdRule,
      fields: [
        {
          name: "household",
          type: "relation",
          required: true,
          maxSelect: 1,
          collectionId: householdsId,
          cascadeDelete: true,
        },
        { name: "date", type: "date", required: true },
        { name: "libelle", type: "text", required: true },
        { name: "solde", type: "number", required: true },
        { name: "created", type: "autodate", onCreate: true },
        { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      ],
    });
    app.save(epargne);

    // ---------------------------------------------------------------
    // 7) perso_ledger — STRICTEMENT PRIVÉ au propriétaire
    //    Pas de champ household : ces données ne sont jamais
    //    partagées, ni temps réel ni statique.
    // ---------------------------------------------------------------
    const persoLedger = new Collection({
      type: "base",
      name: "perso_ledger",
      listRule:   "owner = @request.auth.id",
      viewRule:   "owner = @request.auth.id",
      createRule: '@request.auth.id != "" && owner = @request.auth.id',
      updateRule: "owner = @request.auth.id",
      deleteRule: "owner = @request.auth.id",
      fields: [
        {
          name: "owner",
          type: "relation",
          required: true,
          maxSelect: 1,
          collectionId: usersId,
          cascadeDelete: false,
        },
        { name: "montant", type: "number", required: true },
        { name: "date", type: "date", required: true },
        { name: "note", type: "text" },
        {
          name: "categorie",
          type: "relation",
          required: false,
          maxSelect: 1,
          collectionId: categoriesId,
          cascadeDelete: false,
        },
        { name: "created", type: "autodate", onCreate: true },
        { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      ],
    });
    app.save(persoLedger);
  },

  // -----------------------------------------------------------------
  // DOWN : suppression dans l'ordre inverse pour respecter les FKs.
  // -----------------------------------------------------------------
  (app) => {
    const names = [
      "perso_ledger",
      "epargne",
      "revenus",
      "transactions",
      "recurrents",
      "categories",
      "households",
    ];
    for (const n of names) {
      try {
        const c = app.findCollectionByNameOrId(n);
        app.delete(c);
      } catch (e) {
        // collection déjà absente — on ignore
      }
    }
  }
);