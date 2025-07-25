#!/bin/bash

# Script de génération des secrets pour Stack Cloud Afrique - ISMAIL Platform
# Optimisé pour Netlify, Railway, Supabase et services accessibles en Afrique

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="${SCRIPT_DIR}/../.secrets/africa-secrets.env"
NETLIFY_FILE="${SCRIPT_DIR}/../.secrets/netlify-env.json"
RAILWAY_FILE="${SCRIPT_DIR}/../.secrets/railway-env.json"

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

# Générer une clé API factice
generate_api_key() {
    echo "$(openssl rand -hex 16)"
}

# Générer tous les secrets pour la stack Afrique
generate_africa_secrets() {
    log_info "Génération des secrets pour Stack Cloud Afrique..."
    
    # Créer le fichier de secrets
    cat > "$SECRETS_FILE" << EOF
# ISMAIL Platform - Secrets Stack Cloud Afrique
# Généré le: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# ATTENTION: Ne jamais commiter ce fichier !

# ==============================================
# NETLIFY CONFIGURATION
# ==============================================

# URLs Netlify
NETLIFY_SITE_URL=https://ismail-platform.netlify.app
NETLIFY_DEPLOY_URL=https://deploy-preview-123--ismail-platform.netlify.app
NETLIFY_DEV_URL=https://dev--ismail-platform.netlify.app

# Netlify Build Hook (à configurer manuellement)
NETLIFY_BUILD_HOOK=https://api.netlify.com/build_hooks/REPLACE_WITH_YOUR_HOOK_ID

# ==============================================
# SUPABASE CONFIGURATION
# ==============================================

# URLs Supabase (à remplacer par vos vraies URLs)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=REPLACE_WITH_YOUR_SUPABASE_ANON_KEY
SUPABASE_SERVICE_KEY=REPLACE_WITH_YOUR_SUPABASE_SERVICE_KEY

# Base de données Supabase
DATABASE_URL=postgresql://postgres:$(generate_password 32)@db.your-project-id.supabase.co:5432/postgres

# ==============================================
# RAILWAY CONFIGURATION
# ==============================================

# URLs Railway (à remplacer par vos vraies URLs)
RAILWAY_BACKEND_URL=https://ismail-backend.railway.app
RAILWAY_STAGING_URL=https://ismail-staging.railway.app
RAILWAY_DEV_URL=https://ismail-dev.railway.app

# Railway Database (si utilisé)
RAILWAY_DATABASE_URL=postgresql://postgres:$(generate_password 32)@containers-us-west-1.railway.app:5432/railway

# ==============================================
# UPSTASH REDIS
# ==============================================

# Upstash Redis (à remplacer par vos vraies clés)
UPSTASH_REDIS_REST_URL=https://your-redis-id.upstash.io
UPSTASH_REDIS_REST_TOKEN=REPLACE_WITH_YOUR_UPSTASH_TOKEN
REDIS_URL=redis://default:$(generate_password 32)@your-redis-id.upstash.io:6379

# ==============================================
# JWT SECRETS
# ==============================================

# Développement
DEV_JWT_SECRET=$(generate_jwt_secret)

# Production
PROD_JWT_SECRET=$(generate_jwt_secret)

# Refresh Token Secret
REFRESH_TOKEN_SECRET=$(generate_jwt_secret)

# ==============================================
# SERVICES EXTERNES AFRIQUE
# ==============================================

# Resend (Alternative SendGrid)
RESEND_API_KEY=re_REPLACE_WITH_YOUR_RESEND_KEY

# Discord Webhooks (Alternative Slack)
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/REPLACE/WITH_YOUR_WEBHOOK

# Cloudinary (Stockage images)
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=REPLACE_WITH_YOUR_CLOUDINARY_KEY
CLOUDINARY_API_SECRET=REPLACE_WITH_YOUR_CLOUDINARY_SECRET
CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name

# ==============================================
# MONITORING ET LOGS
# ==============================================

# Better Stack (Logs et monitoring)
BETTER_STACK_TOKEN=REPLACE_WITH_YOUR_BETTER_STACK_TOKEN
LOGTAIL_TOKEN=REPLACE_WITH_YOUR_LOGTAIL_TOKEN

# Sentry (Error tracking)
SENTRY_DSN=https://your-dsn@sentry.io/project-id

# ==============================================
# PAIEMENTS MOBILE MONEY
# ==============================================

# Orange Money API
ORANGE_MONEY_CLIENT_ID=REPLACE_WITH_ORANGE_CLIENT_ID
ORANGE_MONEY_CLIENT_SECRET=REPLACE_WITH_ORANGE_CLIENT_SECRET
ORANGE_MONEY_API_URL=https://api.orange.com/orange-money-webpay/dev/v1

# MTN Mobile Money API
MTN_MOMO_API_KEY=REPLACE_WITH_MTN_API_KEY
MTN_MOMO_API_SECRET=REPLACE_WITH_MTN_API_SECRET
MTN_MOMO_SUBSCRIPTION_KEY=REPLACE_WITH_MTN_SUBSCRIPTION_KEY

# Wave API (si disponible)
WAVE_API_KEY=REPLACE_WITH_WAVE_API_KEY
WAVE_API_SECRET=REPLACE_WITH_WAVE_API_SECRET

# ==============================================
# SONARQUBE / QUALITY
# ==============================================

# SonarCloud (recommandé)
SONAR_TOKEN=REPLACE_WITH_YOUR_SONAR_TOKEN
SONAR_HOST_URL=https://sonarcloud.io
SONAR_ORGANIZATION=miasysteme

# ==============================================
# CHIFFREMENT ET SÉCURITÉ
# ==============================================

# Clé de chiffrement interne
INTERNAL_ENCRYPTION_KEY=$(generate_password 64)

# Clé de signature
SIGNATURE_SECRET=$(generate_password 48)

# Salt pour hachage
PASSWORD_SALT=$(generate_password 32)

# ==============================================
# IDENTIFIANTS UNIQUES
# ==============================================

# UUID pour cette instance
INSTANCE_UUID=$(generate_uuid)

# Clé d'API interne
INTERNAL_API_KEY=$(generate_api_key)

# ==============================================
# ENVIRONNEMENTS
# ==============================================

# URLs par environnement
DEV_BASE_URL=https://dev--ismail-platform.netlify.app
STAGING_BASE_URL=https://staging--ismail-platform.netlify.app
PROD_BASE_URL=https://ismail-platform.netlify.app

# ==============================================
# NOTIFICATIONS
# ==============================================

# Emails de notification
NOTIFICATION_EMAILS=ops@ismail-platform.com,dev@ismail-platform.com

# Numéros WhatsApp (pour notifications critiques)
WHATSAPP_NUMBERS=+225XXXXXXXX,+226XXXXXXXX

EOF

    chmod 600 "$SECRETS_FILE"
    log_success "Secrets générés dans: $SECRETS_FILE"
}

