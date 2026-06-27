/// <reference path="../pb_data/types.d.ts" />

// Patch du seed initial : renseigne recurrent_source sur les
// transactions qui correspondent à une échéance de récurrent.
//
// Sans ce lien, les providers du dashboard pensent que les échéances
// du mois n'ont pas encore été honorées et les comptent en "prévu",
// ce qui double les revenus (salaires) et gonfle les dépenses.
//
// Mapping : pour chaque transaction du seed dont la note se termine
// par " (récurrent)", on retrouve le récurrent par son libellé et on
// renseigne recurrent_source.

migrate(
  (app) => {
    // ---------------------------------------------------------------
    // 0) Foyer
    // ---------------------------------------------------------------
    const households = app.findRecordsByFilter("households", "", "", 1, 0);
    if (households.length === 0) {
      throw new Error("Aucun foyer trouvé.");
    }
    const householdId = households[0].id;

    // ---------------------------------------------------------------
    // 1) Mapping "note de la transaction" → "libellé du récurrent"
    //    On utilise la note pour identifier sans ambiguïté les
    //    transactions issues du seed.
    // ---------------------------------------------------------------
    const noteToRecurrentLibelle = {
      "Hypothèque (récurrent)":         "Hypothèque",
      "Charges PPE (récurrent)":        "Charges PPE",
      "LAMal (récurrent)":              null,        // ambigu : 2 LAMal
      "Crèche (récurrent)":             "Crèche",
      "Spotify (récurrent)":            "Spotify Family",
      "Netflix (récurrent)":            "Netflix",
      "3a — versement mensuel":         "3e pilier (toi)",
      "Salaire (récurrent)":            null,        // ambigu : 2 salaires
      "Allocations familiales":         "Allocations",
    };

    // ---------------------------------------------------------------
    // 2) Index des récurrents du foyer par libellé pour lookup rapide
    // ---------------------------------------------------------------
    const allRecurrents = app.findRecordsByFilter(
      "recurrents",
      `household = "${householdId}"`,
      "",
      500,
      0
    );
    const recByLibelle = {};
    for (const r of allRecurrents) {
      recByLibelle[r.get("libelle")] = r;
    }

    // ---------------------------------------------------------------
    // 3) Parcours des transactions du foyer et patch ciblé
    // ---------------------------------------------------------------
    const allTx = app.findRecordsByFilter(
      "transactions",
      `household = "${householdId}"`,
      "",
      1000,
      0
    );

    let patched = 0;

    for (const tx of allTx) {
      // Si déjà lié, on saute (rejouabilité).
      const existing = tx.get("recurrent_source");
      if (existing && existing.length > 0) continue;

      const note = tx.get("note") || "";
      const auteur = tx.get("auteur");

      let targetLibelle = noteToRecurrentLibelle[note];

      // Cas ambigus : on désambiguïse par l'auteur de la transaction.
      if (targetLibelle === null) {
        if (note === "LAMal (récurrent)") {
          // 2 récurrents : "LAMal (toi)" et "LAMal (ta femme)"
          const candidats = ["LAMal (toi)", "LAMal (ta femme)"];
          for (const lib of candidats) {
            const r = recByLibelle[lib];
            if (r && r.get("personne") === auteur) {
              targetLibelle = lib;
              break;
            }
          }
        } else if (note === "Salaire (récurrent)") {
          // 2 récurrents : "Salaire (toi)" et "Salaire (ta femme)"
          const candidats = ["Salaire (toi)", "Salaire (ta femme)"];
          for (const lib of candidats) {
            const r = recByLibelle[lib];
            if (r && r.get("personne") === auteur) {
              targetLibelle = lib;
              break;
            }
          }
        }
      }

      if (!targetLibelle) continue;

      const rec = recByLibelle[targetLibelle];
      if (!rec) continue;

      tx.set("recurrent_source", rec.id);
      app.save(tx);
      patched++;
    }

    console.log(
      `[patch] recurrent_source renseigné sur ${patched} transactions.`
    );
  },

  // -----------------------------------------------------------------
  // DOWN : on retire les recurrent_source qu'on a posés.
  // -----------------------------------------------------------------
  (app) => {
    const households = app.findRecordsByFilter("households", "", "", 1, 0);
    if (households.length === 0) return;
    const householdId = households[0].id;

    const allTx = app.findRecordsByFilter(
      "transactions",
      `household = "${householdId}" && recurrent_source != ""`,
      "",
      1000,
      0
    );
    for (const tx of allTx) {
      try {
        tx.set("recurrent_source", null);
        app.save(tx);
      } catch (e) { /* skip */ }
    }
  }
);