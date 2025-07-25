#!/bin/bash

# Script de validation de la configuration GitHub pour ISMAIL Platform
# Vérifie que tous les secrets et environments sont correctement configurés

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

# Compteurs
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

# Fonction de test
run_check() {
    local check_name="$1"
    local check_command="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    log_info "Vérification: $check_name"
    
    if eval "$check_command" &> /dev/null; then
        log_success "✓ $check_name"
        return 0
    else
        log_error "✗ $check_name"
        return 1
    fi
}

# Vérifier les prérequis
check_prerequisites() {
    log_info "=== Vérification des Prérequis ==="
    
    run_check "GitHub CLI installé" "command -v gh"
    run_check "GitHub CLI authentifié" "gh auth status"
    run_check "Accès au repository" "gh api repos/$REPO_FULL_NAME --silent"
    
    echo
}

# Vérifier les secrets repository
check_repository_secrets() {
    log_info "=== Vérification des Secrets Repository ==="
    
    local required_secrets=(
        "DEV_DB_HOST"
        "DEV_DB_USERNAME"
        "DEV_DB_PASSWORD"
        "DEV_REDIS_HOST"
        "DEV_REDIS_PASSWORD"
        "DEV_JWT_SECRET"
        "SENDGRID_API_KEY"
        "SLACK_WEBHOOK_URL"
        "SONAR_TOKEN"
        "SONAR_HOST_URL"
        "DEV_BASE_URL"
        "STAGING_BASE_URL"
        "AWS_ACCESS_KEY_ID"
        "AWS_SECRET_ACCESS_KEY"
    )
    
    for secret in "${required_secrets[@]}"; do
        run_check "Secret repository: $secret" "gh api repos/$REPO_FULL_NAME/actions/secrets/$secret --silent"
    done
    
    echo
}

# Vérifier les environments
check_environments() {
    log_info "=== Vérification des Environments ==="
    
    local environments=("production-approval" "staging")
    
    for env in "${environments[@]}"; do
        run_check "Environment: $env" "gh api repos/$REPO_FULL_NAME/environments/$env --silent"
    done
    
    echo
}

# Vérifier les secrets d'environment
check_environment_secrets() {
    log_info "=== Vérification des Secrets Environment ==="
    
    local prod_secrets=(
        "PROD_DB_HOST"
        "PROD_DB_USERNAME"
        "PROD_DB_PASSWORD"
        "PROD_REDIS_HOST"
        "PROD_REDIS_PASSWORD"
        "PROD_JWT_SECRET"
        "PROD_BASE_URL"
        "PROD_GRAFANA_URL"
        "PROD_PROMETHEUS_URL"
        "PRODUCTION_NOTIFICATION_EMAILS"
        "BACKUP_BUCKET"
    )
    
    for secret in "${prod_secrets[@]}"; do
        run_check "Secret production: $secret" "gh api repos/$REPO_FULL_NAME/environments/production-approval/secrets/$secret --silent"
    done
    
    echo
}

# Vérifier les protection rules
check_branch_protection() {
    log_info "=== Vérification des Protection Rules ==="
    
    local branches=("main" "develop")
    
    for branch in "${branches[@]}"; do
        run_check "Protection rule: $branch" "gh api repos/$REPO_FULL_NAME/branches/$branch/protection --silent"
    done
    
    echo
}

# Vérifier les workflows
check_workflows() {
    log_info "=== Vérification des Workflows ==="
    
    local workflows=(
        "ci.yml"
        "cd-dev.yml"
        "cd-production.yml"
        "infrastructure-deploy.yml"
    )
    
    for workflow in "${workflows[@]}"; do
        run_check "Workflow: $workflow" "test -f .github/workflows/$workflow"
    done
    
    echo
}