# Générer la configuration Netlify
generate_netlify_config() {
    log_info "Génération de la configuration Netlify..."
    
    # Source les secrets générés
    source "$SECRETS_FILE"
    
    cat > "$NETLIFY_FILE" << EOF
{
  "build": {
    "environment": {
      "NODE_VERSION": "20",
      "NPM_VERSION": "10",
      "REACT_APP_SUPABASE_URL": "$SUPABASE_URL",
      "REACT_APP_SUPABASE_ANON_KEY": "$SUPABASE_ANON_KEY",
      "REACT_APP_RAILWAY_BACKEND_URL": "$RAILWAY_BACKEND_URL",
      "REACT_APP_CLOUDINARY_CLOUD_NAME": "$CLOUDINARY_CLOUD_NAME",
      "REACT_APP_SENTRY_DSN": "$SENTRY_DSN"
    }
  },
  "context": {
    "production": {
      "environment": {
        "REACT_APP_ENVIRONMENT": "production",
        "REACT_APP_API_URL": "$RAILWAY_BACKEND_URL",
        "REACT_APP_BASE_URL": "$PROD_BASE_URL"
      }
    },
    "deploy-preview": {
      "environment": {
        "REACT_APP_ENVIRONMENT": "staging",
        "REACT_APP_API_URL": "$RAILWAY_STAGING_URL",
        "REACT_APP_BASE_URL": "$STAGING_BASE_URL"
      }
    },
    "branch-deploy": {
      "environment": {
        "REACT_APP_ENVIRONMENT": "development",
        "REACT_APP_API_URL": "$RAILWAY_DEV_URL",
        "REACT_APP_BASE_URL": "$DEV_BASE_URL"
      }
    }
  }
}
EOF

    chmod 600 "$NETLIFY_FILE"
    log_success "Configuration Netlify générée: $NETLIFY_FILE"
}

