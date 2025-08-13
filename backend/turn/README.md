# Coturn (TURN) pour KIVOU

Ce dossier fournit une configuration d’exemple et un service systemd pour déployer un serveur TURN (Coturn), indispensable pour fiabiliser les appels WebRTC derrière des NAT stricts.

## Déploiement rapide (Ubuntu/Debian)

1. Installer Coturn:
   sudo apt-get update && sudo apt-get install -y coturn

2. Copier la configuration:
   sudo cp turnserver.conf.example /etc/turnserver.conf
   sudo chown turnserver:turnserver /etc/turnserver.conf

3. Éditer /etc/turnserver.conf:

   - Définir external-ip=VOTRE_IP_PUBLIQUE
   - Définir realm=votre-domaine (ex: fidest.ci)
   - Définir user=turnuser:turnpassword (ou un userdb)
   - (Optionnel) Configurer cert/pkey pour TLS sur 5349

4. Activer et démarrer le service:
   sudo cp kivou-turn.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable kivou-turn
   sudo systemctl start kivou-turn
   sudo systemctl status kivou-turn

5. Ouvrir les ports firewall:
   - UDP 3478 (TURN) et UDP 49160-49200 (relays)
   - (Optionnel) TCP/TLS 5349

## Intégration côté app

Au build ou au run, fournir les ICE servers via --dart-define:

flutter run \
 --dart-define=TURN_URLS="turn:turn.votredomaine:3478?transport=udp,turns:turn.votredomaine:5349" \
 --dart-define=TURN_USERNAME=turnuser \
 --dart-define=TURN_PASSWORD=turnpassword

flutter build apk --release \
 --dart-define=TURN_URLS="turn:turn.votredomaine:3478?transport=udp,turns:turn.votredomaine:5349" \
 --dart-define=TURN_USERNAME=turnuser \
 --dart-define=TURN_PASSWORD=turnpassword

## Notes

- Le STUN Google est gardé en fallback.
- Si vous utilisez un reverse proxy, exposez 5349 en TLS et/ou 3478 en UDP directement.
- Pour forte charge, préférez un userdb et des credentials temporaires (TURN REST API) : option à implémenter plus tard.
