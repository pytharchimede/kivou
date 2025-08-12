<?php
// Copiez ce fichier en config.local.php (même dossier) pour définir vos variables d'environnement localement.
// Il sera automatiquement inclus par config.php s'il existe.

// Chemin vers le fichier JSON du compte de service Firebase (en dehors du webroot si possible)
putenv('FIREBASE_SA_PATH=/var/www/secure/firebase_sa.json');

// Optionnel: surdéfinir le project id si nécessaire
putenv('FIREBASE_PROJECT_ID=coralys-27476');

// Alternative: injecter directement le contenu JSON (évitez sur shared hosting)
// putenv('FIREBASE_SA_JSON=' . file_get_contents('/var/www/secure/firebase_sa.json'));