# Générer la configuration Railway
generate_railway_config() {
    log_info "Génération de la configuration Railway..."
    
    # Source les secrets générés
    source "$SECRETS_FILE"
    
    cat > "$RAILWAY_FILE" << EOF
{
  "environments": {
    "production": {
      "variables": {
        "SPRING_PROFILES_ACTIVE": "production",
        "SERVER_PORT": "8080",
        "DATABASE_URL": "$DATABASE_URL",
        "REDIS_URL": "$REDIS_URL",
        "JWT_SECRET": "$PROD_JWT_SECRET",
        "REFRESH_TOKEN_SECRET": "$REFRESH_TOKEN_SECRET",
        "RESEND_API_KEY": "$RESEND_API_KEY",
        "CLOUDINARY_URL": "$CLOUDINARY_URL",
        "BETTER_STACK_TOKEN": "$BETTER_STACK_TOKEN",
        "SENTRY_DSN": "$SENTRY_DSN",
        "INTERNAL_ENCRYPTION_KEY": "$INTERNAL_ENCRYPTION_KEY",
        "ORANGE_MONEY_CLIENT_ID": "$ORANGE_MONEY_CLIENT_ID",
        "ORANGE_MONEY_CLIENT_SECRET": "$ORANGE_MONEY_CLIENT_SECRET",
        "MTN_MOMO_API_KEY": "$MTN_MOMO_API_KEY",
        "MTN_MOMO_API_SECRET": "$MTN_MOMO_API_SECRET"
      }
    },
    "staging": {
      "variables": {
        "SPRING_PROFILES_ACTIVE": "staging",
        "SERVER_PORT": "8080",
        "DATABASE_URL": "$DATABASE_URL",
        "REDIS_URL": "$REDIS_URL",
        "JWT_SECRET": "$DEV_JWT_SECRET",
        "REFRESH_TOKEN_SECRET": "$REFRESH_TOKEN_SECRET",
        "RESEND_API_KEY": "$RESEND_API_KEY",
        "CLOUDINARY_URL": "$CLOUDINARY_URL",
        "BETTER_STACK_TOKEN": "$BETTER_STACK_TOKEN",
        "INTERNAL_ENCRYPTION_KEY": "$INTERNAL_ENCRYPTION_KEY"
      }
    }
  }
}
EOF

    chmod 600 "$RAILWAY_FILE"
    log_success "Configuration Railway générée: $RAILWAY_FILE"
}

# Générer un script d'upload GitHub adapté
generate_github_upload_script() {
    local upload_script="${SCRIPT_DIR}/../.secrets/upload-africa-secrets.sh"
    
    cat > "$upload_script" << 'EOF'
#!/bin/bash

# Script pour uploader les secrets Stack Afrique vers GitHub
# Adapté pour Netlify, Railway, Supabase

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="${SCRIPT_DIR}/africa-secrets.env"

# Vérifier GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) n'est pas installé"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "❌ GitHub CLI n'est pas authentifié"
    exit 1
fi

echo "🌍 Upload des secrets Stack Afrique vers GitHub..."

# Source les secrets
source "$SECRETS_FILE"

# Repository secrets
echo "📤 Upload des secrets repository..."
gh secret set SUPABASE_URL --body "$SUPABASE_URL"
gh secret set SUPABASE_ANON_KEY --body "$SUPABASE_ANON_KEY"
gh secret set SUPABASE_SERVICE_KEY --body "$SUPABASE_SERVICE_KEY"
gh secret set RAILWAY_BACKEND_URL --body "$RAILWAY_BACKEND_URL"
gh secret set UPSTASH_REDIS_REST_URL --body "$UPSTASH_REDIS_REST_URL"
gh secret set UPSTASH_REDIS_REST_TOKEN --body "$UPSTASH_REDIS_REST_TOKEN"
gh secret set DEV_JWT_SECRET --body "$DEV_JWT_SECRET"
gh secret set CLOUDINARY_CLOUD_NAME --body "$CLOUDINARY_CLOUD_NAME"
gh secret set CLOUDINARY_API_KEY --body "$CLOUDINARY_API_KEY"
gh secret set CLOUDINARY_API_SECRET --body "$CLOUDINARY_API_SECRET"
gh secret set INTERNAL_ENCRYPTION_KEY --body "$INTERNAL_ENCRYPTION_KEY"
gh secret set DEV_BASE_URL --body "$DEV_BASE_URL"
gh secret set STAGING_BASE_URL --body "$STAGING_BASE_URL"

# Environment secrets (production)
echo "📤 Upload des secrets environment production..."
gh secret set PROD_JWT_SECRET --env production-approval --body "$PROD_JWT_SECRET"
gh secret set PROD_BASE_URL --env production-approval --body "$PROD_BASE_URL"
gh secret set RESEND_API_KEY --env production-approval --body "$RESEND_API_KEY"
gh secret set BETTER_STACK_TOKEN --env production-approval --body "$BETTER_STACK_TOKEN"
gh secret set ORANGE_MONEY_CLIENT_ID --env production-approval --body "$ORANGE_MONEY_CLIENT_ID"
gh secret set ORANGE_MONEY_CLIENT_SECRET --env production-approval --body "$ORANGE_MONEY_CLIENT_SECRET"
gh secret set MTN_MOMO_API_KEY --env production-approval --body "$MTN_MOMO_API_KEY"
gh secret set MTN_MOMO_API_SECRET --env production-approval --body "$MTN_MOMO_API_SECRET"
gh secret set NOTIFICATION_EMAILS --env production-approval --body "$NOTIFICATION_EMAILS"

echo "⚠️  Configurez manuellement ces secrets:"
echo "   - NETLIFY_BUILD_HOOK"
echo "   - DISCORD_WEBHOOK_URL"
echo "   - SONAR_TOKEN"
echo "   - SENTRY_DSN"

echo "✅ Secrets Stack Afrique uploadés avec succès !"
echo "🔗 Vérifiez sur: https://github.com/miasysteme/Ismail-Plateform/settings/secrets"
EOF

    chmod +x "$upload_script"
    log_success "Script d'upload GitHub généré: $upload_script"
}

