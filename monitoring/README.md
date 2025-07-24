# Monitoring et Tests ISMAIL - Guide Complet

## 🎯 Vue d'Ensemble

Cette documentation couvre l'ensemble de la stack de monitoring et de tests pour la plateforme ISMAIL, incluant :

- **Monitoring** : Prometheus, Grafana, AlertManager
- **Tests d'Intégration** : Testcontainers avec PostgreSQL, Redis, Kong
- **Tests de Performance** : K6 avec scénarios réalistes
- **Observabilité** : Métriques, logs, traces et alertes

## 📊 Architecture de Monitoring

### Stack Complète
```
┌─────────────────────────────────────────────────────────────┐
│                    ISMAIL Monitoring Stack                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Prometheus    │ │     Grafana     │ │  AlertManager   ││
│  │   (Métriques)   │ │  (Dashboards)   │ │   (Alertes)     ││
│  │                 │ │                 │ │                 ││
│  │ • Collecte      │ │ • Visualisation │ │ • Notifications ││
│  │ • Stockage      │ │ • Dashboards    │ │ • Escalade      ││
│  │ • Requêtes      │ │ • Alertes       │ │ • Intégrations  ││
│  │ • Règles        │ │ • Utilisateurs  │ │ • Templates     ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
│                                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Exporters     │ │   ServiceMon    │ │     Logs        ││
│  │                 │ │                 │ │                 ││
│  │ • PostgreSQL    │ │ • Kong          │ │ • Centralisés   ││
│  │ • Redis         │ │ • Services      │ │ • Structurés    ││
│  │ • MongoDB       │ │ • Kubernetes    │ │ • Recherche     ││
│  │ • Node          │ │ • Applications  │ │ • Rétention     ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Déploiement Rapide

### 1. Déploiement Monitoring

```bash
# Configuration
export ENVIRONMENT=dev
export SENDGRID_API_KEY=your-api-key
export SLACK_WEBHOOK_URL=your-webhook-url

# Déploiement complet
chmod +x infrastructure/scripts/setup-monitoring.sh
./infrastructure/scripts/setup-monitoring.sh dev
```

### 2. Accès aux Interfaces

```bash
# Grafana (admin/mot-de-passe-généré)
kubectl port-forward -n ismail-monitoring svc/grafana 3000:3000

# Prometheus
kubectl port-forward -n ismail-monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# AlertManager
kubectl port-forward -n ismail-monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```

## 📈 Dashboards Grafana

### **Kong API Gateway Dashboard**
- **Métriques Principales** :
  - Requests per Second (RPS)
  - Latence P95/P99
  - Taux d'erreur par service
  - Santé des upstreams
  - Utilisation mémoire Kong

- **Alertes Configurées** :
  - Kong indisponible (>2min)
  - Latence >1s (>5min)
  - Taux d'erreur >5% (>5min)
  - Upstream down (>2min)

### **Services Core Dashboard**
- **Auth Service** :
  - Tentatives de connexion (succès/échec)
  - Sessions actives
  - Statut KYC (pending/verified/rejected)
  - Temps de réponse par endpoint

- **Wallet Service** :
  - Taux de transactions (succès/échec)
  - Solde total des portefeuilles
  - Commissions payées
  - Volume de transactions

- **Infrastructure** :
  - Utilisation JVM (mémoire, GC)
  - Pool de connexions DB
  - Cache Redis (hit rate)
  - Métriques Kubernetes

### **Business Metrics Dashboard**
- **KPIs Métier** :
  - Utilisateurs actifs quotidiens/mensuels
  - Volume de transactions par jour
  - Revenus générés
  - Taux de conversion inscription→KYC

- **Géolocalisation** :
  - Répartition des utilisateurs par pays
  - Transactions par région
  - Performance par zone géographique

## 🚨 Système d'Alertes

### **Alertes Critiques** (Notification immédiate)
```yaml
# Infrastructure
- Nœud Kubernetes down (>5min)
- Kong API Gateway indisponible (>2min)
- Base de données inaccessible (>2min)

# Services
- Service core indisponible (>2min)
- Taux d'erreur >5% (>5min)
- Latence P95 >2s (>5min)

# Sécurité
- Attaque brute force détectée
- Accès non autorisé répété
- Pattern de transactions suspect
```

### **Alertes Warning** (Notification différée)
```yaml
# Performance
- CPU >80% (>10min)
- Mémoire >85% (>10min)
- Disque >90% (>5min)

# Business
- Taux d'échec connexion >20% (>5min)
- Arriéré KYC >100 (>30min)
- Solde total portefeuilles faible
```

### **Canaux de Notification**
- **Email** : ops@ismail-platform.com (toutes alertes)
- **Slack** : #alerts-critical (alertes critiques)
- **SMS** : Numéros d'astreinte (alertes critiques uniquement)

## 🧪 Tests d'Intégration

### **Architecture Testcontainers**
```java
@Testcontainers
class AuthServiceIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("ismail_test")
            .withUsername("test_user")
            .withPassword("test_password");
    
    @Container
    static GenericContainer<?> redis = new GenericContainer<>("redis:7-alpine")
            .withExposedPorts(6379);
    
    @Container
    static GenericContainer<?> kong = new GenericContainer<>("kong:3.4")
            .withExposedPorts(8000, 8001);
}
```

### **Scénarios de Test**
1. **Inscription Utilisateur** :
   - Validation des données
   - Génération ID ISMAIL
   - Création portefeuille
   - Envoi notifications

2. **Authentification** :
   - Connexion valide/invalide
   - Gestion sessions
   - Refresh tokens
   - Rate limiting

3. **Transactions Portefeuille** :
   - Crédit/débit
   - Transferts entre comptes
   - Validation PIN
   - Limites quotidiennes

### **Exécution des Tests**
```bash
# Tests d'intégration complets
cd tests/integration
mvn clean verify -Dspring.profiles.active=test

