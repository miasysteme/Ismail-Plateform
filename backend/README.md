# ISMAIL Platform - Backend API

API REST Node.js/Express pour la plateforme ISMAIL avec intégration Supabase.

## 🚀 Démarrage Rapide

### Prérequis
- Node.js 18+
- npm 8+
- Compte Supabase configuré

### Installation Locale

```bash
# 1. Installer les dépendances
npm install

# 2. Configurer les variables d'environnement
cp .env.example .env
# Éditer .env avec vos vraies valeurs

# 3. Démarrer en mode développement
npm run dev

# 4. Tester l'API
curl http://localhost:8080/health
```

## 📡 Endpoints Disponibles

### Authentification
- `POST /api/v1/auth/register` - Inscription
- `POST /api/v1/auth/login` - Connexion
- `POST /api/v1/auth/refresh` - Rafraîchir token
- `GET /api/v1/auth/me` - Profil utilisateur

### Utilisateurs
- `GET /api/v1/users` - Liste utilisateurs
- `GET /api/v1/users/:id` - Détails utilisateur
- `PUT /api/v1/users/:id` - Modifier profil

### Portefeuilles
- `GET /api/v1/wallets` - Mes portefeuilles
- `GET /api/v1/wallets/balance` - Solde
- `POST /api/v1/wallets/recharge` - Recharger

### Transactions
- `GET /api/v1/transactions` - Historique
- `POST /api/v1/transactions` - Nouvelle transaction
- `GET /api/v1/transactions/:id` - Détails transaction

## 🔧 Configuration

### Variables d'Environnement

Voir `.env.example` pour la liste complète des variables.

### Base de Données

L'API utilise Supabase avec le schéma `ismail` :
- Tables : `users`, `wallets`, `transactions`
- Vues : `users_with_wallets`, `transactions_with_user`

## 🚂 Déploiement Railway

### Configuration Automatique

1. Connecter le repository à Railway
2. Sélectionner le dossier `backend/`
3. Configurer les variables d'environnement
4. Déployer automatiquement

### Variables Railway Requises

```bash
NODE_ENV=production
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key
JWT_SECRET=your-jwt-secret
```

## 🧪 Tests

```bash
# Tests unitaires
npm test

# Tests en mode watch
npm run test:watch

# Linting
npm run lint
npm run lint:fix
```

## 📚 Documentation API

Une fois démarré, la documentation Swagger sera disponible à :
- Local : http://localhost:8080/docs
- Production : https://your-railway-url/docs

## 🔐 Sécurité

- Authentification JWT
- Validation des données avec express-validator
- Rate limiting
- CORS configuré
- Helmet pour les headers de sécurité
- Hachage bcrypt pour les mots de passe

## 🏗️ Architecture

```
backend/
├── src/
│   ├── config/          # Configuration (Supabase, etc.)
│   ├── middleware/      # Middleware Express
│   ├── routes/          # Routes API
│   ├── utils/           # Utilitaires
│   └── server.js        # Point d'entrée
├── package.json
├── railway.toml         # Configuration Railway
└── README.md
```

## 🐛 Debugging

### Logs
Les logs sont configurés avec Morgan en mode développement.

### Health Check
- Endpoint : `/health`
- Vérifie la connexion Supabase
- Retourne le statut des services

## 📞 Support

Pour toute question ou problème :
- Issues GitHub : https://github.com/miasysteme/Ismail-Plateform/issues
- Email : support@ismail-platform.com