# Afficher le résumé
display_summary() {
    log_info "=== Résumé Génération Secrets Stack Afrique ==="
    
    echo
    echo "🌍 **Stack Cloud Afrique configurée**:"
    echo "  ✅ Netlify - Hébergement frontend"
    echo "  ✅ Railway - Backend services"
    echo "  ✅ Supabase - Base de données PostgreSQL"
    echo "  ✅ Upstash - Redis serverless"
    echo "  ✅ Resend - Emails (alternative SendGrid)"
    echo "  ✅ Cloudinary - Stockage images"
    echo "  ✅ Better Stack - Monitoring"
    echo
    echo "📁 **Fichiers générés**:"
    echo "  ✅ $SECRETS_FILE"
    echo "  ✅ $NETLIFY_FILE"
    echo "  ✅ $RAILWAY_FILE"
    echo "  ✅ ${SCRIPT_DIR}/../.secrets/upload-africa-secrets.sh"
    echo
    echo "🔐 **Secrets générés**:"
    echo "  ✅ JWT secrets (dev/prod)"
    echo "  ✅ Clés de chiffrement"
    echo "  ✅ Identifiants uniques"
    echo "  ✅ Configuration environnements"
    echo
    echo "⚠️  **À configurer manuellement**:"
    echo "  🔑 SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_KEY"
    echo "  🔑 RAILWAY_BACKEND_URL (après déploiement)"
    echo "  🔑 UPSTASH_REDIS_REST_URL, UPSTASH_REDIS_REST_TOKEN"
    echo "  🔑 RESEND_API_KEY"
    echo "  🔑 CLOUDINARY credentials"
    echo "  🔑 ORANGE_MONEY et MTN_MOMO API keys"
    echo "  🔑 DISCORD_WEBHOOK_URL"
    echo "  🔑 BETTER_STACK_TOKEN"
    echo "  🔑 SONAR_TOKEN"
    echo
    echo "📋 **Prochaines étapes**:"
    echo "  1. Créer les comptes sur les services (Supabase, Railway, etc.)"
    echo "  2. Configurer les services et récupérer les clés"
    echo "  3. Mettre à jour le fichier secrets avec les vraies valeurs"
    echo "  4. Exécuter: .secrets/upload-africa-secrets.sh"
    echo "  5. Configurer Netlify et Railway"
    echo "  6. Tester la stack complète"
    echo
    log_warning "IMPORTANT: Cette stack est optimisée pour l'Afrique de l'Ouest !"
    log_success "Coûts estimés: $30-80/mois vs $200-500/mois avec AWS"
}

# Fonction principale
main() {
    echo "🌍 Génération Secrets Stack Cloud Afrique - ISMAIL Platform"
    echo "========================================================="
    echo
    
    check_prerequisites
    create_secrets_directory
    generate_africa_secrets
    generate_netlify_config
    generate_railway_config
    generate_github_upload_script
    display_summary
}

# Vérification des arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -gt 0 && "$1" == "--help" ]]; then
        echo "Usage: $0"
        echo
        echo "Génère les secrets pour Stack Cloud Afrique (Netlify + Railway + Supabase)."
        echo
        echo "Services configurés:"
        echo "  - Netlify (hébergement frontend)"
        echo "  - Railway (backend services)"
        echo "  - Supabase (base de données)"
        echo "  - Upstash (Redis)"
        echo "  - Resend (emails)"
        echo "  - Cloudinary (stockage)"
        echo "  - Better Stack (monitoring)"
        echo
        echo "Avantages pour l'Afrique:"
        echo "  - Accessible depuis l'Afrique de l'Ouest"
        echo "  - Latence optimisée"
        echo "  - Coûts réduits"
        echo "  - Support mobile money"
        echo
        exit 0
    fi
    
    main "$@"
fi
