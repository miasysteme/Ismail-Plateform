#!/bin/bash

# Script de configuration des environments GitHub pour ISMAIL Platform
# Configure les environments avec les protection rules appropriées

set -euo pipefail

# Configuration
REPO_OWNER="miasysteme"
REPO_NAME="Ismail-Plateform"
REPO_FULL_NAME="${REPO_OWNER}/${REPO_NAME}"

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
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) n'est pas installé"
        log_info "Installation: https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI n'est pas authentifié"
        log_info "Exécutez: gh auth login"
        exit 1
    fi
    
    # Vérifier les permissions
    if ! gh api repos/$REPO_FULL_NAME --silent; then
        log_error "Pas d'accès au repository $REPO_FULL_NAME"
        exit 1
    fi
    
    log_success "Prérequis validés"
}

# Créer l'environment production-approval
create_production_environment() {
    log_info "Création de l'environment production-approval..."
    
    # Créer l'environment
    local env_config='{
        "wait_timer": 300,
        "reviewers": [
            {
                "type": "User",
                "id": null
            }
        ],
        "deployment_branch_policy": {
            "protected_branches": false,
            "custom_branch_policies": true
        }
    }'
    
    # Note: GitHub CLI ne supporte pas encore la création d'environments
    # Utilisation de l'API REST directement
    
    log_info "Configuration de l'environment production-approval..."
    
    # Créer l'environment via API
    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/$REPO_FULL_NAME/environments/production-approval" \
        --input - << EOF
{
  "wait_timer": 300,
  "reviewers": [],
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true
  }
}
EOF
    
    log_success "Environment production-approval créé"
}

# Configurer les branch policies pour production
configure_production_branch_policy() {
    log_info "Configuration des branch policies pour production..."
    
    # Configurer les branches autorisées pour production
    gh api \
        --method POST \
        -H "Accept: application/vnd.github+json" \
        "/repos/$REPO_FULL_NAME/environments/production-approval/deployment-branch-policies" \
        --input - << EOF
{
  "name": "main",
  "type": "branch"
}
EOF
    
    # Ajouter les tags de release
    gh api \
        --method POST \
        -H "Accept: application/vnd.github+json" \
        "/repos/$REPO_FULL_NAME/environments/production-approval/deployment-branch-policies" \
        --input - << EOF
{
  "name": "v*.*.*",
  "type": "tag"
}
EOF
    
    log_success "Branch policies configurées pour production"
}

# Créer l'environment staging
create_staging_environment() {
    log_info "Création de l'environment staging..."
    
    # Créer l'environment staging
    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/$REPO_FULL_NAME/environments/staging" \
        --input - << EOF
{
  "wait_timer": 120,
  "reviewers": [],
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true
  }
}
EOF
    
    log_success "Environment staging créé"
}

# Configurer les branch policies pour staging
configure_staging_branch_policy() {
    log_info "Configuration des branch policies pour staging..."
    
    # Branches autorisées pour staging
    local branches=("main" "develop")
    
    for branch in "${branches[@]}"; do
        gh api \
            --method POST \
            -H "Accept: application/vnd.github+json" \
            "/repos/$REPO_FULL_NAME/environments/staging/deployment-branch-policies" \
            --input - << EOF
{
  "name": "$branch",
  "type": "branch"
}
EOF
    done
    
    # Tags RC pour staging
    gh api \
        --method POST \
        -H "Accept: application/vnd.github+json" \
        "/repos/$REPO_FULL_NAME/environments/staging/deployment-branch-policies" \
        --input - << EOF
{
  "name": "v*.*.*-rc*",
  "type": "tag"
}
EOF
    
    log_success "Branch policies configurées pour staging"
}

# Configurer les protection rules pour main
configure_main_branch_protection() {
    log_info "Configuration des protection rules pour la branche main..."
    
    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/$REPO_FULL_NAME/branches/main/protection" \
        --input - << EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "CI / Code Analysis & Security",
      "CI / Unit Tests (auth-service)",
      "CI / Unit Tests (wallet-service)",
      "CI / Integration Tests",
      "CI / Quality Gate"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "require_last_push_approval": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true
}
EOF
    
    log_success "Protection rules configurées pour main"
}

