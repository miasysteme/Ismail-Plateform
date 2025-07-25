#!/bin/bash

# Script de génération des secrets sécurisés pour ISMAIL Platform
# Génère tous les secrets requis avec des standards de sécurité élevés

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="${SCRIPT_DIR}/../.secrets/generated-secrets.env"
GITHUB_SECRETS_FILE="${SCRIPT_DIR}/../.secrets/github-secrets.json"

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
    
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL n'est pas installé"
        exit 1
    fi
    
    if ! command -v base64 &> /dev/null; then
        log_error "base64 n'est pas installé"
        exit 1
    fi
    
    log_success "Prérequis validés"
}

# Créer le répertoire des secrets
create_secrets_directory() {
    local secrets_dir="${SCRIPT_DIR}/../.secrets"
    
    if [ ! -d "$secrets_dir" ]; then
        mkdir -p "$secrets_dir"
        chmod 700 "$secrets_dir"
        log_info "Répertoire secrets créé: $secrets_dir"
    fi
    
    # Ajouter au .gitignore si pas déjà présent
    local gitignore_file="${SCRIPT_DIR}/../.gitignore"
    if ! grep -q "\.secrets/" "$gitignore_file" 2>/dev/null; then
        echo "" >> "$gitignore_file"
        echo "# Secrets générés (JAMAIS commiter)" >> "$gitignore_file"
        echo ".secrets/" >> "$gitignore_file"
        log_info "Ajouté .secrets/ au .gitignore"
    fi
}

# Générer un mot de passe sécurisé
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Générer une clé JWT
generate_jwt_secret() {
    openssl rand -base64 64 | tr -d "\n"
}

# Générer un UUID
generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen
    else
        openssl rand -hex 16 | sed 's/\(..\)/\1-/g; s/.$//' | sed 's/\(.\{8\}\)-\(.\{4\}\)-\(.\{4\}\)-\(.\{4\}\)-\(.\{12\}\)/\1-\2-\3-\4-\5/'
    fi
}

# Générer tous les secrets
generate_all_secrets() {
    log_info "Génération des secrets sécurisés..."
    
    # Créer le fichier de secrets
    cat > "$SECRETS_FILE" << EOF
# ISMAIL Platform - Secrets Générés
# Généré le: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# ATTENTION: Ne jamais commiter ce fichier !

# ==============================================
# BASE DE DONNÉES
# ==============================================

# Développement
DEV_DB_HOST=dev-db.ismail-platform.com
DEV_DB_USERNAME=ismail_dev
DEV_DB_PASSWORD=$(generate_password 32)

# Production
PROD_DB_HOST=prod-db.ismail-platform.com
PROD_DB_USERNAME=ismail_prod
PROD_DB_PASSWORD=$(generate_password 48)

# ==============================================
# REDIS
# ==============================================

# Développement
DEV_REDIS_HOST=dev-redis.ismail-platform.com
DEV_REDIS_PASSWORD=$(generate_password 32)

# Production
PROD_REDIS_HOST=prod-redis.ismail-platform.com
PROD_REDIS_PASSWORD=$(generate_password 48)

# ==============================================
# JWT SECRETS
# ==============================================

# Développement
DEV_JWT_SECRET=$(generate_jwt_secret)

# Production
PROD_JWT_SECRET=$(generate_jwt_secret)

# ==============================================
# SERVICES EXTERNES
# ==============================================

# SendGrid (à remplacer par votre vraie clé)
SENDGRID_API_KEY=SG.REPLACE_WITH_YOUR_SENDGRID_KEY

# Slack Webhook (à remplacer par votre vraie URL)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/REPLACE/WITH/YOUR_WEBHOOK

# ==============================================
# SONARQUBE
# ==============================================

# SonarQube (à remplacer par votre token)
SONAR_TOKEN=REPLACE_WITH_YOUR_SONAR_TOKEN
SONAR_HOST_URL=https://sonarcloud.io

# ==============================================
# URLs ENVIRONNEMENTS
# ==============================================

# Développement
DEV_BASE_URL=https://dev.ismail-platform.com

# Staging
STAGING_BASE_URL=https://staging.ismail-platform.com

# Production
PROD_BASE_URL=https://ismail-platform.com
PROD_GRAFANA_URL=https://grafana.ismail-platform.com
PROD_PROMETHEUS_URL=https://prometheus.ismail-platform.com

# ==============================================
# NOTIFICATIONS
# ==============================================

# Emails de notification production
PRODUCTION_NOTIFICATION_EMAILS=ops@ismail-platform.com,cto@ismail-platform.com

# ==============================================
# BACKUP
# ==============================================

# Bucket S3 pour backups
BACKUP_BUCKET=ismail-backups-prod

# ==============================================
# AWS (à remplacer par vos vraies clés)
# ==============================================

AWS_ACCESS_KEY_ID=REPLACE_WITH_YOUR_AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=REPLACE_WITH_YOUR_AWS_SECRET_KEY

# ==============================================
# IDENTIFIANTS UNIQUES
# ==============================================

# UUID pour cette instance
INSTANCE_UUID=$(generate_uuid)

# Clé de chiffrement interne
INTERNAL_ENCRYPTION_KEY=$(generate_password 64)

EOF

    chmod 600 "$SECRETS_FILE"
    log_success "Secrets générés dans: $SECRETS_FILE"
}

