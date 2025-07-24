# Services Core ISMAIL - Guide de Déploiement

## 🏗️ Architecture des Services

### Vue d'Ensemble
```
┌─────────────────────────────────────────────────────────────┐
│                    ISMAIL Services Layer                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │  Kong Gateway   │ │  Auth Service   │ │ Wallet Service  ││
│  │   (Port 80)     │ │   (Port 8080)   │ │   (Port 8080)   ││
│  │                 │ │                 │ │                 ││
│  │ • Rate Limiting │ │ • JWT Tokens    │ │ • Portefeuilles ││
│  │ • Load Balancer │ │ • KYC Biométrie │ │ • Transactions  ││
│  │ • SSL/TLS       │ │ • Sessions      │ │ • Commissions   ││
│  │ • API Routing   │ │ • Cartes Pro    │ │ • Paiements     ││
│  │ • Monitoring    │ │ • Audit         │ │ • Rapports      ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
│                                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ User Service    │ │ Notification    │ │ Business        ││
│  │   (Port 8080)   │ │    Service      │ │   Modules       ││
│  │                 │ │   (Port 8080)   │ │   (Port 8080)   ││
│  │ • Profils       │ │ • Email/SMS     │ │ • Services      ││
│  │ • Préférences   │ │ • Push Notifs   │ │ • Shop          ││
│  │ • Géolocation   │ │ • Templates     │ │ • Booking       ││
│  │ • Documents     │ │ • Historique    │ │ • Real Estate   ││
│  │ • Analytics     │ │ • Scheduling    │ │ • Recovery      ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Déploiement Rapide

### Prérequis
```bash
# Outils requis
kubectl version --client
helm version
docker version
mvn --version

# Variables d'environnement
export ENVIRONMENT=dev
export NAMESPACE=ismail-core
```

### 1. Déploiement Kong API Gateway

```bash
# Rendre le script exécutable
chmod +x infrastructure/scripts/setup-kong.sh

# Déployer Kong
./infrastructure/scripts/setup-kong.sh dev

# Vérifier le déploiement
kubectl get pods -n ismail-ingress
kubectl get services -n ismail-ingress
```

### 2. Construction des Services

```bash
# Service d'authentification
cd services/auth-service
mvn clean package -DskipTests
mvn jib:build

# Service portefeuille
cd ../wallet-service
mvn clean package -DskipTests
mvn jib:build

# Retour au répertoire racine
cd ../..
```

### 3. Déploiement des Services

```bash
# Créer le namespace
kubectl create namespace ismail-core