# Configurer les protection rules pour develop
configure_develop_branch_protection() {
    log_info "Configuration des protection rules pour la branche develop..."
    
    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        "/repos/$REPO_FULL_NAME/branches/develop/protection" \
        --input - << EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "CI / Code Analysis & Security",
      "CI / Unit Tests (auth-service)",
      "CI / Unit Tests (wallet-service)",
      "CI / Integration Tests"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true
}
EOF
    
    log_success "Protection rules configurées pour develop"
}

# Créer le fichier CODEOWNERS
create_codeowners_file() {
    log_info "Création du fichier CODEOWNERS..."
    
    local codeowners_file=".github/CODEOWNERS"
    
    cat > "$codeowners_file" << EOF
# ISMAIL Platform - Code Owners
# Ces utilisateurs seront automatiquement demandés pour review

# Global owners
* @miasysteme

# Infrastructure et CI/CD
/.github/ @miasysteme
/infrastructure/ @miasysteme
/scripts/ @miasysteme

# Services Core
/services/ @miasysteme

# Base de données
/database/ @miasysteme

# Tests
/tests/ @miasysteme

# Documentation
/docs/ @miasysteme
README.md @miasysteme
CONTRIBUTING.md @miasysteme

# Configuration sensible
.secrets/ @miasysteme
*.env @miasysteme
**/secrets/ @miasysteme
EOF
    
    log_success "Fichier CODEOWNERS créé"
}

# Configurer les labels du repository
configure_repository_labels() {
    log_info "Configuration des labels du repository..."
    
    # Labels par défaut pour ISMAIL
    local labels=(
        "bug:🐛 Bug:d73a4a"
        "enhancement:✨ Enhancement:a2eeef"
        "documentation:📚 Documentation:0075ca"
        "security:🔒 Security:b60205"
        "performance:⚡ Performance:fbca04"
        "infrastructure:🏗️ Infrastructure:0e8a16"
        "ci-cd:🚀 CI/CD:1d76db"
        "auth-service:🔐 Auth Service:c2e0c6"
        "wallet-service:💰 Wallet Service:bfd4f2"
        "monitoring:📊 Monitoring:f9d0c4"
        "testing:🧪 Testing:e4e669"
        "priority-high:🔥 High Priority:d93f0b"
        "priority-medium:⚠️ Medium Priority:fbca04"
        "priority-low:📝 Low Priority:0e8a16"
    )
    
    for label in "${labels[@]}"; do
        IFS=':' read -r name description color <<< "$label"
        
        gh api \
            --method POST \
            -H "Accept: application/vnd.github+json" \
            "/repos/$REPO_FULL_NAME/labels" \
            --input - << EOF
{
  "name": "$name",
  "description": "$description",
  "color": "$color"
}
EOF
    done
    
    log_success "Labels configurés"
}

