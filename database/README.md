# Bases de Données ISMAIL - Guide de Déploiement

## 🗄️ Architecture des Données

### Vue d'Ensemble
```
┌─────────────────────────────────────────────────────────────┐
│                    ISMAIL Data Layer                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   PostgreSQL    │ │     MongoDB     │ │      Redis      ││
│  │   (AWS RDS)     │ │  (Kubernetes)   │ │ (ElastiCache)   ││
│  │                 │ │                 │ │                 ││
│  │ • Users & Auth  │ │ • User Profiles │ │ • Sessions      ││
│  │ • Wallets       │ │ • Products      │ │ • Cache API     ││
│  │ • Transactions  │ │ • Reviews       │ │ • Queues        ││
│  │ • Bookings      │ │ • Notifications │ │ • Rate Limiting ││
│  │ • Properties    │ │ • Analytics     │ │ • Geolocation   ││
│  │ • Recovery      │ │ • CMS Content   │ │ • Real-time     ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Répartition des Données

#### PostgreSQL (Données Transactionnelles)
- **Users & Authentication** : Comptes, KYC, sessions
- **Wallets & Transactions** : Portefeuilles, crédits, commissions
- **Business Data** : Réservations, commandes, biens immobiliers
- **Recovery** : Dossiers de recouvrement, actions
- **Audit** : Logs d'audit, conformité

#### MongoDB (Données Flexibles)
- **User Profiles** : Profils étendus, préférences
- **Product Catalog** : Catalogue produits, variantes
- **Reviews & Ratings** : Avis, évaluations, commentaires
- **Notifications** : Messages, templates, historique
- **Analytics** : Événements, métriques, rapports
- **CMS** : Contenus, pages, articles

#### Redis (Cache & Sessions)
- **Sessions** : Sessions utilisateur, tokens JWT
- **API Cache** : Cache des réponses API
- **Queues** : Files d'attente (email, SMS, push)
- **Rate Limiting** : Limitation de débit
- **Geolocation** : Cache géospatial
- **Real-time** : Compteurs, métriques temps réel

## 🚀 Déploiement Rapide

### Prérequis
```bash
# Outils requis
kubectl version --client
helm version
psql --version
mongosh --version

# Variables d'environnement
export ENVIRONMENT=dev  # ou staging, prod
```

### Déploiement Automatique
```bash
# Rendre le script exécutable
chmod +x database/scripts/deploy-databases.sh

# Déployer toutes les bases de données
./database/scripts/deploy-databases.sh dev
```

### Déploiement Manuel

#### 1. PostgreSQL (RDS)
```bash
# PostgreSQL est déjà créé par Terraform
# Récupérer les informations de connexion
cd infrastructure/terraform
POSTGRES_HOST=$(terraform output -raw postgres_endpoint)
POSTGRES_PASSWORD=$(terraform output -raw postgres_password)

# Initialiser la base
export PGPASSWORD="$POSTGRES_PASSWORD"
psql -h "$POSTGRES_HOST" -U postgres -d postgres -f database/postgresql/init-database.sql

# Exécuter les migrations
psql -h "$POSTGRES_HOST" -U postgres -d ismail_main -f database/postgresql/migrations/001_create_core_tables.sql

# Insérer les données de test (dev uniquement)
psql -h "$POSTGRES_HOST" -U postgres -d ismail_main -f database/seeds/seed-data.sql
```

#### 2. MongoDB
```bash
# Déployer MongoDB avec Helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm install mongodb bitnami/mongodb \
  --namespace ismail-data \
  --values infrastructure/helm/mongodb/values.yaml \
  --wait

# Initialiser les collections
kubectl port-forward -n ismail-data svc/mongodb 27017:27017 &
MONGODB_PASSWORD=$(kubectl get secret mongodb -n ismail-data -o jsonpath="{.data.mongodb-root-password}" | base64 -d)

mongosh "mongodb://admin:${MONGODB_PASSWORD}@localhost:27017/admin" \
  --file database/mongodb/init-collections.js
```

#### 3. Redis (ElastiCache)
```bash
# Redis est déjà créé par Terraform
# Récupérer les informations de connexion
REDIS_HOST=$(terraform output -raw redis_endpoint)
REDIS_PASSWORD=$(terraform output -raw redis_auth_token)