# Vérifier les fichiers de configuration
check_config_files() {
    log_info "=== Vérification des Fichiers de Configuration ==="
    
    local config_files=(
        ".github/CODEOWNERS"
        ".github/ISSUE_TEMPLATE/bug_report.yml"
        ".github/ISSUE_TEMPLATE/feature_request.yml"
        ".gitignore"
        "README.md"
        "CONTRIBUTING.md"
        "CHANGELOG.md"
        "LICENSE"
    )
    
    for file in "${config_files[@]}"; do
        run_check "Fichier: $file" "test -f $file"
    done
    
    echo
}

# Tester la connectivité des services externes
test_external_services() {
    log_info "=== Test des Services Externes ==="
    
    # Test SonarCloud (si token configuré)
    if gh secret list | grep -q "SONAR_TOKEN"; then
        local sonar_token=$(gh secret list --json name,value | jq -r '.[] | select(.name=="SONAR_TOKEN") | .value' 2>/dev/null || echo "")
        if [ -n "$sonar_token" ]; then
            run_check "Connectivité SonarCloud" "curl -s -f -H 'Authorization: Bearer $sonar_token' https://sonarcloud.io/api/authentication/validate"
        else
            log_warning "Token SonarQube non accessible pour test"
        fi
    else
        log_warning "Secret SONAR_TOKEN non configuré"
    fi
    
    # Test GitHub API
    run_check "API GitHub" "gh api user --silent"
    
    echo
}

