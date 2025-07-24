
# 🚀 ISMAIL Platform

**Plateforme digitale complète pour l'écosystème CEDEAO**

[![CI/CD Pipeline](https://github.com/miasysteme/Ismail-Plateform/actions/workflows/ci.yml/badge.svg)](https://github.com/miasysteme/Ismail-Plateform/actions/workflows/ci.yml)
[![Security Scan](https://github.com/miasysteme/Ismail-Plateform/actions/workflows/security-scan.yml/badge.svg)](https://github.com/miasysteme/Ismail-Plateform/actions/workflows/security-scan.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=ismail-platform&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=ismail-platform)
[![Coverage](https://codecov.io/gh/miasysteme/Ismail-Plateform/branch/main/graph/badge.svg)](https://codecov.io/gh/miasysteme/Ismail-Plateform)

## 🎯 Vue d'Ensemble

ISMAIL est une plateforme digitale innovante conçue pour révolutionner l'écosystème des services dans la zone CEDEAO. Elle offre une solution complète intégrant authentification biométrique, portefeuille électronique, et modules business avancés.

### ✨ Fonctionnalités Principales

- 🔐 **Authentification Biométrique** - KYC avancé avec reconnaissance faciale et empreintes
- 💰 **Portefeuille Électronique** - Gestion multi-devises avec intégration mobile money
- 🏪 **E-commerce Intégré** - Marketplace complète avec gestion des commandes
- 🏨 **Réservations** - Système de booking pour hôtels et services
- 🏠 **Immobilier** - Plateforme de gestion immobilière
- 📞 **Recouvrement** - Solution de recouvrement de créances
- 🌐 **API Gateway** - Kong pour la gestion centralisée des APIs

## 🏗️ Architecture

### Stack Technologique

```
┌─────────────────────────────────────────────────────────────┐
│                    ISMAIL Platform Stack                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Frontend          │  Backend           │  Infrastructure   │
│  ─────────         │  ───────           │  ──────────────   │
│  • React/Next.js   │  • Java 21         │  • Kubernetes     │
│  • TypeScript      │  • Spring Boot 3   │  • Docker         │
│  • Tailwind CSS    │  • PostgreSQL      │  • Kong Gateway   │
│  • PWA Support     │  • Redis           │  • Prometheus     │
│                    │  • MongoDB         │  • Grafana        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Microservices

- **🔐 Auth Service** - Authentification et gestion des utilisateurs
- **💰 Wallet Service** - Portefeuille électronique et transactions
- **👤 User Service** - Gestion des profils utilisateurs
- **📧 Notification Service** - Notifications multi-canal
- **🏪 Services Module** - Prestataires de services
- **🛒 Shop Module** - E-commerce et marketplace
- **📅 Booking Module** - Réservations et planning
- **🏠 Real Estate Module** - Gestion immobilière
- **📞 Recovery Module** - Recouvrement de créances

## 🚀 Démarrage Rapide

### Prérequis

- **Java 21+**
- **Docker & Docker Compose**
- **Kubernetes** (minikube pour dev local)
- **Maven 3.9+**
- **Node.js 20+**

### Installation Locale

```bash
# 1. Cloner le repository
git clone https://github.com/miasysteme/Ismail-Plateform.git
cd Ismail-Plateform

# 2. Démarrer l'infrastructure locale
docker-compose -f infrastructure/docker/docker-compose.dev.yml up -d

# 3. Construire et démarrer les services
cd services/auth-service
mvn spring-boot:run

cd ../wallet-service
mvn spring-boot:run

# 4. Accéder à l'application
open http://localhost:8080
```

### Déploiement Kubernetes

```bash
# 1. Déployer Kong API Gateway
chmod +x infrastructure/scripts/setup-kong.sh
./infrastructure/scripts/setup-kong.sh dev

# 2. Déployer le monitoring
chmod +x infrastructure/scripts/setup-monitoring.sh
./infrastructure/scripts/setup-monitoring.sh dev

# 3. Déployer les services
kubectl apply -f infrastructure/k8s/services/
```

## 📊 Monitoring et Observabilité

### Dashboards Disponibles

- **🌐 Kong Gateway** - `http://localhost:3000/d/kong`
- **🔐 Auth Service** - `http://localhost:3000/d/auth`
- **💰 Wallet Service** - `http://localhost:3000/d/wallet`
- **📊 Infrastructure** - `http://localhost:3000/d/k8s`

### Métriques Clés

```yaml
SLIs/SLOs:
  Availability: 99.9%
  Latency P95: < 2s
  Error Rate: < 0.1%
  Throughput: 1000+ req/s
```

## 🧪 Tests

### Exécution des Tests

```bash
# Tests unitaires
mvn test

# Tests d'intégration
cd tests/integration
mvn verify

# Tests de performance
cd tests/performance
k6 run auth-load-test.js

# Tests complets
chmod +x tests/scripts/run-all-tests.sh
./tests/scripts/run-all-tests.sh
```

### Couverture de Code

- **Objectif** : >80% de couverture
- **Outil** : JaCoCo
- **Rapports** : `target/site/jacoco/index.html`

## 🔒 Sécurité

### Fonctionnalités de Sécurité

- **🔐 JWT Tokens** avec refresh automatique
- **🛡️ Rate Limiting** par utilisateur et endpoint
- **🔍 KYC Biométrique** avec seuils de confiance
- **🚨 Détection de Fraude** en temps réel
- **📊 Audit Complet** conforme RGPD

### Scans de Sécurité

- **CodeQL** - Analyse statique du code
- **Trivy** - Scan des vulnérabilités containers
- **Dependency Check** - Vulnérabilités des dépendances
- **Secret Scanning** - Détection de secrets

## 🚀 CI/CD

### Pipeline GitHub Actions

```yaml
Stages:
  1. 🔍 Code Analysis & Security
  2. 🧪 Unit & Integration Tests
  3. 🎯 Quality Gates (SonarQube)
  4. 🐳 Docker Build & Push
  5. ⚡ Performance Tests
  6. 🚀 Deploy (Dev/Staging/Prod)
```

### Stratégies de Déploiement

- **Development** : Rolling update automatique
- **Staging** : Blue-green avec validation
- **Production** : Blue-green avec approbation manuelle

## 📚 Documentation

### Guides Disponibles

- **🏗️ [Architecture](docs/architecture.md)** - Vue d'ensemble technique
- **🚀 [Déploiement](infrastructure/README.md)** - Guide de déploiement
- **📊 [Monitoring](monitoring/README.md)** - Observabilité et alertes
- **🔄 [CI/CD](ci-cd/README.md)** - Pipeline et automatisation
- **🧪 [Tests](tests/README.md)** - Stratégie de tests
- **🔒 [Sécurité](docs/security.md)** - Bonnes pratiques sécurité

### API Documentation

- **🔐 Auth API** - `http://localhost:8080/api/auth/swagger-ui.html`
- **💰 Wallet API** - `http://localhost:8080/api/wallet/swagger-ui.html`
- **📊 Kong Admin** - `http://localhost:8001`

## 🤝 Contribution

### Workflow de Développement

1. **Fork** le repository
2. **Créer** une branche feature (`git checkout -b feature/amazing-feature`)
3. **Commit** les changes (`git commit -m 'feat: add amazing feature'`)
4. **Push** vers la branche (`git push origin feature/amazing-feature`)
5. **Ouvrir** une Pull Request

### Standards de Code

- **Java** : Google Java Style Guide
- **Commits** : Conventional Commits
- **Tests** : Minimum 80% de couverture
- **Documentation** : Javadoc pour toutes les APIs publiques

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👥 Équipe

- **🏗️ Architecture** - Équipe Platform
- **🔐 Sécurité** - Équipe Security
- **📊 DevOps** - Équipe Infrastructure
- **💼 Business** - Équipe Product

## 📞 Support

- **📧 Email** : support@ismail-platform.com
- **💬 Slack** : [#ismail-support](https://ismail-workspace.slack.com)
- **📖 Wiki** : [Documentation complète](https://wiki.ismail-platform.com)
- **🐛 Issues** : [GitHub Issues](https://github.com/miasysteme/Ismail-Plateform/issues)

---

**🚀 Développé avec ❤️ pour l'écosystème CEDEAO**

*Plateforme ISMAIL - Révolutionner les services digitaux en Afrique de l'Ouest*