# Déployer les services
kubectl apply -f infrastructure/k8s/services/
```

## 📋 Services Développés

### 🔐 **Auth Service** - Service d'Authentification

#### **Fonctionnalités Principales**
- **Inscription/Connexion** avec validation complète
- **JWT Tokens** avec refresh automatique
- **KYC Biométrique** avec SDK intégré
- **Sessions Multi-Appareils** avec gestion centralisée
- **Cartes Professionnelles** avec QR codes sécurisés
- **Audit Complet** pour conformité RGPD

#### **Endpoints Principaux**
```
POST /api/auth/register          # Inscription utilisateur
POST /api/auth/login             # Connexion
POST /api/auth/refresh           # Rafraîchir token
POST /api/auth/logout            # Déconnexion
GET  /api/auth/profile           # Profil utilisateur
POST /api/auth/kyc/start         # Démarrer KYC
POST /api/auth/kyc/biometric     # Données biométriques
GET  /api/auth/professional-card # Carte professionnelle
```

#### **Technologies Utilisées**
- **Spring Boot 3.2** avec Java 21
- **Spring Security** avec JWT
- **PostgreSQL** pour persistance
- **Redis** pour sessions et cache
- **MapStruct** pour mapping
- **Flyway** pour migrations
- **Testcontainers** pour tests

### 💰 **Wallet Service** - Service Portefeuille

#### **Fonctionnalités Principales**
- **Portefeuilles Multi-Devises** avec conversion automatique
- **Transactions Sécurisées** avec validation PIN
- **Intégration Paiements** (Orange Money, MTN, Wave, Cartes)
- **Commissions Automatiques** pour commerciaux
- **Limites Configurables** par profil utilisateur
- **Rapports Financiers** en temps réel

#### **Endpoints Principaux**
```
GET  /api/wallet/balance         # Solde portefeuille
POST /api/wallet/credit          # Créditer le compte
POST /api/wallet/transfer        # Transfert entre comptes
GET  /api/wallet/transactions    # Historique transactions
POST /api/wallet/withdraw        # Retrait vers mobile money
GET  /api/wallet/commissions     # Commissions gagnées
```

#### **Moyens de Paiement Intégrés**
- **Orange Money** (API REST)
- **MTN Mobile Money** (API REST)
- **Wave** (API REST)
- **Cartes Bancaires** (Stripe)
- **Virements Bancaires** (API bancaires)

### 🌐 **Kong API Gateway** - Passerelle API

#### **Fonctionnalités Configurées**
- **Rate Limiting** par utilisateur et endpoint
- **Load Balancing** avec health checks
- **SSL/TLS** avec certificats automatiques
- **CORS** configuré pour applications web/mobile
- **JWT Validation** avec plugin personnalisé
- **Monitoring** avec métriques Prometheus

#### **Plugins Activés**
- **CORS** : Support multi-domaines
- **Rate Limiting** : Protection DDoS
- **JWT** : Validation tokens
- **Prometheus** : Métriques
- **Request Transformer** : Headers personnalisés
- **Response Transformer** : Réponses standardisées

#### **Routes Configurées**
```
/api/auth/*          → auth-service
/api/wallet/*        → wallet-service
/api/users/*         → user-service
/api/notifications/* → notification-service
/api/services/*      → services-module
/api/shop/*          → shop-module
/api/booking/*       → booking-module
/api/realestate/*    → realestate-module
/api/recovery/*      → recovery-module
```

## 🔧 Configuration et Sécurité

### **Authentification JWT**

#### **Structure du Token**
```json
{
  "iss": "ismail-platform",
  "aud": "ismail-api",
  "sub": "user-uuid",
  "user_id": "user-uuid",
  "ismail_id": "CI241201-A1B2-CL",
  "email": "user@example.com",
  "profile_type": "CLIENT",
  "permissions": ["READ_PROFILE", "MANAGE_WALLET"],
  "session_id": "session-uuid",
  "iat": 1701234567,
  "exp": 1701238167
}
```

#### **Validation Multi-Niveaux**
1. **Kong Gateway** : Validation signature et expiration
2. **Service Auth** : Validation session active
3. **Services Métier** : Validation permissions spécifiques

### **Sécurité des Transactions**

#### **Validation PIN**
- **Chiffrement** : PIN hashé avec bcrypt
- **Tentatives** : Maximum 3 tentatives
- **Verrouillage** : 15 minutes après échec
- **Audit** : Toutes les tentatives loggées

#### **Limites Dynamiques**
```yaml
# Limites par défaut
daily-limit: 1,000,000 FCFA
monthly-limit: 10,000,000 FCFA
max-balance: 50,000,000 FCFA
min-transfer: 100 FCFA
max-transfer: 5,000,000 FCFA
```

### **KYC Biométrique**

#### **Processus de Vérification**
1. **Documents** : Pièce d'identité + selfie
2. **Biométrie** : Empreintes + reconnaissance faciale
3. **Validation** : Algorithmes IA + validation manuelle
4. **Certification** : Carte professionnelle générée

#### **Niveaux de Confiance**
- **Niveau 1** : Documents uniquement (limites réduites)
- **Niveau 2** : Documents + biométrie (limites normales)
- **Niveau 3** : Validation manuelle (limites maximales)

## 📊 Monitoring et Métriques

### **Métriques Kong**
```
kong_http_requests_total
kong_latency_bucket
kong_bandwidth_bytes
kong_upstream_health
```

### **Métriques Services**
```
http_requests_total
http_request_duration_seconds
jvm_memory_used_bytes
database_connections_active
redis_commands_processed_total
```

### **Dashboards Grafana**
- **Kong Gateway** : Trafic, latence, erreurs
- **Auth Service** : Connexions, KYC, sessions
- **Wallet Service** : Transactions, soldes, commissions
- **Business Metrics** : Utilisateurs actifs, revenus

## 🧪 Tests et Qualité

### **Tests Automatisés**

#### **Tests Unitaires**
```bash
# Auth Service
cd services/auth-service
mvn test

# Wallet Service
cd services/wallet-service
mvn test
```

#### **Tests d'Intégration**
```bash
# Avec Testcontainers
mvn verify -P integration-tests
```

#### **Tests de Performance**
```bash
# Load testing avec K6
k6 run tests/performance/auth-load-test.js
k6 run tests/performance/wallet-load-test.js
```

### **Couverture de Code**
- **Objectif** : >80% de couverture
- **Outil** : JaCoCo
- **Rapports** : Générés automatiquement

### **Qualité du Code**
- **SonarQube** : Analyse statique
- **Checkstyle** : Standards de codage
- **SpotBugs** : Détection de bugs

## 🔄 CI/CD Pipeline

### **Pipeline GitLab CI**
```yaml
stages:
  - build
  - test
  - security-scan
  - build-image
  - deploy-dev
  - integration-tests
  - deploy-staging
  - deploy-prod
```

### **Déploiement Automatique**
1. **Build** : Compilation et tests
2. **Security** : Scan vulnérabilités
3. **Image** : Construction Docker
4. **Deploy** : Déploiement Kubernetes
5. **Verify** : Tests de santé

## 📞 Support et Dépannage

### **Logs et Debugging**

#### **Consulter les Logs**
```bash
# Kong Gateway
kubectl logs -n ismail-ingress -l app.kubernetes.io/name=kong

# Auth Service
kubectl logs -n ismail-core -l app=auth-service

# Wallet Service
kubectl logs -n ismail-core -l app=wallet-service
```

#### **Debug Mode**
```bash
# Activer debug pour un service
kubectl set env deployment/auth-service LOG_LEVEL=DEBUG -n ismail-core
```

### **Health Checks**

#### **Vérifier la Santé des Services**
```bash
# Kong
curl http://kong-admin:8001/status

# Auth Service
curl http://auth-service:8080/actuator/health

# Wallet Service
curl http://wallet-service:8080/actuator/health
```

### **Problèmes Courants**

#### **Kong ne démarre pas**
1. Vérifier la base de données Kong
2. Contrôler les secrets Kubernetes
3. Valider la configuration

#### **Service d'auth inaccessible**
1. Vérifier les routes Kong
2. Contrôler les secrets JWT
3. Valider la base de données

#### **Transactions échouent**
1. Vérifier les limites utilisateur
2. Contrôler les moyens de paiement
3. Valider les soldes

---

**🎯 Services Core déployés et opérationnels !**

*Architecture robuste, sécurisée et scalable pour la plateforme ISMAIL.*