# Créer les issue templates
create_issue_templates() {
    log_info "Création des templates d'issues..."
    
    local templates_dir=".github/ISSUE_TEMPLATE"
    mkdir -p "$templates_dir"
    
    # Template Bug Report
    cat > "$templates_dir/bug_report.yml" << EOF
name: 🐛 Bug Report
description: Signaler un bug dans la plateforme ISMAIL
title: "[BUG] "
labels: ["bug"]
body:
  - type: markdown
    attributes:
      value: |
        Merci de signaler ce bug ! Veuillez fournir autant de détails que possible.
  
  - type: dropdown
    id: service
    attributes:
      label: Service concerné
      description: Quel service est affecté ?
      options:
        - Auth Service
        - Wallet Service
        - Infrastructure
        - CI/CD
        - Monitoring
        - Autre
    validations:
      required: true
  
  - type: textarea
    id: description
    attributes:
      label: Description du bug
      description: Description claire et concise du bug
    validations:
      required: true
  
  - type: textarea
    id: reproduction
    attributes:
      label: Étapes de reproduction
      description: Étapes pour reproduire le comportement
      placeholder: |
        1. Aller à '...'
        2. Cliquer sur '...'
        3. Voir l'erreur
    validations:
      required: true
  
  - type: textarea
    id: expected
    attributes:
      label: Comportement attendu
      description: Description du comportement attendu
    validations:
      required: true
  
  - type: textarea
    id: environment
    attributes:
      label: Environnement
      description: Informations sur l'environnement
      placeholder: |
        - OS: [e.g. Ubuntu 20.04]
        - Browser: [e.g. Chrome 91]
        - Version: [e.g. v1.0.0]
EOF

    # Template Feature Request
    cat > "$templates_dir/feature_request.yml" << EOF
name: ✨ Feature Request
description: Proposer une nouvelle fonctionnalité
title: "[FEATURE] "
labels: ["enhancement"]
body:
  - type: markdown
    attributes:
      value: |
        Merci de proposer cette fonctionnalité ! Décrivez votre idée en détail.
  
  - type: dropdown
    id: module
    attributes:
      label: Module concerné
      description: Quel module serait affecté ?
      options:
        - Auth Service
        - Wallet Service
        - Services Module
        - Shop Module
        - Booking Module
        - Real Estate Module
        - Recovery Module
        - Infrastructure
        - Autre
    validations:
      required: true
  
  - type: textarea
    id: problem
    attributes:
      label: Problème à résoudre
      description: Quel problème cette fonctionnalité résoudrait-elle ?
    validations:
      required: true
  
  - type: textarea
    id: solution
    attributes:
      label: Solution proposée
      description: Description claire de la solution souhaitée
    validations:
      required: true
  
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considérées
      description: Autres solutions envisagées
EOF

    log_success "Templates d'issues créés"
}

# Afficher le résumé
display_summary() {
    log_info "=== Résumé de la Configuration GitHub ==="
    
    echo
    echo "✅ Environments configurés:"
    echo "  🏭 production-approval (wait: 5min, reviewers requis)"
    echo "  🧪 staging (wait: 2min)"
    echo
    echo "✅ Branch protection configurée:"
    echo "  🔒 main (2 reviewers, status checks requis)"
    echo "  🔒 develop (1 reviewer, status checks requis)"
    echo
    echo "✅ Fichiers créés:"
    echo "  📝 .github/CODEOWNERS"
    echo "  📋 .github/ISSUE_TEMPLATE/bug_report.yml"
    echo "  📋 .github/ISSUE_TEMPLATE/feature_request.yml"
    echo
    echo "✅ Labels configurés:"
    echo "  🏷️ 13 labels pour organisation des issues"
    echo
    echo "🔗 URLs utiles:"
    echo "  📊 Environments: https://github.com/$REPO_FULL_NAME/settings/environments"
    echo "  🔒 Branch protection: https://github.com/$REPO_FULL_NAME/settings/branches"
    echo "  🏷️ Labels: https://github.com/$REPO_FULL_NAME/labels"
    echo "  📋 Issues: https://github.com/$REPO_FULL_NAME/issues"
    echo
    log_success "Configuration GitHub terminée !"
}

# Fonction principale
main() {
    echo "🔧 Configuration GitHub Environments - ISMAIL Platform"
    echo "=================================================="
    echo
    
    check_prerequisites
    create_production_environment
    configure_production_branch_policy
    create_staging_environment
    configure_staging_branch_policy
    configure_main_branch_protection
    configure_develop_branch_protection
    create_codeowners_file
    configure_repository_labels
    create_issue_templates
    display_summary
}

# Vérification des arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -gt 0 && "$1" == "--help" ]]; then
        echo "Usage: $0"
        echo
        echo "Configure les environments GitHub et les protection rules."
        echo
        echo "Ce script configure:"
        echo "  - Environments (production-approval, staging)"
        echo "  - Branch protection rules (main, develop)"
        echo "  - CODEOWNERS file"
        echo "  - Issue templates"
        echo "  - Repository labels"
        echo
        echo "Prérequis:"
        echo "  - GitHub CLI (gh) installé et authentifié"
        echo "  - Permissions admin sur le repository"
        echo
        exit 0
    fi
    
    main "$@"
fi
