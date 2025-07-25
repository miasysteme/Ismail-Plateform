# 🔐 Guide de Configuration GitHub - ISMAIL Platform

Ce guide vous accompagne dans la configuration complète des secrets GitHub et des environments pour la CI/CD pipeline.

## 📋 Table des Matières

1. [Secrets GitHub Requis](#secrets-github-requis)
2. [Configuration des Environments](#configuration-des-environments)
3. [SonarQube Setup](#sonarqube-setup)
4. [Validation de la Configuration](#validation-de-la-configuration)

---

## 🔑 Secrets GitHub Requis

### **Accès au Repository**
Allez sur : `https://github.com/miasysteme/Ismail-Plateform/settings/secrets/actions`

### **1. AWS Configuration**

#### **AWS_ACCESS_KEY_ID**
```
Description: AWS Access Key pour déploiement infrastructure
Valeur: AKIA... (votre access key AWS)
Scope: Repository
```

#### **AWS_SECRET_ACCESS_KEY**
```
Description: AWS Secret Key pour déploiement infrastructure
Valeur: ... (votre secret key AWS)
Scope: Repository
```

### **2. Base de Données - Développement**

#### **DEV_DB_HOST**
```
Description: Host de la base de données développement
Valeur: dev-db.ismail-platform.com
Scope: Repository
```

#### **DEV_DB_USERNAME**
```
Description: Utilisateur base de données développement
Valeur: ismail_dev
Scope: Repository
```

#### **DEV_DB_PASSWORD**
```
Description: Mot de passe base de données développement
Valeur: [Générer un mot de passe fort]
Scope: Repository
```

### **3. Base de Données - Production**

#### **PROD_DB_HOST**
```
Description: Host de la base de données production
Valeur: prod-db.ismail-platform.com
Scope: Environment (production-approval)
```

#### **PROD_DB_USERNAME**
```
Description: Utilisateur base de données production
Valeur: ismail_prod
Scope: Environment (production-approval)
```

#### **PROD_DB_PASSWORD**
```
Description: Mot de passe base de données production
Valeur: [Générer un mot de passe très fort]
Scope: Environment (production-approval)
```

### **4. Redis Configuration**

#### **DEV_REDIS_HOST**
```
Description: Host Redis développement
Valeur: dev-redis.ismail-platform.com
Scope: Repository
```

#### **DEV_REDIS_PASSWORD**
```
Description: Mot de passe Redis développement
Valeur: [Générer un mot de passe fort]
Scope: Repository
```

#### **PROD_REDIS_HOST**
```
Description: Host Redis production
Valeur: prod-redis.ismail-platform.com
Scope: Environment (production-approval)
```

#### **PROD_REDIS_PASSWORD**
```
Description: Mot de passe Redis production
Valeur: [Générer un mot de passe très fort]
Scope: Environment (production-approval)
```

### **5. JWT Secrets**

#### **DEV_JWT_SECRET**
```
Description: Secret JWT pour développement
Valeur: [Générer une clé de 256 bits en base64]
Scope: Repository
```

#### **PROD_JWT_SECRET**
```
Description: Secret JWT pour production
Valeur: [Générer une clé de 256 bits en base64]
Scope: Environment (production-approval)
```

### **6. Services Externes**

#### **SENDGRID_API_KEY**
```
Description: Clé API SendGrid pour emails
Valeur: SG.xxxxx (votre clé SendGrid)
Scope: Repository
```

#### **SLACK_WEBHOOK_URL**
```
Description: Webhook Slack pour notifications
Valeur: https://hooks.slack.com/services/...
Scope: Repository
```

### **7. Quality Tools**

#### **SONAR_TOKEN**
```
Description: Token SonarQube pour quality gates
Valeur: [Token généré depuis SonarQube]
Scope: Repository
```

#### **SONAR_HOST_URL**
```
Description: URL de l'instance SonarQube
Valeur: https://sonarqube.ismail-platform.com
Scope: Repository
```

### **8. URLs des Environnements**

#### **DEV_BASE_URL**
```
Description: URL de base environnement développement
Valeur: https://dev.ismail-platform.com
Scope: Repository
```

#### **STAGING_BASE_URL**
```
Description: URL de base environnement staging
Valeur: https://staging.ismail-platform.com
Scope: Repository
```

#### **PROD_BASE_URL**
```
Description: URL de base environnement production
Valeur: https://ismail-platform.com
Scope: Environment (production-approval)
```

#### **PROD_GRAFANA_URL**
```
Description: URL Grafana production
Valeur: https://grafana.ismail-platform.com
Scope: Environment (production-approval)
```

#### **PROD_PROMETHEUS_URL**
```
Description: URL Prometheus production
Valeur: https://prometheus.ismail-platform.com
Scope: Environment (production-approval)
```

### **9. Notifications Production**

#### **PRODUCTION_NOTIFICATION_EMAILS**
```
Description: Emails pour notifications production
Valeur: ops@ismail-platform.com,cto@ismail-platform.com
Scope: Environment (production-approval)
```

### **10. Backup Configuration**

#### **BACKUP_BUCKET**
```
Description: Bucket S3 pour backups
Valeur: ismail-backups-prod
Scope: Environment (production-approval)
```

---

## 🌍 Configuration des Environments

### **1. Environment: production-approval**

#### **Accès**
Allez sur : `https://github.com/miasysteme/Ismail-Plateform/settings/environments`

#### **Configuration**
```yaml
Environment Name: production-approval
Protection Rules:
  - Required reviewers: 2
  - Prevent self-review: true
  - Dismiss stale reviews: true
  - Require review from CODEOWNERS: true
  - Deployment branches: 
    - Selected branches: main
    - Tags: v*.*.*
  - Wait timer: 5 minutes
  - Environment secrets: PROD_*
```

#### **Reviewers Requis**
- Ajouter les administrateurs du projet
- Minimum 2 reviewers pour production

### **2. Environment: staging**

#### **Configuration**
```yaml
Environment Name: staging
Protection Rules:
  - Required reviewers: 1
  - Deployment branches:
    - Selected branches: main, develop
    - Tags: v*.*.*-rc*
  - Wait timer: 2 minutes
```

---

## 🔍 SonarQube Setup

### **1. Instance SonarQube**

#### **Option A: SonarCloud (Recommandé)**
1. Aller sur https://sonarcloud.io
2. Se connecter avec GitHub
3. Importer le repository `miasysteme/Ismail-Plateform`
4. Générer un token d'analyse

#### **Option B: Instance Self-Hosted**
```bash
# Docker Compose pour SonarQube
version: '3.8'
services:
  sonarqube:
    image: sonarqube:community
    ports:
      - "9000:9000"
    environment:
      - SONAR_JDBC_URL=jdbc:postgresql://db:5432/sonar
      - SONAR_JDBC_USERNAME=sonar
      - SONAR_JDBC_PASSWORD=sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions
  
  db:
    image: postgres:13
    environment:
      - POSTGRES_USER=sonar
      - POSTGRES_PASSWORD=sonar
      - POSTGRES_DB=sonar
    volumes:
      - postgresql_data:/var/lib/postgresql/data

volumes:
  sonarqube_data:
  sonarqube_logs:
  sonarqube_extensions:
  postgresql_data:
```

### **2. Configuration Projets**

#### **Auth Service**
```
Project Key: ismail-auth-service
Project Name: ISMAIL Auth Service
Main Branch: main
```

#### **Wallet Service**
```
Project Key: ismail-wallet-service
Project Name: ISMAIL Wallet Service
Main Branch: main
```

### **3. Quality Gates**

#### **Configuration Recommandée**
```yaml
Quality Gate: ISMAIL Platform
Conditions:
  - Coverage: > 80%
  - Duplicated Lines: < 3%
  - Maintainability Rating: A
  - Reliability Rating: A
  - Security Rating: A
  - Security Hotspots Reviewed: 100%
  - New Bugs: 0
  - New Vulnerabilities: 0
  - New Code Smells: < 5
```

---

## ✅ Validation de la Configuration

### **1. Test des Secrets**

#### **Script de Validation**
```bash
#!/bin/bash
# Tester la connectivité avec les secrets configurés

echo "🔍 Validation des secrets GitHub..."

# Test AWS
aws sts get-caller-identity

# Test Base de données
pg_isready -h $DEV_DB_HOST -U $DEV_DB_USERNAME

# Test Redis
redis-cli -h $DEV_REDIS_HOST ping

# Test SendGrid
curl -X POST https://api.sendgrid.com/v3/mail/send \
  -H "Authorization: Bearer $SENDGRID_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"personalizations":[{"to":[{"email":"test@example.com"}]}],"from":{"email":"test@ismail-platform.com"},"subject":"Test","content":[{"type":"text/plain","value":"Test"}]}'

echo "✅ Validation terminée"
```

### **2. Test Pipeline CI/CD**

#### **Déclencher un Build**
1. Faire un commit sur la branche `develop`
2. Vérifier que la CI pipeline se lance
3. Contrôler les logs pour les erreurs de secrets

#### **Test Déploiement Dev**
1. Push sur `develop` déclenche le déploiement dev
2. Vérifier les health checks
3. Valider les smoke tests

### **3. Test Environment Production**

#### **Simulation Déploiement**
1. Créer un tag `v0.1.1-test`
2. Vérifier que l'approval est demandé
3. Tester le processus d'approbation

---

## 🚨 Sécurité et Bonnes Pratiques

### **Rotation des Secrets**
- **Fréquence**: Tous les 90 jours minimum
- **Procédure**: Rotation automatisée via scripts
- **Audit**: Logs de toutes les utilisations

### **Accès Restreint**
- **Principe du moindre privilège**
- **Secrets par environment**
- **Audit trail complet**

### **Monitoring**
- **Alertes sur échecs d'authentification**
- **Monitoring utilisation des secrets**
- **Détection d'anomalies**

---

**🎯 Configuration complète pour une CI/CD sécurisée !**
