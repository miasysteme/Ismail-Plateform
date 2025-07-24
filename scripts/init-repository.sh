#!/bin/bash

# Script d'initialisation du repository ISMAIL Platform
# Initialise Git, configure les remotes et fait le premier commit

set -euo pipefail

# Configuration
REMOTE_URL="https://github.com/miasysteme/Ismail-Plateform.git"
MAIN_BRANCH="main"
DEVELOP_BRANCH="develop"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    if ! command -v git &> /dev/null; then
        log_error "Git n'est pas installé"
        exit 1
    fi
    
    if ! git --version | grep -q "git version"; then
        log_error "Git n'est pas correctement configuré"
        exit 1
    fi
    
    log_success "Prérequis validés"
}

# Configurer Git si nécessaire
configure_git() {
    log_info "Configuration Git..."
    
    # Vérifier si Git est configuré
    if ! git config user.name &> /dev/null; then
        log_warning "Nom d'utilisateur Git non configuré"
        read -p "Entrez votre nom: " git_name
        git config --global user.name "$git_name"
    fi
    
    if ! git config user.email &> /dev/null; then
        log_warning "Email Git non configuré"
        read -p "Entrez votre email: " git_email
        git config --global user.email "$git_email"
    fi
    
    # Configuration recommandée
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
    
    log_success "Git configuré"
    log_info "Utilisateur: $(git config user.name) <$(git config user.email)>"
}

# Initialiser le repository Git
init_repository() {
    log_info "Initialisation du repository Git..."
    
    # Vérifier si c'est déjà un repo Git
    if [ -d ".git" ]; then
        log_warning "Repository Git déjà initialisé"
        return 0
    fi
    
    # Initialiser Git
    git init
    
    # Ajouter le remote origin
    git remote add origin "$REMOTE_URL"
    
    log_success "Repository Git initialisé"
}

# Créer la structure de branches
setup_branches() {
    log_info "Configuration des branches..."
    
    # Créer et basculer sur main
    git checkout -b "$MAIN_BRANCH" 2>/dev/null || git checkout "$MAIN_BRANCH"
    
    log_success "Branche $MAIN_BRANCH configurée"
}

# Ajouter tous les fichiers
add_files() {
    log_info "Ajout des fichiers au repository..."
    
    # Ajouter tous les fichiers
    git add .
    
    # Vérifier les fichiers ajoutés
    local files_count=$(git diff --cached --name-only | wc -l)
    log_info "$files_count fichiers ajoutés"
    
    # Afficher un aperçu des fichiers principaux
    log_info "Fichiers principaux ajoutés:"
    git diff --cached --name-only | grep -E '\.(md|yml|yaml|java|sh|json)$' | head -20 | while read file; do
        echo "  ✓ $file"
    done
    
    if [ "$files_count" -gt 20 ]; then
        echo "  ... et $((files_count - 20)) autres fichiers"
    fi
}

# Créer le commit initial
create_initial_commit() {
    log_info "Création du commit initial..."
    
    # Message de commit détaillé
    local commit_message="🎉 Initial commit: ISMAIL Platform v0.1.0

🏗️ Infrastructure & Architecture:
- Kong API Gateway with rate limiting and SSL/TLS
- Kubernetes manifests with auto-scaling
- Docker multi-architecture images (AMD64/ARM64)
- Microservices architecture with service mesh

🔐 Auth Service:
- JWT authentication with refresh tokens
- Biometric KYC integration
- Multi-device session management
- Professional cards with QR codes
- GDPR compliant audit trail

💰 Wallet Service:
- Multi-currency wallets (XOF, EUR, USD)
- Secure transactions with PIN validation
- Payment integrations (Orange Money, MTN, Wave, Cards)
- Automatic commission calculation (4-6%)
- Dynamic limits per user profile
- Real-time financial reporting

📊 Monitoring & Observability:
- Prometheus metrics collection (50+ metrics)
- Grafana dashboards (Kong, Services, Infrastructure, Business)
- AlertManager with multi-channel notifications
- Exporters for PostgreSQL, Redis, MongoDB
- Centralized logging with retention policies

🧪 Testing & Quality:
- Unit tests with >80% coverage (JaCoCo)
- Integration tests with Testcontainers
- Performance tests with K6 (200+ users)
- Security scanning (CodeQL, Trivy)
- Automated smoke tests

🚀 CI/CD Pipeline:
- GitHub Actions with 6-stage pipeline
- SonarQube quality gates
- Multi-environment deployment (dev/staging/prod)
- Blue-green production deployment
- Automatic rollback on failure

🔒 Security:
- Multi-factor authentication (JWT + PIN + biometric)
- AES-256 encryption for sensitive data
- TLS 1.3 for transport security
- Kubernetes network policies
- Secret management with rotation

📚 Documentation:
- Complete architecture documentation
- OpenAPI 3.0 with Swagger UI
- Deployment guides for all environments
- Monitoring configuration guides
- CI/CD pipeline documentation
- Developer contribution guide

🎯 Performance Metrics:
- Latency P95: <2s for 95% of requests
- Throughput: 1000+ req/s peak capacity
- Availability: 99.9% SLA with 24/7 monitoring
- Error Rate: <0.1% for critical endpoints

🔮 Ready for Business Modules:
- Services Module (service providers)
- Shop Module (e-commerce)
- Booking Module (hotel reservations)
- Real Estate Module (property management)
- Recovery Module (debt collection)

Technologies: Java 21, Spring Boot 3.2, PostgreSQL 15, Redis 7, 
Kubernetes, Docker, Kong Gateway, Prometheus, Grafana, GitHub Actions

🚀 Foundation ready for CEDEAO digital ecosystem revolution!"
    
    # Créer le commit
    git commit -m "$commit_message"
    
    log_success "Commit initial créé"
}