# Tester la connexion
redis-cli -h "$REDIS_HOST" -p 6379 -a "$REDIS_PASSWORD" ping
```

## 📊 Configuration des Bases

### PostgreSQL - Schémas et Tables

#### Schémas Organisés
```sql
-- Schéma core (authentification, portefeuille)
core.users                 -- Utilisateurs principaux
core.user_biometrics       -- Données biométriques chiffrées
core.professional_cards    -- Cartes d'identité digitales
core.wallets               -- Portefeuilles électroniques
core.transactions          -- Transactions (partitionnées)
core.commissions           -- Commissions commerciales

-- Schéma business (modules métier)
business.service_providers -- Prestataires de services
business.service_bookings  -- Réservations de services
business.shop_orders       -- Commandes e-commerce
business.hotel_bookings    -- Réservations hôtelières
business.real_estate_properties -- Biens immobiliers
business.recovery_cases    -- Dossiers de recouvrement

-- Schéma audit (conformité)
audit.audit_log           -- Logs d'audit (partitionnés)

-- Schéma analytics (vues et statistiques)
analytics.user_stats      -- Statistiques utilisateurs
analytics.wallet_stats    -- Statistiques portefeuilles
analytics.transaction_stats -- Statistiques transactions
```

#### Fonctionnalités Avancées
- **Partitioning** : Tables transactions et audit partitionnées par mois
- **Géolocalisation** : Extension PostGIS pour services de proximité
- **Chiffrement** : Fonctions de chiffrement pour données sensibles
- **Audit** : Triggers automatiques pour traçabilité complète
- **Performance** : Index optimisés, statistiques automatiques

### MongoDB - Collections et Validation

#### Collections Principales
```javascript
// Profils utilisateurs avec géolocalisation
user_profiles {
  userId: "uuid-reference",
  avatar: { url, thumbnailUrl },
  location: { type: "Point", coordinates: [lng, lat] },
  preferences: { language, currency, notifications },
  documents: [{ type, url, verificationStatus }]
}

// Catalogue produits avec recherche full-text
products {
  merchantId: "uuid-reference",
  name: "string",
  description: "string",
  price: NumberDecimal,
  stock: { quantity, lowStockThreshold },
  variants: [{ id, name, price, stock }],
  images: [{ url, alt, position }],
  rating: { average, count }
}

// Avis et évaluations
reviews {
  authorId: "uuid-reference",
  targetId: "uuid-reference",
  targetType: "PRODUCT|SERVICE|PROVIDER",
  rating: 1-5,
  comment: "string",
  isVerifiedPurchase: boolean
}

// Notifications multi-canal
notifications {
  userId: "uuid-reference",
  type: "ORDER_CONFIRMED|PAYMENT_RECEIVED|...",
  title: "string",
  message: "string",
  channels: ["PUSH", "EMAIL", "SMS"],
  status: "PENDING|SENT|DELIVERED|READ"
}
```

#### Index et Performance
- **Géospatial** : Index 2dsphere pour géolocalisation
- **Text Search** : Index full-text pour recherche produits
- **TTL** : Expiration automatique des événements analytics
- **Compound** : Index composés pour requêtes complexes

### Redis - Organisation et Patterns

#### Structure des Clés
```redis
# Sessions utilisateur (DB 0)
user:session:{user_id} -> JSON session data (TTL: 24h)

# Cache API (DB 1)
api:cache:{endpoint}:{params_hash} -> JSON response (TTL: 5min)

# Queues de traitement (DB 2)
queue:notifications -> List of notification jobs
queue:emails -> List of email jobs
queue:sms -> List of SMS jobs

# Rate limiting (DB 3)
rate_limit:api:{user_id}:{endpoint} -> request count (TTL: 1h)
rate_limit:login:{ip} -> attempt count (TTL: 15min)

# Géolocalisation (DB 4)
geo:providers:{category} -> Geospatial index of providers

# Analytics temps réel (DB 5)
stats:daily:transactions:{date} -> count
stats:user:login:{user_id} -> timestamp

# Notifications (DB 6)
notif:preferences:{user_id} -> JSON preferences
notif:templates:{type} -> JSON template
```

#### Patterns Utilisés
- **Cache-Aside** : Cache des profils utilisateurs
- **Write-Through** : Soldes de portefeuille
- **Pub/Sub** : Notifications temps réel
- **Leaderboard** : Classements avec ZSET
- **Rate Limiting** : Sliding window avec ZSET

## 🔧 Maintenance et Monitoring

### Sauvegardes Automatiques

#### PostgreSQL
```bash
# Backup quotidien automatique (RDS)
# Rétention: 30 jours (prod), 7 jours (dev)