# Générer le fichier JSON pour GitHub CLI
generate_github_secrets_json() {
    log_info "Génération du fichier JSON pour GitHub CLI..."
    
    # Source les secrets générés
    source "$SECRETS_FILE"
    
    cat > "$GITHUB_SECRETS_FILE" << EOF
{
  "repository_secrets": {
    "DEV_DB_HOST": "$DEV_DB_HOST",
    "DEV_DB_USERNAME": "$DEV_DB_USERNAME",
    "DEV_DB_PASSWORD": "$DEV_DB_PASSWORD",
    "DEV_REDIS_HOST": "$DEV_REDIS_HOST",
    "DEV_REDIS_PASSWORD": "$DEV_REDIS_PASSWORD",
    "DEV_JWT_SECRET": "$DEV_JWT_SECRET",
    "SENDGRID_API_KEY": "$SENDGRID_API_KEY",
    "SLACK_WEBHOOK_URL": "$SLACK_WEBHOOK_URL",
    "SONAR_TOKEN": "$SONAR_TOKEN",
    "SONAR_HOST_URL": "$SONAR_HOST_URL",
    "DEV_BASE_URL": "$DEV_BASE_URL",
    "STAGING_BASE_URL": "$STAGING_BASE_URL",
    "AWS_ACCESS_KEY_ID": "$AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY": "$AWS_SECRET_ACCESS_KEY",
    "INTERNAL_ENCRYPTION_KEY": "$INTERNAL_ENCRYPTION_KEY"
  },
  "environment_secrets": {
    "production-approval": {
      "PROD_DB_HOST": "$PROD_DB_HOST",
      "PROD_DB_USERNAME": "$PROD_DB_USERNAME",
      "PROD_DB_PASSWORD": "$PROD_DB_PASSWORD",
      "PROD_REDIS_HOST": "$PROD_REDIS_HOST",
      "PROD_REDIS_PASSWORD": "$PROD_REDIS_PASSWORD",
      "PROD_JWT_SECRET": "$PROD_JWT_SECRET",
      "PROD_BASE_URL": "$PROD_BASE_URL",
      "PROD_GRAFANA_URL": "$PROD_GRAFANA_URL",
      "PROD_PROMETHEUS_URL": "$PROD_PROMETHEUS_URL",
      "PRODUCTION_NOTIFICATION_EMAILS": "$PRODUCTION_NOTIFICATION_EMAILS",
      "BACKUP_BUCKET": "$BACKUP_BUCKET"
    }
  }
}
EOF

    chmod 600 "$GITHUB_SECRETS_FILE"
    log_success "Fichier JSON GitHub généré: $GITHUB_SECRETS_FILE"
}

