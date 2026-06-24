/// <reference path="../pb_data/types.d.ts" />

// Init du schéma : foyers, catégories, transactions, récurrents
// (dépenses ET revenus), épargne, ledger perso. Tout est scoped
// par foyer (household), sauf perso_ledger qui est scoped par
// propriétaire.

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
      listRule:   "members.id ?= @request.auth.id",
      viewRule:   "members.id ?= @request.auth.id",
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

    // Règle "même foyer que moi"
    const householdRule = "household.members.id ?= @request.auth.id";

    // ---------------------------------------------------------------
    // 2) categories — type = "depense" ou "revenu"
    //    Une catégorie générale (Alimentation, Salaire, etc.) que
    //    l'utilisateur crée depuis l'app.
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
    // 3) recurrents — définitions récurrentes, DÉPENSES ET REVENUS.
    //    Les paiements/encaissements effectifs sont enregistrés dans
    //    transactions, via recurrent_source.
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
        // Sens du flux : sortie d'argent (dépense) ou entrée (revenu).
        // Doit être cohérent avec le type de la catégorie liée.
        {
          name: "sens",
          type: "select",
          required: true,
          maxSelect: 1,
          values: ["depense", "revenu"],
        },
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
        // Personne concernée :
        //   - pour une dépense : qui paie par défaut
        //   - pour un revenu   : qui perçoit
        {
          name: "personne",
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
    // 4) transactions — dépenses ET revenus réalisés.
    //    Le sens (entrée/sortie) se déduit de la catégorie liée.
    //    Trace des récurrents via recurrent_source.
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
    // 5) epargne — snapshots datés des soldes
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
    // 6) perso_ledger — STRICTEMENT PRIVÉ au propriétaire.
    //    Pas de champ household : ces données ne sont jamais
    //    partagées, ni en temps réel ni en statique.
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