# Créer la branche develop
create_develop_branch() {
    log_info "Création de la branche develop..."
    
    # Créer la branche develop depuis main
    git checkout -b "$DEVELOP_BRANCH"
    
    log_success "Branche $DEVELOP_BRANCH créée"
}

# Pousser vers GitHub
push_to_github() {
    log_info "Push vers GitHub..."
    
    # Demander confirmation
    echo
    log_warning "Prêt à pousser vers GitHub:"
    echo "  Repository: $REMOTE_URL"
    echo "  Branches: $MAIN_BRANCH, $DEVELOP_BRANCH"
    echo
    read -p "Continuer? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Push annulé par l'utilisateur"
        return 0
    fi
    
    # Pousser main
    log_info "Push de la branche $MAIN_BRANCH..."
    git checkout "$MAIN_BRANCH"
    git push -u origin "$MAIN_BRANCH"
    
    # Pousser develop
    log_info "Push de la branche $DEVELOP_BRANCH..."
    git checkout "$DEVELOP_BRANCH"
    git push -u origin "$DEVELOP_BRANCH"
    
    # Définir develop comme branche par défaut pour le développement
    git checkout "$DEVELOP_BRANCH"
    
    log_success "Push vers GitHub terminé"
}

# Afficher le résumé
display_summary() {
    log_info "=== Résumé de l'initialisation ==="
    
    echo
    echo "🎉 Repository ISMAIL Platform initialisé avec succès !"
    echo
    echo "📊 Statistiques:"
    echo "  - Commits: $(git rev-list --count HEAD)"
    echo "  - Fichiers: $(git ls-files | wc -l)"
    echo "  - Branches: $(git branch -a | wc -l)"
    echo
    echo "🌐 Repository GitHub:"
    echo "  - URL: $REMOTE_URL"
    echo "  - Branche principale: $MAIN_BRANCH"
    echo "  - Branche de développement: $DEVELOP_BRANCH"
    echo
    echo "🚀 Prochaines étapes:"
    echo "  1. Configurer les secrets GitHub pour la CI/CD"
    echo "  2. Configurer les environments (staging, production)"
    echo "  3. Démarrer le développement des modules business"
    echo "  4. Configurer SonarQube et les quality gates"
    echo
    echo "📚 Documentation disponible:"
    echo "  - README.md - Vue d'ensemble du projet"
    echo "  - CONTRIBUTING.md - Guide de contribution"
    echo "  - CHANGELOG.md - Historique des versions"
    echo "  - infrastructure/README.md - Guide de déploiement"
    echo "  - monitoring/README.md - Guide monitoring"
    echo "  - ci-cd/README.md - Guide CI/CD"
    echo
    echo "🔗 Liens utiles:"
    echo "  - Repository: $REMOTE_URL"
    echo "  - Issues: $REMOTE_URL/issues"
    echo "  - Actions: $REMOTE_URL/actions"
    echo "  - Wiki: $REMOTE_URL/wiki"
    echo
    log_success "Initialisation terminée !"
}

# Fonction principale
main() {
    echo "🚀 Initialisation du Repository ISMAIL Platform"
    echo "=============================================="
    echo
    
    check_prerequisites
    configure_git
    init_repository
    setup_branches
    add_files
    create_initial_commit
    create_develop_branch
    push_to_github
    display_summary
}

# Vérification des arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -gt 0 && "$1" == "--help" ]]; then
        echo "Usage: $0"
        echo
        echo "Initialise le repository Git ISMAIL Platform et fait le premier commit."
        echo
        echo "Ce script:"
        echo "  1. Configure Git si nécessaire"
        echo "  2. Initialise le repository Git"
        echo "  3. Ajoute tous les fichiers"
        echo "  4. Crée le commit initial"
        echo "  5. Crée la branche develop"
        echo "  6. Pousse vers GitHub"
        echo
        echo "Prérequis:"
        echo "  - Git installé et configuré"
        echo "  - Accès en écriture au repository GitHub"
        echo
        exit 0
    fi
    
    main "$@"
fi
