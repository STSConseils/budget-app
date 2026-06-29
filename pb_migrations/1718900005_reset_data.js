/// <reference path="../pb_data/types.d.ts" />

// ============================================================
//  RESET DES DONNÉES DE TEST
// ============================================================
// Vide les collections de données métier pour repartir à zéro,
// SANS toucher :
//   - au schéma (les collections restent en place)
//   - aux comptes utilisateurs (collection users)
//   - aux foyers (collection households)
//
// ⚠️ SUPPRESSION IRRÉVERSIBLE. Cette migration s'exécute
//    automatiquement au redémarrage de PocketBase, une seule fois.
//    Ne la déploie QUE lorsque tu es prêt à effacer tes données de test.
//
// Pour la rejouer plus tard (nouveau reset), renomme le fichier avec
// un timestamp plus grand (ex. 1718900006_reset_data.js).
// ============================================================

migrate(
  (app) => {
    // ----- Réglages : mets à false ce que tu veux CONSERVER -----
    const WIPE_TRANSACTIONS = true;
    const WIPE_PERSO        = true;
    const WIPE_RECURRENTS   = true;
    const WIPE_EPARGNE      = true;
    const WIPE_CATEGORIES   = false; // par défaut : on GARDE les catégories
    // ------------------------------------------------------------
    // Astuce : passe WIPE_CATEGORIES à true si tu veux aussi repartir
    // sans aucune catégorie. Sinon, tes 19 catégories sont conservées
    // (tu les édites/supprimes ensuite à la main dans l'app si besoin).

    const wipe = (collectionName) => {
      let total = 0;
      // Boucle tant qu'il reste des enregistrements (par lots de 200).
      while (true) {
        const recs = app.findRecordsByFilter(collectionName, "", "", 200, 0);
        if (recs.length === 0) break;
        for (const r of recs) {
          app.delete(r);
          total++;
        }
      }
      console.log(`[reset] ${collectionName} : ${total} enregistrement(s) supprimé(s).`);
    };

    // Ordre IMPORTANT : on supprime d'abord ce qui référence les autres
    // collections (clés étrangères en cascadeDelete:false), sinon la
    // suppression est refusée.
    //   transactions → référence categories, recurrents, users, households
    //   perso_ledger → référence categories, users
    //   recurrents   → référence categories, users, households
    //   epargne      → référence households uniquement
    //   categories   → référencée par les précédentes (donc en DERNIER)

    if (WIPE_TRANSACTIONS) wipe("transactions");
    if (WIPE_PERSO)        wipe("perso_ledger");
    if (WIPE_RECURRENTS)   wipe("recurrents");
    if (WIPE_EPARGNE)      wipe("epargne");
    if (WIPE_CATEGORIES)   wipe("categories");

    console.log("[reset] Terminé. Schéma, utilisateurs et foyers conservés.");
  },

  // -----------------------------------------------------------------
  // DOWN : impossible de restaurer des données supprimées. No-op.
  // -----------------------------------------------------------------
  (app) => {
    // Rien à faire — les données effacées ne peuvent pas être recréées.
  }
);
