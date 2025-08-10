# KIVOU Backend (PHP + MySQL)

Base URL (prod): https://fidest.ci/kivou/backend

## Déploiement rapide

1. Importer `schema.sql` dans MySQL.
2. Déployer le dossier `backend/` sur votre hébergement dans `kivou/backend`.
3. Éditer `config.php` si nécessaire (hôte, identifiants DB).
4. Vérifier PHP >= 7.4 et extension PDO MySQL activée.

## Endpoints

- POST `/api/auth/register.php` { email, password, name, phone? }
- POST `/api/auth/login.php` { email, password }
- GET `/api/providers/list.php` ?category=...&minRating=...&q=...
- POST `/api/providers/upload_photo.php` multipart/form-data file=..., provider_id?
- POST `/api/bookings/create.php` ...
- GET `/api/bookings/list_by_user.php?user_id=...`
- POST `/api/reviews/create.php` ...

Uploads: `/uploads/` (public). Assurez-vous que le dossier est accessible en écriture.

## Sécurité minimale

- Les endpoints actuels ne gèrent pas encore de tokens JWT. Il est conseillé d’ajouter une couche d’authentification (JWT ou session) selon vos besoins.
- Évitez d’exposer `config.php` en dehors du serveur PHP.

## Architecture (maintenable)

- `src/Support/Autoload.php` — autoload PSR-4 minimal pour `Kivou\` et `App\`.
- `src/Support/Database.php` — PDO singleton (Database::connect/::pdo).
- `src/Support/Request.php` et `src/Support/Response.php` — helpers JSON.
- `src/Models/` — modèles (User, ServiceProvider) + sérialisation `json()`.
- `src/Repositories/` — accès SQL encapsulé (UserRepository, ServiceProviderRepository).
- `src/Services/` — logique métier (AuthService).

Endpoints refactorisés: auth/login, auth/register, providers/list utilisent ces couches.

## Test rapide

- Importer `schema.sql`.
- Configurer `backend/config.php` (les identifiants DB y sont déjà renseignés).
- Tester:
  - POST `/api/auth/register.php`
  - POST `/api/auth/login.php`
  - GET `/api/providers/list.php`