# Backup manuel
pg_dump -h $POSTGRES_HOST -U postgres -d ismail_main > backup_$(date +%Y%m%d).sql
```

#### MongoDB
```bash
# Backup avec mongodump
mongodump --uri="mongodb://admin:password@mongodb.ismail-data.svc.cluster.local:27017/ismail_main" \
  --out=/backup/mongodb_$(date +%Y%m%d)

# Restauration
mongorestore --uri="mongodb://admin:password@mongodb.ismail-data.svc.cluster.local:27017/ismail_main" \
  /backup/mongodb_20241201/ismail_main
```

#### Redis
```bash
# Backup RDB automatique (ElastiCache)
# Snapshot quotidien avec rétention 7 jours

# Backup manuel
redis-cli -h $REDIS_HOST -p 6379 -a $REDIS_PASSWORD BGSAVE
```

### Monitoring et Métriques

#### Dashboards Grafana
- **PostgreSQL** : Connexions, requêtes lentes, taille des tables
- **MongoDB** : Opérations, réplication, index usage
- **Redis** : Mémoire, hit rate, connexions, latence

#### Alertes Configurées
- **PostgreSQL** : Connexions > 80%, requêtes > 5s
- **MongoDB** : Réplication lag > 10s, opérations lentes
- **Redis** : Mémoire > 85%, hit rate < 90%

### Optimisation Performance

#### PostgreSQL
```sql
-- Analyse des requêtes lentes
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
WHERE mean_time > 1000 
ORDER BY mean_time DESC;

-- Statistiques des index
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes 
WHERE idx_scan = 0;
```

#### MongoDB
```javascript
// Profiling des opérations lentes
db.setProfilingLevel(2, { slowms: 1000 });
db.system.profile.find().sort({ ts: -1 }).limit(5);

// Statistiques des index
db.products.getIndexes();
db.products.stats().indexSizes;
```

#### Redis
```bash
# Statistiques mémoire
redis-cli -h $REDIS_HOST -a $REDIS_PASSWORD INFO memory

# Analyse des clés
redis-cli -h $REDIS_HOST -a $REDIS_PASSWORD --bigkeys

# Monitoring en temps réel
redis-cli -h $REDIS_HOST -a $REDIS_PASSWORD MONITOR
```

## 🔒 Sécurité et Conformité

### Chiffrement
- **PostgreSQL** : Chiffrement au repos (RDS), TLS en transit
- **MongoDB** : Chiffrement au repos et en transit
- **Redis** : AUTH token, TLS activé

### Accès et Permissions
- **Utilisateurs dédiés** par service avec permissions minimales
- **Secrets Kubernetes** pour credentials
- **Network Policies** pour isolation réseau
- **Audit logging** pour traçabilité complète

### Conformité RGPD
- **Chiffrement** des données personnelles
- **Pseudonymisation** des identifiants
- **Rétention** automatique (5 ans max)
- **Droit à l'oubli** avec scripts de suppression

## 📞 Support et Dépannage

### Connexions aux Bases
```bash
# PostgreSQL
kubectl get secret postgres-credentials -n ismail-core -o jsonpath='{.data.host}' | base64 -d

# MongoDB
kubectl port-forward -n ismail-data svc/mongodb 27017:27017

# Redis
kubectl get secret redis-credentials -n ismail-core -o jsonpath='{.data.host}' | base64 -d
```

### Commandes Utiles
```bash
# Vérifier l'état des pods
kubectl get pods -n ismail-data

# Logs MongoDB
kubectl logs -n ismail-data -l app.kubernetes.io/name=mongodb

# Métriques Redis
kubectl port-forward -n ismail-data svc/redis-metrics 9121:9121
```

### Problèmes Courants
1. **Connexion refusée** : Vérifier les secrets et network policies
2. **Performances lentes** : Analyser les index et requêtes
3. **Espace disque** : Monitoring des volumes persistants
4. **Réplication MongoDB** : Vérifier le statut du replica set

---

**🎯 Bases de données prêtes pour la plateforme ISMAIL !**

*Architecture robuste, sécurisée et scalable pour supporter la croissance de la plateforme.*
