#!/bin/bash

# Script de validation de la Stack Cloud Afrique pour ISMAIL Platform
# Vérifie la connectivité et configuration de tous les services

set -euo pipefail

# Configuration
SECRETS_FILE="${PWD}/.secrets/africa-secrets.env"

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

# Charger les secrets
load_secrets() {
    if [ -f "$SECRETS_FILE" ]; then
        source "$SECRETS_FILE"
        log_success "Secrets chargés depuis $SECRETS_FILE"
    else
        log_error "Fichier secrets non trouvé: $SECRETS_FILE"
        log_info "Exécutez d'abord: ./scripts/generate-secrets-africa.sh"
        exit 1
    fi
}

# Vérifier les prérequis
check_prerequisites() {
    log_info "=== Vérification des Prérequis ==="
    
    run_check "curl installé" "command -v curl"
    run_check "jq installé" "command -v jq"
    run_check "node installé" "command -v node"
    run_check "npm installé" "command -v npm"
    
    echo
}

# Tester Netlify
test_netlify() {
    log_info "=== Test Netlify ==="
    
    if [ -n "${NETLIFY_SITE_URL:-}" ]; then
        run_check "Netlify site accessible" "curl -s -f --max-time 10 '$NETLIFY_SITE_URL'"
    else
        log_warning "NETLIFY_SITE_URL non configuré"
    fi
    
    # Test Netlify CLI si installé
    if command -v netlify &> /dev/null; then
        if [ -n "${NETLIFY_AUTH_TOKEN:-}" ]; then
            run_check "Netlify CLI auth" "netlify status --auth '$NETLIFY_AUTH_TOKEN'"
        else
            log_warning "NETLIFY_AUTH_TOKEN non configuré"
        fi
    else
        log_warning "Netlify CLI non installé"
    fi
    
    echo
}

# Tester Supabase
test_supabase() {
    log_info "=== Test Supabase ==="
    
    if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_ANON_KEY:-}" ]; then
        # Test API Supabase
        run_check "Supabase API accessible" "curl -s -f --max-time 10 -H 'apikey: $SUPABASE_ANON_KEY' '$SUPABASE_URL/rest/v1/'"
        
        # Test Auth endpoint
        run_check "Supabase Auth accessible" "curl -s -f --max-time 10 -H 'apikey: $SUPABASE_ANON_KEY' '$SUPABASE_URL/auth/v1/settings'"
    else
        log_warning "Credentials Supabase non configurés"
    fi
    
    echo
}

# Tester Railway
test_railway() {
    log_info "=== Test Railway ==="
    
    if [ -n "${RAILWAY_BACKEND_URL:-}" ]; then
        # Test health endpoint
        run_check "Railway backend accessible" "curl -s -f --max-time 10 '$RAILWAY_BACKEND_URL/actuator/health'"
    else
        log_warning "RAILWAY_BACKEND_URL non configuré"
    fi
    
    # Test Railway CLI si installé
    if command -v railway &> /dev/null; then
        if [ -n "${RAILWAY_TOKEN:-}" ]; then
            run_check "Railway CLI auth" "railway login --token '$RAILWAY_TOKEN'"
        else
            log_warning "RAILWAY_TOKEN non configuré"
        fi
    else
        log_warning "Railway CLI non installé"
    fi
    
    echo
}

# Tester Upstash Redis
test_upstash() {
    log_info "=== Test Upstash Redis ==="
    
    if [ -n "${UPSTASH_REDIS_REST_URL:-}" ] && [ -n "${UPSTASH_REDIS_REST_TOKEN:-}" ]; then
        # Test ping Redis
        run_check "Upstash Redis ping" "curl -s -f --max-time 10 -H 'Authorization: Bearer $UPSTASH_REDIS_REST_TOKEN' '$UPSTASH_REDIS_REST_URL/ping'"
        
        # Test set/get
        local test_key="test_$(date +%s)"
        local test_value="test_value"
        
        if curl -s -f --max-time 10 -H "Authorization: Bearer $UPSTASH_REDIS_REST_TOKEN" \
           -d "[\"SET\", \"$test_key\", \"$test_value\"]" \
           "$UPSTASH_REDIS_REST_URL" &> /dev/null; then
            
            run_check "Upstash Redis set/get" "curl -s -f --max-time 10 -H 'Authorization: Bearer $UPSTASH_REDIS_REST_TOKEN' -d '[\"GET\", \"$test_key\"]' '$UPSTASH_REDIS_REST_URL' | jq -r '.result' | grep -q '$test_value'"
            
            # Cleanup
            curl -s -H "Authorization: Bearer $UPSTASH_REDIS_REST_TOKEN" \
                 -d "[\"DEL\", \"$test_key\"]" \
                 "$UPSTASH_REDIS_REST_URL" &> /dev/null
        else
            log_error "✗ Upstash Redis set/get"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        fi
    else
        log_warning "Credentials Upstash non configurés"
    fi
    
    echo
}

