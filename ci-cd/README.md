# CI/CD Pipeline ISMAIL - Guide Complet

## 🎯 Vue d'Ensemble

Pipeline CI/CD complète pour la plateforme ISMAIL utilisant **GitHub Actions** avec :

- **CI** : Tests automatiques, analyse de code, sécurité
- **CD** : Déploiement automatique multi-environnements
- **Quality Gates** : SonarQube, couverture de code, sécurité
- **Blue-Green Deployment** : Déploiement sans interruption en production

## 🏗️ Architecture CI/CD

### Pipeline Complète
```
┌─────────────────────────────────────────────────────────────┐
│                    ISMAIL CI/CD Pipeline                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │   Code Push     │ │   CI Pipeline   │ │  CD Pipeline    ││
│  │                 │ │                 │ │                 ││
│  │ • Git Push      │ │ • Code Analysis │ │ • Dev Deploy    ││
│  │ • Pull Request  │ │ • Unit Tests    │ │ • Staging       ││
│  │ • Tag Release   │ │ • Integration   │ │ • Production    ││
│  │ • Manual        │ │ • Security Scan │ │ • Blue-Green    ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
│                                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │  Quality Gates  │ │   Docker Build  │ │   Monitoring    ││
│  │                 │ │                 │ │                 ││
│  │ • SonarQube     │ │ • Multi-arch    │ │ • Health Checks ││
│  │ • Coverage      │ │ • Security Scan │ │ • Smoke Tests   ││
│  │ • Performance   │ │ • Registry Push │ │ • Notifications ││
│  │ • Approval      │ │ • Vulnerability │ │ • Rollback      ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Workflows GitHub Actions

### **1. CI Pipeline** (`.github/workflows/ci.yml`)

#### **Déclencheurs**
```yaml
on:
  push:
    branches: [ main, develop, 'feature/*', 'hotfix/*' ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 2 * * *'  # Scan sécurité quotidien
```

#### **Jobs Principaux**
1. **Code Analysis & Security**
   - CodeQL analysis (Java, JavaScript)
   - Trivy vulnerability scanner
   - SARIF upload pour GitHub Security

2. **Unit Tests**
   - Tests parallèles par service
   - Couverture de code avec JaCoCo
   - Upload vers Codecov

3. **Integration Tests**
   - Testcontainers (PostgreSQL, Redis)
   - Tests end-to-end réalistes
   - Rapports détaillés

4. **Quality Gate**
   - SonarQube analysis
   - Quality gate validation
   - Métriques de qualité

5. **Build Docker Images**
   - Multi-architecture (amd64, arm64)
   - Cache optimisé
   - Push vers GitHub Container Registry

6. **Performance Tests**
   - K6 load testing
   - Métriques de performance
   - Seuils de validation

### **2. CD Development** (`.github/workflows/cd-dev.yml`)

#### **Déclencheurs**
```yaml
on:
  push:
    branches: [ develop ]
  workflow_dispatch:
    inputs:
      force_deploy: boolean
```

#### **Étapes de Déploiement**
1. **Pre-deployment Checks**
   - Validation CI status
   - Génération tags images

2. **Deploy Infrastructure**
   - Kong API Gateway
   - Monitoring stack
   - Secrets management

3. **Deploy Services**
   - Déploiement parallèle
   - Health checks
   - Rollout validation

4. **Post-deployment Tests**
   - Smoke tests
   - Health verification
   - Functional validation

### **3. CD Production** (`.github/workflows/cd-production.yml`)

#### **Déclencheurs**
```yaml
on:
  push:
    tags: [ 'v*.*.*' ]
  workflow_dispatch:
    inputs:
      version: string
      skip_tests: boolean
```

#### **Sécurité Production**
1. **Pre-production Validation**
   - Environment approval required
   - Version format validation
   - Staging validation check

2. **Pre-deployment Backup**
   - Database backup
   - Configuration backup
   - S3 storage

3. **Blue-Green Deployment**
   - Deploy Blue environment
   - Health checks Blue
   - Traffic switch
   - Cleanup Green

4. **Post-deployment Tests**
   - Production smoke tests
   - Load testing
   - Metrics validation

## 🔧 Configuration Requise

### **Secrets GitHub**
```yaml
# AWS Configuration
AWS_ACCESS_KEY_ID: "AKIA..."
AWS_SECRET_ACCESS_KEY: "..."

# Database Credentials
DEV_DB_HOST: "dev-db.ismail.com"
DEV_DB_USERNAME: "ismail_dev"
DEV_DB_PASSWORD: "..."
PROD_DB_HOST: "prod-db.ismail.com"
PROD_DB_USERNAME: "ismail_prod"
PROD_DB_PASSWORD: "..."

# Redis Credentials
DEV_REDIS_HOST: "dev-redis.ismail.com"
DEV_REDIS_PASSWORD: "..."
PROD_REDIS_HOST: "prod-redis.ismail.com"
PROD_REDIS_PASSWORD: "..."

# JWT Secrets
DEV_JWT_SECRET: "dev-jwt-secret-key"
PROD_JWT_SECRET: "prod-jwt-secret-key"

# External Services
SENDGRID_API_KEY: "SG...."
SLACK_WEBHOOK_URL: "https://hooks.slack.com/..."

# Quality Tools
SONAR_TOKEN: "..."
SONAR_HOST_URL: "https://sonarqube.ismail.com"

# URLs
DEV_BASE_URL: "https://dev.ismail-platform.com"
STAGING_BASE_URL: "https://staging.ismail-platform.com"
PROD_BASE_URL: "https://ismail-platform.com"
PROD_GRAFANA_URL: "https://grafana.ismail-platform.com"
PROD_PROMETHEUS_URL: "https://prometheus.ismail-platform.com"

# Notifications
PRODUCTION_NOTIFICATION_EMAILS: "ops@ismail-platform.com,cto@ismail-platform.com"

# Backup
BACKUP_BUCKET: "ismail-backups-prod"
```

### **Environments GitHub**
```yaml
# Environment: production-approval
Protection Rules:
- Required reviewers: 2
- Deployment branches: main, tags
- Wait timer: 5 minutes
- Environment secrets: PROD_*
```

## 🐳 Docker Configuration

### **Multi-stage Dockerfile**
```dockerfile
# services/auth-service/Dockerfile
FROM eclipse-temurin:21-jre-alpine AS runtime

WORKDIR /app
COPY target/auth-service-*.jar app.jar

# Security
RUN addgroup -g 1000 ismail && \
    adduser -D -s /bin/sh -u 1000 -G ismail ismail
USER ismail

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### **Image Tagging Strategy**
```yaml
Tags générés automatiquement:
- develop-{sha}     # Branche develop
- feature-{sha}     # Branches feature
- v1.0.0           # Tags de release
- latest           # Dernière version stable
- develop-latest   # Dernière version develop
```

## 📊 Quality Gates

### **SonarQube Configuration**
```yaml
Quality Gate Conditions:
- Coverage: > 80%
- Duplicated Lines: < 3%
- Maintainability Rating: A
- Reliability Rating: A
- Security Rating: A
- Security Hotspots: 0
- Bugs: 0
- Vulnerabilities: 0
```

### **Performance Thresholds**
```yaml
K6 Performance Tests:
- Response Time P95: < 2s
- Error Rate: < 0.1%
- Throughput: > 100 req/s
- Memory Usage: < 1GB
- CPU Usage: < 70%
```

## 🔒 Sécurité

### **Security Scanning**
1. **CodeQL** : Analyse statique du code
2. **Trivy** : Scan des vulnérabilités containers
3. **Dependency Check** : Vulnérabilités des dépendances
4. **Secret Scanning** : Détection de secrets dans le code

### **Container Security**
```yaml
Security Measures:
- Non-root user (UID 1000)
- Read-only filesystem
- No privileged containers
- Security contexts enforced
- Network policies applied
```

## 🚀 Déploiement

### **Stratégies par Environnement**

#### **Development**
- **Trigger** : Push sur `develop`
- **Strategy** : Rolling update
- **Approval** : Aucune
- **Tests** : Smoke tests

#### **Staging**
- **Trigger** : Tag `v*.*.*-rc*`
- **Strategy** : Blue-green
- **Approval** : Automatique
- **Tests** : Full test suite

#### **Production**
- **Trigger** : Tag `v*.*.*`
- **Strategy** : Blue-green
- **Approval** : Manuelle (2 reviewers)
- **Tests** : Production validation

### **Rollback Strategy**
```bash
# Rollback automatique en cas d'échec
kubectl rollout undo deployment/auth-service -n ismail-prod

# Rollback manuel vers version spécifique
kubectl set image deployment/auth-service \
  auth-service=ghcr.io/ismail-platform/auth-service:v1.0.0 \
  -n ismail-prod
```

## 📈 Monitoring CI/CD

### **Métriques Surveillées**
```yaml
Pipeline Metrics:
- Build success rate
- Deployment frequency
- Lead time for changes
- Mean time to recovery
- Change failure rate

Quality Metrics:
- Test coverage trend
- Code quality score
- Security vulnerabilities
- Performance regression
```

### **Notifications**
```yaml
Slack Channels:
- #ci-cd: Tous les builds
- #deployments: Déploiements uniquement
- #alerts-critical: Échecs critiques

Email Notifications:
- ops@ismail-platform.com: Tous les déploiements
- dev-team@ismail-platform.com: Échecs de build
- management@ismail-platform.com: Déploiements production
```

## 🛠️ Maintenance

### **Mise à Jour des Workflows**
```bash
# Tester les workflows localement avec act
act -j unit-tests
act -j build-images

# Valider la syntaxe
yamllint .github/workflows/
```

### **Nettoyage Automatique**
```yaml
# Nettoyage des images Docker anciennes
Retention Policy:
- Images develop: 7 jours
- Images feature: 3 jours
- Images release: 1 an
- Images latest: Permanent
```

### **Backup et Restauration**
```bash
# Backup des configurations
kubectl get workflows -o yaml > workflows-backup.yaml

# Backup des secrets (chiffrés)
kubectl get secrets -o yaml > secrets-backup.yaml
```

## 🎯 Bonnes Pratiques

### **Development**
1. **Feature Branches** : Toujours créer des branches pour les nouvelles fonctionnalités
2. **Pull Requests** : Code review obligatoire avant merge
3. **Commit Messages** : Format conventionnel (feat, fix, docs, etc.)
4. **Tests** : Écrire les tests avant le code (TDD)

### **CI/CD**
1. **Fail Fast** : Arrêter le pipeline dès la première erreur
2. **Parallel Execution** : Exécuter les jobs en parallèle quand possible
3. **Cache Strategy** : Utiliser le cache pour accélérer les builds
4. **Idempotency** : Les déploiements doivent être idempotents

### **Security**
1. **Least Privilege** : Permissions minimales pour chaque job
2. **Secret Management** : Utiliser GitHub Secrets, jamais en dur
3. **Audit Trail** : Logger toutes les actions importantes
4. **Regular Updates** : Mettre à jour les actions et dépendances

---

**🎉 Pipeline CI/CD complète configurée !**

*Déploiement automatique, sécurisé et scalable pour la plateforme ISMAIL.*