# Tests spécifiques
mvn test -Dtest=AuthServiceIntegrationTest
mvn test -Dtest=WalletServiceIntegrationTest
```

## ⚡ Tests de Performance

### **Configuration K6**
```javascript
export const options = {
  stages: [
    { duration: '2m', target: 10 },   // Montée progressive
    { duration: '5m', target: 50 },   // Charge normale
    { duration: '10m', target: 100 }, // Charge élevée
    { duration: '5m', target: 200 },  // Pic de charge
    { duration: '5m', target: 0 },    // Descente
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% < 2s
    http_req_failed: ['rate<0.05'],    // Erreurs < 5%
  },
};
```

### **Scénarios Réalistes**

#### **Service d'Authentification**
- **30%** Inscriptions nouvelles
- **50%** Connexions existantes
- **20%** Accès profil/sessions

#### **Service Portefeuille**
- **40%** Consultation solde
- **20%** Historique transactions
- **15%** Crédits portefeuille
- **15%** Transferts
- **10%** Retraits

### **Métriques Surveillées**
```javascript
// Métriques personnalisées K6
const loginSuccessRate = new Rate('login_success_rate');
const transactionDuration = new Trend('transaction_duration');
const errorCount = new Counter('error_count');
```

### **Exécution des Tests**
```bash
# Test complet automatisé
chmod +x tests/scripts/run-all-tests.sh
./tests/scripts/run-all-tests.sh

# Tests de performance uniquement
k6 run --duration 10m tests/performance/auth-load-test.js
k6 run --duration 10m tests/performance/wallet-load-test.js

# Avec métriques InfluxDB
k6 run --out influxdb=http://localhost:8086/k6 auth-load-test.js
```

## 📊 Métriques et KPIs

### **Métriques Techniques**
```prometheus
# Kong API Gateway
kong_http_requests_total
kong_latency_bucket
kong_upstream_health

# Services ISMAIL
http_requests_total{service="auth-service"}
http_request_duration_seconds{service="wallet-service"}
jvm_memory_used_bytes

# Infrastructure
node_cpu_seconds_total
node_memory_MemAvailable_bytes
kube_pod_status_ready
```

### **Métriques Business**
```prometheus
# Authentification
auth_login_attempts_total{status="success|failed"}
auth_active_sessions_total
kyc_verifications_total{status="pending|verified|rejected"}

# Portefeuille
wallet_transactions_total{type="credit|debit|transfer"}
wallet_total_balance_fcfa
wallet_commissions_paid_total

# Utilisation
ismail_active_users_daily
ismail_transaction_volume_fcfa
ismail_revenue_generated_fcfa
```

### **SLIs/SLOs Définis**
```yaml
# Service Level Indicators/Objectives
Availability: 99.9% (8.76h downtime/year)
Latency: P95 < 2s, P99 < 5s
Error Rate: < 0.1% for critical paths
Throughput: 1000+ req/s peak capacity
```

## 🔧 Configuration et Maintenance

### **Rétention des Données**
- **Prometheus** : 30 jours (métriques haute résolution)
- **Grafana** : Dashboards versionnés
- **Logs** : 90 jours (applications), 1 an (audit)
- **Alertes** : Historique 6 mois

### **Backup et Restauration**
```bash
# Backup Prometheus
kubectl exec -n ismail-monitoring prometheus-0 -- \
  tar czf /tmp/prometheus-backup.tar.gz /prometheus

# Backup Grafana
kubectl exec -n ismail-monitoring grafana-0 -- \
  sqlite3 /var/lib/grafana/grafana.db ".backup /tmp/grafana-backup.db"
```

### **Mise à Jour**
```bash
# Mise à jour Prometheus
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace ismail-monitoring \
  --values infrastructure/monitoring/prometheus/values.yaml

# Mise à jour Grafana
helm upgrade grafana grafana/grafana \
  --namespace ismail-monitoring \
  --values infrastructure/monitoring/grafana/values.yaml
```

## 🎯 Bonnes Pratiques

### **Monitoring**
1. **Métriques RED** : Rate, Errors, Duration pour chaque service
2. **Métriques USE** : Utilization, Saturation, Errors pour l'infrastructure
3. **Alertes actionnables** : Chaque alerte doit avoir une action claire
4. **Dashboards par audience** : Ops, Dev, Business séparés

### **Tests**
1. **Pyramid de tests** : Beaucoup d'unitaires, moins d'intégration, peu d'E2E
2. **Tests en parallèle** : Isolation avec Testcontainers
3. **Données réalistes** : Volumes et patterns proches de la production
4. **CI/CD intégré** : Tests automatiques à chaque commit

### **Performance**
1. **Baseline établie** : Mesures de référence documentées
2. **Tests réguliers** : Performance testing en continu
3. **Seuils adaptatifs** : Ajustement selon la croissance
4. **Optimisation continue** : Amélioration basée sur les métriques

---

**🎉 Stack de monitoring et tests complète déployée !**

*Observabilité totale et qualité assurée pour la plateforme ISMAIL.*
