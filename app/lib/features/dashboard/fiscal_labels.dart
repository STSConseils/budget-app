String? fiscalPosteLabel(String nom) {
  final n = nom.toLowerCase();
  if (n.contains('hypoth')) return 'Intérêts hypothécaires';
  if (n.contains('lamal') || n.contains('assurance maladie') || n.contains('caisse maladie')) return 'LAMal';
  if (n.contains('crèche') || n.contains('creche') || n.contains('garde') || n.contains('parascolaire')) return 'Frais de garde';
  if (n.contains('pilier') || n.contains('prévoyance')) return '3e pilier';
  if (n.contains('médic') || n.contains('medic') || n.contains('franchis') || n.contains('dentiste')) return 'Frais médicaux';
  if (n.contains('entretien') || n.contains('rénovation')) return 'Entretien immobilier';
  return null;
}