# Générer un script d'upload vers GitHub
generate_upload_script() {
    local upload_script="${SCRIPT_DIR}/../.secrets/upload-to-github.sh"
    
    cat > "$upload_script" << 'EOF'
#!/bin/bash

# Script pour uploader les secrets vers GitHub
# Nécessite GitHub CLI (gh) installé et configuré

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="${SCRIPT_DIR}/generated-secrets.env"
GITHUB_SECRETS_FILE="${SCRIPT_DIR}/github-secrets.json"

# Vérifier GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) n'est pas installé"
    echo "Installation: https://cli.github.com/"
    exit 1
fi

# Vérifier l'authentification
if ! gh auth status &> /dev/null; then
    echo "❌ GitHub CLI n'est pas authentifié"
    echo "Exécutez: gh auth login"
    exit 1
fi

echo "🔐 Upload des secrets vers GitHub..."

# Source les secrets
source "$SECRETS_FILE"

# Repository secrets
echo "📤 Upload des secrets repository..."
gh secret set DEV_DB_HOST --body "$DEV_DB_HOST"
gh secret set DEV_DB_USERNAME --body "$DEV_DB_USERNAME"
gh secret set DEV_DB_PASSWORD --body "$DEV_DB_PASSWORD"
gh secret set DEV_REDIS_HOST --body "$DEV_REDIS_HOST"
gh secret set DEV_REDIS_PASSWORD --body "$DEV_REDIS_PASSWORD"
gh secret set DEV_JWT_SECRET --body "$DEV_JWT_SECRET"
gh secret set DEV_BASE_URL --body "$DEV_BASE_URL"
gh secret set STAGING_BASE_URL --body "$STAGING_BASE_URL"
gh secret set INTERNAL_ENCRYPTION_KEY --body "$INTERNAL_ENCRYPTION_KEY"

# Secrets externes (à configurer manuellement)
echo "⚠️  Configurez manuellement ces secrets:"
echo "   - SENDGRID_API_KEY"
echo "   - SLACK_WEBHOOK_URL"
echo "   - SONAR_TOKEN"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"

# Environment secrets (production)
echo "📤 Upload des secrets environment production..."
gh secret set PROD_DB_HOST --env production-approval --body "$PROD_DB_HOST"
gh secret set PROD_DB_USERNAME --env production-approval --body "$PROD_DB_USERNAME"
gh secret set PROD_DB_PASSWORD --env production-approval --body "$PROD_DB_PASSWORD"
gh secret set PROD_REDIS_HOST --env production-approval --body "$PROD_REDIS_HOST"
gh secret set PROD_REDIS_PASSWORD --env production-approval --body "$PROD_REDIS_PASSWORD"
gh secret set PROD_JWT_SECRET --env production-approval --body "$PROD_JWT_SECRET"
gh secret set PROD_BASE_URL --env production-approval --body "$PROD_BASE_URL"
gh secret set PROD_GRAFANA_URL --env production-approval --body "$PROD_GRAFANA_URL"
gh secret set PROD_PROMETHEUS_URL --env production-approval --body "$PROD_PROMETHEUS_URL"
gh secret set PRODUCTION_NOTIFICATION_EMAILS --env production-approval --body "$PRODUCTION_NOTIFICATION_EMAILS"
gh secret set BACKUP_BUCKET --env production-approval --body "$BACKUP_BUCKET"

echo "✅ Secrets uploadés avec succès !"
echo "🔗 Vérifiez sur: https://github.com/miasysteme/Ismail-Plateform/settings/secrets"
EOF

    chmod +x "$upload_script"
    log_success "Script d'upload généré: $upload_script"
}

# Afficher le résumé
display_summary() {
    log_info "=== Résumé de la Génération des Secrets ==="
    
    echo
    echo "📁 Fichiers générés:"
    echo "  ✅ $SECRETS_FILE"
    echo "  ✅ $GITHUB_SECRETS_FILE"
    echo "  ✅ ${SCRIPT_DIR}/../.secrets/upload-to-github.sh"
    echo
    echo "🔐 Secrets générés:"
    echo "  ✅ Mots de passe base de données (dev/prod)"
    echo "  ✅ Mots de passe Redis (dev/prod)"
    echo "  ✅ Secrets JWT (dev/prod)"
    echo "  ✅ Clé de chiffrement interne"
    echo "  ✅ UUID d'instance"
    echo
    echo "⚠️  À configurer manuellement:"
    echo "  🔑 SENDGRID_API_KEY (clé SendGrid)"
    echo "  🔑 SLACK_WEBHOOK_URL (webhook Slack)"
    echo "  🔑 SONAR_TOKEN (token SonarQube)"
    echo "  🔑 AWS_ACCESS_KEY_ID (clé AWS)"
    echo "  🔑 AWS_SECRET_ACCESS_KEY (secret AWS)"
    echo
    echo "📋 Prochaines étapes:"
    echo "  1. Configurer les secrets externes"
    echo "  2. Exécuter: .secrets/upload-to-github.sh"
    echo "  3. Configurer les environments GitHub"
    echo "  4. Tester la pipeline CI/CD"
    echo
    log_warning "IMPORTANT: Ne jamais commiter le répertoire .secrets/ !"
}

# Fonction principale
main() {
    echo "🔐 Génération des Secrets ISMAIL Platform"
    echo "========================================"
    echo
    
    check_prerequisites
    create_secrets_directory
    generate_all_secrets
    generate_github_secrets_json
    generate_upload_script
    display_summary
}

# Vérification des arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -gt 0 && "$1" == "--help" ]]; then
        echo "Usage: $0"
        echo
        echo "Génère tous les secrets sécurisés requis pour ISMAIL Platform."
        echo
        echo "Ce script génère:"
        echo "  - Mots de passe sécurisés pour bases de données"
        echo "  - Secrets JWT pour authentification"
        echo "  - Clés de chiffrement internes"
        echo "  - Fichiers de configuration pour GitHub"
        echo
        echo "Fichiers générés:"
        echo "  - .secrets/generated-secrets.env"
        echo "  - .secrets/github-secrets.json"
        echo "  - .secrets/upload-to-github.sh"
        echo
        exit 0
    fi
    
    main "$@"
fi