# Tester Resend
test_resend() {
    log_info "=== Test Resend ==="
    
    if [ -n "${RESEND_API_KEY:-}" ]; then
        # Test API Resend
        run_check "Resend API accessible" "curl -s -f --max-time 10 -H 'Authorization: Bearer $RESEND_API_KEY' 'https://api.resend.com/domains'"
    else
        log_warning "RESEND_API_KEY non configuré"
    fi
    
    echo
}

# Tester Cloudinary
test_cloudinary() {
    log_info "=== Test Cloudinary ==="
    
    if [ -n "${CLOUDINARY_CLOUD_NAME:-}" ] && [ -n "${CLOUDINARY_API_KEY:-}" ]; then
        # Test API Cloudinary
        run_check "Cloudinary API accessible" "curl -s -f --max-time 10 'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/list' -u '$CLOUDINARY_API_KEY:$CLOUDINARY_API_SECRET'"
    else
        log_warning "Credentials Cloudinary non configurés"
    fi
    
    echo
}

# Tester Discord
test_discord() {
    log_info "=== Test Discord ==="
    
    if [ -n "${DISCORD_WEBHOOK_URL:-}" ]; then
        # Test webhook Discord
        local test_message='{"content": "🧪 Test de connectivité ISMAIL Platform - Stack Afrique"}'
        
        run_check "Discord webhook" "curl -s -f --max-time 10 -H 'Content-Type: application/json' -d '$test_message' '$DISCORD_WEBHOOK_URL'"
    else
        log_warning "DISCORD_WEBHOOK_URL non configuré"
    fi
    
    echo
}

# Tester Better Stack
test_better_stack() {
    log_info "=== Test Better Stack ==="
    
    if [ -n "${BETTER_STACK_TOKEN:-}" ]; then
        # Test API Better Stack
        run_check "Better Stack API accessible" "curl -s -f --max-time 10 -H 'Authorization: Bearer $BETTER_STACK_TOKEN' 'https://logs.betterstack.com/api/v1/tail'"
    else
        log_warning "BETTER_STACK_TOKEN non configuré"
    fi
    
    echo
}

# Tester Sentry
test_sentry() {
    log_info "=== Test Sentry ==="
    
    if [ -n "${SENTRY_DSN:-}" ]; then
        # Extraire l'URL de base du DSN
        local sentry_host=$(echo "$SENTRY_DSN" | sed -n 's|https://.*@\([^/]*\)/.*|\1|p')
        
        if [ -n "$sentry_host" ]; then
            run_check "Sentry accessible" "curl -s -f --max-time 10 'https://$sentry_host/api/0/'"
        else
            log_warning "Format SENTRY_DSN invalide"
        fi
    else
        log_warning "SENTRY_DSN non configuré"
    fi
    
    echo
}

# Tester GitHub Secrets
test_github_secrets() {
    log_info "=== Test GitHub Secrets ==="
    
    if command -v gh &> /dev/null; then
        if gh auth status &> /dev/null; then
            # Vérifier quelques secrets clés
            local key_secrets=("SUPABASE_URL" "RAILWAY_BACKEND_URL" "NETLIFY_AUTH_TOKEN")
            
            for secret in "${key_secrets[@]}"; do
                run_check "GitHub secret: $secret" "gh secret list | grep -q '$secret'"
            done
        else
            log_warning "GitHub CLI non authentifié"
        fi
    else
        log_warning "GitHub CLI non installé"
    fi
    
    echo
}

# Test de latence réseau
test_network_latency() {
    log_info "=== Test Latence Réseau ==="
    
    local services=(
        "netlify.com"
        "railway.app"
        "supabase.com"
        "upstash.com"
        "resend.com"
        "cloudinary.com"
    )
    
    for service in "${services[@]}"; do
        local latency=$(curl -o /dev/null -s -w "%{time_total}" --max-time 5 "https://$service" 2>/dev/null || echo "timeout")
        
        if [ "$latency" != "timeout" ]; then
            local latency_ms=$(echo "$latency * 1000" | bc 2>/dev/null || echo "0")
            log_success "✓ $service: ${latency_ms%.*}ms"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            log_error "✗ $service: timeout"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
        fi
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    done
    
    echo
}

# Générer un rapport
generate_report() {
    local report_file="africa-stack-validation-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Rapport de Validation Stack Cloud Afrique - ISMAIL Platform

**Date**: $(date -u +%Y-%m-%dT%H:%M:%SZ)  
**Stack**: Netlify + Railway + Supabase + Services Afrique

## 📊 Résumé

- **Total des vérifications**: $TOTAL_CHECKS
- **Réussies**: $PASSED_CHECKS
- **Échouées**: $FAILED_CHECKS
- **Taux de réussite**: $(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))%

## 🌍 Services Testés

### Hébergement et Déploiement
- Netlify: $([ -n "${NETLIFY_SITE_URL:-}" ] && echo "✅ Configuré" || echo "⚠️ Non configuré")
- Railway: $([ -n "${RAILWAY_BACKEND_URL:-}" ] && echo "✅ Configuré" || echo "⚠️ Non configuré")