# Vérifier la syntaxe des workflows
validate_workflow_syntax() {
    log_info "=== Validation Syntaxe Workflows ==="
    
    local workflows_dir=".github/workflows"
    
    if [ -d "$workflows_dir" ]; then
        for workflow_file in "$workflows_dir"/*.yml "$workflows_dir"/*.yaml; do
            if [ -f "$workflow_file" ]; then
                local workflow_name=$(basename "$workflow_file")
                
                # Validation YAML basique
                if command -v yamllint &> /dev/null; then
                    run_check "Syntaxe YAML: $workflow_name" "yamllint '$workflow_file'"
                else
                    # Validation Python si yamllint pas disponible
                    if command -v python3 &> /dev/null; then
                        run_check "Syntaxe YAML: $workflow_name" "python3 -c 'import yaml; yaml.safe_load(open(\"$workflow_file\"))'"
                    else
                        log_warning "yamllint et python3 non disponibles pour validation YAML"
                    fi
                fi
            fi
        done
    fi
    
    echo
}

# Vérifier les permissions
check_permissions() {
    log_info "=== Vérification des Permissions ==="
    
    # Vérifier les permissions sur le repository
    local repo_perms=$(gh api repos/$REPO_FULL_NAME --jq '.permissions')
    
    if echo "$repo_perms" | jq -e '.admin == true' &> /dev/null; then
        log_success "✓ Permissions admin sur le repository"
    else
        log_error "✗ Permissions admin requises sur le repository"
    fi
    
    # Vérifier les permissions Actions
    run_check "Permissions GitHub Actions" "gh api repos/$REPO_FULL_NAME/actions/permissions --silent"
    
    echo
}

# Générer un rapport détaillé
generate_report() {
    local report_file="github-config-validation-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Rapport de Validation GitHub - ISMAIL Platform

**Date**: $(date -u +%Y-%m-%dT%H:%M:%SZ)  
**Repository**: $REPO_FULL_NAME  
**Validateur**: $(gh api user --jq '.login')

## 📊 Résumé

- **Total des vérifications**: $TOTAL_CHECKS
- **Réussies**: $PASSED_CHECKS
- **Échouées**: $FAILED_CHECKS
- **Taux de réussite**: $(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))%

## 🔍 Détails des Vérifications

### Prérequis
$(if [ $PASSED_CHECKS -gt 0 ]; then echo "✅ GitHub CLI configuré et authentifié"; else echo "❌ Problèmes avec GitHub CLI"; fi)

### Secrets Repository
$(gh secret list --json name | jq -r '.[] | "- " + .name' | head -10)
$(if [ $(gh secret list --json name | jq length) -gt 10 ]; then echo "... et $(( $(gh secret list --json name | jq length) - 10 )) autres"; fi)

### Environments
$(gh api repos/$REPO_FULL_NAME/environments --jq '.environments[] | "- " + .name' 2>/dev/null || echo "Aucun environment configuré")

### Workflows
$(ls .github/workflows/*.yml 2>/dev/null | sed 's|.github/workflows/|- |' || echo "Aucun workflow trouvé")

## 🎯 Recommandations

$(if [ $FAILED_CHECKS -gt 0 ]; then
    echo "### Actions Requises"
    echo "- Corriger les $FAILED_CHECKS vérifications échouées"
    echo "- Consulter les logs détaillés ci-dessus"
    echo "- Relancer la validation après corrections"
else
    echo "### Configuration Complète"
    echo "✅ Toutes les vérifications sont passées avec succès !"
    echo "✅ La CI/CD pipeline est prête à être utilisée"
fi)

## 🔗 Liens Utiles

- [Repository](https://github.com/$REPO_FULL_NAME)
- [Secrets](https://github.com/$REPO_FULL_NAME/settings/secrets)
- [Environments](https://github.com/$REPO_FULL_NAME/settings/environments)
- [Actions](https://github.com/$REPO_FULL_NAME/actions)

---
*Rapport généré automatiquement par validate-github-config.sh*
EOF
    
    log_success "Rapport généré: $report_file"
}

# Afficher le résumé final
display_summary() {
    echo
    log_info "=== Résumé de la Validation ==="
    
    echo
    echo "📊 **Statistiques**:"
    echo "  - Total des vérifications: $TOTAL_CHECKS"
    echo "  - Réussies: $PASSED_CHECKS"
    echo "  - Échouées: $FAILED_CHECKS"
    echo "  - Taux de réussite: $(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))%"
    echo
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        log_success "🎉 Toutes les vérifications sont passées !"
        log_success "✅ La configuration GitHub est complète et opérationnelle"
        echo
        echo "🚀 **Prêt pour**:"
        echo "  ✅ Déclenchement automatique des workflows"
        echo "  ✅ Déploiements avec approbations"
        echo "  ✅ Quality gates automatiques"
        echo "  ✅ Notifications multi-canal"
    else
        log_error "❌ $FAILED_CHECKS vérifications ont échoué"
        echo
        echo "🔧 **Actions requises**:"
        echo "  1. Corriger les problèmes identifiés"
        echo "  2. Consulter la documentation dans docs/"
        echo "  3. Relancer la validation"
        echo "  4. Tester la pipeline CI/CD"
    fi
    
    echo
    echo "📚 **Documentation**:"
    echo "  - docs/github-setup-guide.md"
    echo "  - docs/sonarqube-setup.md"
    echo "  - ci-cd/README.md"
}

# Fonction principale
main() {
    echo "🔍 Validation Configuration GitHub - ISMAIL Platform"
    echo "================================================"
    echo
    
    check_prerequisites
    check_repository_secrets
    check_environments
    check_environment_secrets
    check_branch_protection
    check_workflows
    check_config_files
    test_external_services
    validate_workflow_syntax
    check_permissions
    
    generate_report
    display_summary
    
    # Code de sortie basé sur les résultats
    if [ $FAILED_CHECKS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Vérification des arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -gt 0 && "$1" == "--help" ]]; then
        echo "Usage: $0"
        echo
        echo "Valide la configuration GitHub pour ISMAIL Platform."
        echo
        echo "Ce script vérifie:"
        echo "  - Secrets repository et environment"
        echo "  - Environments et protection rules"
        echo "  - Workflows et fichiers de configuration"
        echo "  - Connectivité services externes"
        echo "  - Syntaxe et permissions"
        echo
        echo "Prérequis:"
        echo "  - GitHub CLI (gh) installé et authentifié"
        echo "  - Permissions admin sur le repository"
        echo
        exit 0
    fi
    
    main "$@"
fi
