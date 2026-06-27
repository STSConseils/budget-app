/// <reference path="../pb_data/types.d.ts" />

// Seed de démonstration pour le foyer existant.
// Crée : catégories suisses, récurrents (dépenses + revenus salaires),
// snapshot d'épargne, et quelques transactions du mois en cours
// (y compris des dépenses déductibles fiscalement).
//
// Le seed est rejouable et idempotent autant que possible : si une
// donnée existe déjà (par son nom), on la réutilise plutôt que d'en
// créer une nouvelle. Le down() supprime tout ce qui a été créé.

migrate(
  (app) => {
    // ---------------------------------------------------------------
    // 0) Récupérer foyer + utilisateurs
    // ---------------------------------------------------------------
    const households = app.findRecordsByFilter("households", "", "", 1, 0);
    if (households.length === 0) {
      throw new Error(
        "Aucun foyer trouvé. Crée d'abord un household avant de lancer ce seed."
      );
    }
    const household = households[0];
    const householdId = household.id;

    const memberIds = household.get("members") || [];
    if (memberIds.length === 0) {
      throw new Error("Le foyer n'a aucun membre.");
    }
    const me = memberIds[0];                         // utilisateur principal
    const partner = memberIds.length > 1 ? memberIds[1] : me;

    // Date du mois en cours, format YYYY-MM-DD
    const now = new Date();
    const yyyy = now.getUTCFullYear();
    const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
    const day = (d) => `${yyyy}-${mm}-${String(d).padStart(2, "0")} 00:00:00.000Z`;

    // ---------------------------------------------------------------
    // 1) Catégories — créées si absentes
    // ---------------------------------------------------------------
    const catsCol = app.findCollectionByNameOrId("categories");

    // [nom, type, couleur, icone, budgetMensuel]
    const categoriesSeed = [
      // Dépenses
      ["Logement",         "depense", "#1F4D7A", "home",          3200],
      ["Alimentation",     "depense", "#7AA877", "shopping_cart", 1200],
      ["Garde enfants",    "depense", "#C89B6A", "child_care",    1800],
      ["Activités enfants","depense", "#E0C97E", "sports_soccer",  400],
      ["Transport",        "depense", "#5B8DEF", "directions_car", 600],
      ["Assurance maladie","depense", "#9B86B8", "local_hospital", 980],
      ["Frais médicaux",   "depense", "#CF8F7E", "medical_services",200],
      ["Sorties",          "depense", "#E08A7E", "restaurant",     500],
      ["Abonnements",      "depense", "#A38A6A", "subscriptions",  150],
      ["Numérique",        "depense", "#6B7280", "devices",        100],
      ["Habillement",      "depense", "#8A6A8A", "checkroom",      200],
      ["Vacances",         "depense", "#4A9B8E", "beach_access",   500],
      ["Impôts",           "depense", "#5C5C5C", "account_balance",1500],
      ["3e pilier",        "depense", "#7AA877", "savings",         605],
      ["Entretien maison", "depense", "#A8754F", "build",           300],
      ["Divers",           "depense", "#9CA3AF", "more_horiz",      150],
      // Revenus
      ["Salaire",          "revenu",  "#2E7D32", "payments",       null],
      ["Allocations",      "revenu",  "#558B2F", "family_restroom",null],
      ["Autres revenus",   "revenu",  "#7CB342", "trending_up",    null],
    ];

    const catId = {}; // map nom -> id
    for (const [nom, type, couleur, icone, budget] of categoriesSeed) {
      // Cherche s'il existe déjà
      const existing = app.findRecordsByFilter(
        "categories",
        `nom = "${nom}" && household = "${householdId}"`,
        "",
        1,
        0
      );
      if (existing.length > 0) {
        catId[nom] = existing[0].id;
        continue;
      }
      const rec = new Record(catsCol);
      rec.set("household", householdId);
      rec.set("nom", nom);
      rec.set("type", type);
      rec.set("couleur", couleur);
      rec.set("icone", icone);
      if (budget !== null) rec.set("budget_mensuel", budget);
      app.save(rec);
      catId[nom] = rec.id;
    }

    // ---------------------------------------------------------------
    // 2) Récurrents — dépenses ET revenus
    // ---------------------------------------------------------------
    const recCol = app.findCollectionByNameOrId("recurrents");

    // [libelle, montant, sens, frequence, jour, categorie, personne]
    const recurrentsSeed = [
      // Dépenses récurrentes
      ["Hypothèque",         1500, "depense", "mensuel", 5,  "Logement",          me],
      ["Charges PPE",         400, "depense", "mensuel", 5,  "Logement",          me],
      ["LAMal (toi)",         490, "depense", "mensuel", 1,  "Assurance maladie", me],
      ["LAMal (ta femme)",    490, "depense", "mensuel", 1,  "Assurance maladie", partner],
      ["Crèche",             1400, "depense", "mensuel", 10, "Garde enfants",     partner],
      ["Abo CFF (toi)",       185, "depense", "mensuel", 15, "Transport",         me],
      ["Netflix",              22, "depense", "mensuel", 20, "Abonnements",       me],
      ["Spotify Family",       21, "depense", "mensuel", 12, "Abonnements",       me],
      ["3e pilier (toi)",     605, "depense", "mensuel", 25, "3e pilier",         me],
      // Revenus récurrents
      ["Salaire (toi)",      7200, "revenu",  "mensuel", 25, "Salaire",           me],
      ["Salaire (ta femme)", 4800, "revenu",  "mensuel", 25, "Salaire",           partner],
      ["Allocations",         400, "revenu",  "mensuel", 25, "Allocations",       me],
    ];

    for (const [libelle, montant, sens, freq, jour, catNom, personne] of recurrentsSeed) {
      const existing = app.findRecordsByFilter(
        "recurrents",
        `libelle = "${libelle}" && household = "${householdId}"`,
        "",
        1,
        0
      );
      if (existing.length > 0) continue;

      const rec = new Record(recCol);
      rec.set("household", householdId);
      rec.set("libelle", libelle);
      rec.set("montant", montant);
      rec.set("sens", sens);
      rec.set("frequence", freq);
      rec.set("jour_du_mois", jour);
      rec.set("categorie", catId[catNom]);
      rec.set("personne", personne);
      rec.set("actif", true);
      app.save(rec);
    }

    // ---------------------------------------------------------------
    // 3) Épargne — un snapshot
    // ---------------------------------------------------------------
    const epaCol = app.findCollectionByNameOrId("epargne");
    const epaExisting = app.findRecordsByFilter(
      "epargne",
      `libelle = "Compte épargne principal" && household = "${householdId}"`,
      "",
      1,
      0
    );
    if (epaExisting.length === 0) {
      const epa = new Record(epaCol);
      epa.set("household", householdId);
      epa.set("date", day(1));
      epa.set("libelle", "Compte épargne principal");
      epa.set("solde", 48200);
      app.save(epa);
    }

    // ---------------------------------------------------------------
    // 4) Transactions du mois en cours
    //    Inclut des dépenses avec categorie_fiscale renseignée pour
    //    valider la mécanique de déduction fiscale.
    // ---------------------------------------------------------------
    const txCol = app.findCollectionByNameOrId("transactions");

    // [jour, montant, categorie, auteur, note, categorie_fiscale]
    const transactionsSeed = [
      // Alimentation
      [3,  118.40, "Alimentation",     me,      "Migros",                       "non_deductible"],
      [7,   85.20, "Alimentation",     partner, "Coop",                         "non_deductible"],
      [12, 142.60, "Alimentation",     me,      "Migros",                       "non_deductible"],
      [18,  73.10, "Alimentation",     partner, "Coop",                         "non_deductible"],
      // Sorties
      [6,   62.00, "Sorties",          me,      "Resto vendredi soir",          "non_deductible"],
      [14,  38.50, "Sorties",          partner, "Brunch dimanche",              "non_deductible"],
      // Transport
      [8,   95.00, "Transport",        me,      "Plein d'essence",              "non_deductible"],
      // Médical — DÉDUCTIBLE
      [9,  240.00, "Frais médicaux",   partner, "Dentiste",                     "frais_medicaux"],
      [16,  68.50, "Frais médicaux",   me,      "Pharmacie hors franchise",     "frais_medicaux"],
      // Garde enfants — DÉDUCTIBLE
      [10, 1400.00,"Garde enfants",    partner, "Crèche (récurrent)",           "garde_enfants"],
      [13,  180.00,"Garde enfants",    me,      "Maman de jour appoint",        "garde_enfants"],
      // Entretien maison — DÉDUCTIBLE
      [4,  420.00, "Entretien maison", me,      "Plombier — fuite cuisine",     "entretien_immobilier"],
      [11, 180.00, "Entretien maison", me,      "Peinture extérieure",          "entretien_immobilier"],
      // Hypothèque — DÉDUCTIBLE (intérêts)
      [5,  1500.00,"Logement",         me,      "Hypothèque (récurrent)",       "interets_dette"],
      [5,   400.00,"Logement",         me,      "Charges PPE (récurrent)",      "non_deductible"],
      // Assurance maladie — DÉDUCTIBLE
      [1,   490.00,"Assurance maladie",me,      "LAMal (récurrent)",            "assurance_maladie"],
      [1,   490.00,"Assurance maladie",partner, "LAMal (récurrent)",            "assurance_maladie"],
      // 3e pilier — DÉDUCTIBLE
      [25,  605.00,"3e pilier",        me,      "3a — versement mensuel",       "3e_pilier"],
      // Activités enfants
      [2,   80.00, "Activités enfants",partner, "Cours de natation",            "non_deductible"],
      // Abonnements (récurrents déjà confirmés)
      [12,   21.00,"Abonnements",      me,      "Spotify (récurrent)",          "non_deductible"],
      [20,   22.00,"Abonnements",      me,      "Netflix (récurrent)",          "non_deductible"],
      // Numérique
      [15,   59.90,"Numérique",        me,      "Stockage cloud",               "non_deductible"],
      // Revenus
      [25, 7200.00,"Salaire",          me,      "Salaire (récurrent)",          "non_deductible"],
      [25, 4800.00,"Salaire",          partner, "Salaire (récurrent)",          "non_deductible"],
      [25,  400.00,"Allocations",      me,      "Allocations familiales",       "non_deductible"],
    ];

    for (const [jour, montant, catNom, auteur, note, fiscale] of transactionsSeed) {
      const tx = new Record(txCol);
      tx.set("household", householdId);
      tx.set("montant", montant);
      tx.set("date", day(jour));
      tx.set("categorie", catId[catNom]);
      tx.set("auteur", auteur);
      tx.set("note", note);
      tx.set("categorie_fiscale", fiscale);
      app.save(tx);
    }
  },

  // -----------------------------------------------------------------
  // DOWN : supprime les données du seed (foyer + utilisateurs intacts)
  // -----------------------------------------------------------------
  (app) => {
    const households = app.findRecordsByFilter("households", "", "", 1, 0);
    if (households.length === 0) return;
    const hid = households[0].id;

    const collections = ["transactions", "epargne", "recurrents", "categories"];
    for (const colName of collections) {
      try {
        const recs = app.findRecordsByFilter(
          colName,
          `household = "${hid}"`,
          "",
          1000,
          0
        );
        for (const r of recs) {
          try { app.delete(r); } catch (e) { /* skip */ }
        }
      } catch (e) {
        // collection absente : skip
      }
    }
  }
);