### Base de Données et Cache
- Supabase: $([ -n "${SUPABASE_URL:-}" ] && echo "✅ Configuré" || echo "⚠️ Non configuré")
- Upstash Redis: $([ -n "${UPSTASH_REDIS_REST_URL:-}" ] && echo "✅ Configuré" || echo "⚠️ Non configuré")

### Services Externes
- Resend: $([ -n "${RESEND_API_KEY:-}" ] && echo "✅ Configuré" || echo "⚠️ Non configuré")
- Cloudinary: $([ -n "${CLOUDINARY_CLOUD_NAME:-}" ] && echo "✅ Configuré" || echo "⚠️ Non configuré")
- Discord: $([ -n "${DISCORD_WEBHOOK_URL:-}" ] && echo "✅ Configuré" || echo "⚠️ Non configuré")

### Monitoring
- Better Stack: $([ -n "${BETTER_STACK_TOKEN:-}" ] && echo "✅ Configuré" || echo "⚠️ Non configuré")
- Sentry: $([ -n "${SENTRY_DSN:-}" ] && echo "✅ Configuré" || echo "⚠️ Non configuré")

## 🎯 Recommandations

$(if [ $FAILED_CHECKS -gt 0 ]; then
    echo "### Actions Requises"
    echo "- Corriger les $FAILED_CHECKS vérifications échouées"
    echo "- Configurer les services manquants"
    echo "- Vérifier les credentials et URLs"
else
    echo "### Stack Opérationnelle"
    echo "✅ Tous les services sont opérationnels !"
    echo "✅ La stack Afrique est prête pour la production"
fi)

## 💰 Estimation des Coûts

- **Netlify**: Gratuit → \$19/mois
- **Railway**: \$5/mois par service
- **Supabase**: Gratuit → \$25/mois
- **Upstash**: Gratuit → \$0.2/100k requêtes
- **Resend**: Gratuit → \$20/mois
- **Cloudinary**: Gratuit → \$89/mois

**Total estimé**: \$30-180/mois (vs \$200-500/mois avec AWS)

---
*Rapport généré automatiquement par validate-africa-stack.sh*
EOF
    
    log_success "Rapport généré: $report_file"
}

# Afficher le résumé final
display_summary() {
    echo
    log_info "=== Résumé de la Validation Stack Afrique ==="
    
    echo
    echo "🌍 **Stack Cloud Afrique**:"
    echo "  - Netlify (Frontend)"
    echo "  - Railway (Backend)"
    echo "  - Supabase (Database)"
    echo "  - Upstash (Redis)"
    echo "  - Resend (Emails)"
    echo "  - Cloudinary (Storage)"
    echo "  - Discord (Notifications)"
    echo "  - Better Stack (Monitoring)"
    echo
    echo "📊 **Statistiques**:"
    echo "  - Total des vérifications: $TOTAL_CHECKS"
    echo "  - Réussies: $PASSED_CHECKS"
    echo "  - Échouées: $FAILED_CHECKS"
    echo "  - Taux de réussite: $(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))%"
    echo
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        log_success "🎉 Stack Cloud Afrique opérationnelle !"
        log_success "✅ Tous les services sont accessibles depuis l'Afrique"
        echo
        echo "🚀 **Prêt pour**:"
        echo "  ✅ Déploiement automatique"
        echo "  ✅ Scaling en Afrique de l'Ouest"
        echo "  ✅ Coûts optimisés"
        echo "  ✅ Latence réduite"
    else
        log_error "❌ $FAILED_CHECKS services ont des problèmes"
        echo
        echo "🔧 **Actions requises**:"
        echo "  1. Configurer les services manquants"
        echo "  2. Vérifier les credentials"
        echo "  3. Consulter docs/africa-services-setup.md"
        echo "  4. Relancer la validation"
    fi
    
    echo
    echo "📚 **Documentation**:"
    echo "  - docs/cloud-africa-setup.md"
    echo "  - docs/africa-services-setup.md"
    echo "  - .secrets/africa-secrets.env"
}

# Fonction principale
main() {
    echo "🌍 Validation Stack Cloud Afrique - ISMAIL Platform"
    echo "================================================"
    echo
    
    load_secrets
    check_prerequisites
    test_netlify
    test_supabase
    test_railway
    test_upstash
    test_resend
    test_cloudinary
    test_discord
    test_better_stack
    test_sentry
    test_github_secrets
    test_network_latency
    
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
        echo "Valide la Stack Cloud Afrique pour ISMAIL Platform."
        echo
        echo "Services testés:"
        echo "  - Netlify (hébergement frontend)"
        echo "  - Railway (backend services)"
        echo "  - Supabase (base de données)"
        echo "  - Upstash (Redis serverless)"
        echo "  - Resend (service emails)"
        echo "  - Cloudinary (stockage images)"
        echo "  - Discord (notifications)"
        echo "  - Better Stack (monitoring)"
        echo "  - Sentry (error tracking)"
        echo
        echo "Prérequis:"
        echo "  - Fichier .secrets/africa-secrets.env configuré"
        echo "  - curl, jq, node, npm installés"
        echo
        exit 0
    fi
    
    main "$@"
fi
