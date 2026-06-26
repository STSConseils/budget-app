const fiscalCodes = [
  'non_deductible',
  'entretien_immobilier',
  'garde_enfants',
  'frais_medicaux',
  'assurance_maladie',
  'dons',
  'formation',
  '3e_pilier',
  'frais_professionnels',
  'interets_dette',
  'pension_alimentaire',
];

String? fiscalPosteLabel(String code) => switch (code) {
      'entretien_immobilier' => 'Entretien immobilier',
      'garde_enfants' => 'Frais de garde',
      'frais_medicaux' => 'Frais médicaux',
      'assurance_maladie' => 'LAMal / Assurance',
      'dons' => 'Dons',
      'formation' => 'Formation',
      '3e_pilier' => '3e pilier',
      'frais_professionnels' => 'Frais professionnels',
      'interets_dette' => 'Intérêts hypothécaires',
      'pension_alimentaire' => 'Pension alimentaire',
      _ => null,
    };
