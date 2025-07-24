#!/bin/bash

# Tests de fumée pour la plateforme ISMAIL
# Vérifications rapides post-déploiement

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENT="${1:-dev}"
BASE_URL="${BASE_URL:-http://localhost:8080}"
TIMEOUT="${TIMEOUT:-30}"

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

# Variables globales
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Fonction pour exécuter un test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    log_info "Running test: $test_name"
    
    if eval "$test_command"; then
        log_success "✓ $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_error "✗ $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Test de connectivité de base
test_basic_connectivity() {
    curl -s -f --max-time $TIMEOUT "$BASE_URL" > /dev/null
}

# Test de santé des services
test_service_health() {
    local service="$1"
    curl -s -f --max-time $TIMEOUT "$BASE_URL/api/$service/actuator/health" | \
        jq -e '.status == "UP"' > /dev/null
}

# Test d'information des services
test_service_info() {
    local service="$1"
    curl -s -f --max-time $TIMEOUT "$BASE_URL/api/$service/actuator/info" | \
        jq -e '.app.name' > /dev/null
}

# Test d'inscription utilisateur
test_user_registration() {
    local timestamp=$(date +%s)
    local test_user_email="smoke-test-${timestamp}@ismail-platform.com"
    local test_user_phone="+225012345${timestamp: -4}"
    
    local response=$(curl -s -w "%{http_code}" --max-time $TIMEOUT \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$test_user_email\",
            \"phone\": \"$test_user_phone\",
            \"password\": \"SmokeTest123!\",
            \"confirmPassword\": \"SmokeTest123!\",
            \"firstName\": \"Smoke\",
            \"lastName\": \"Test\",
            \"profileType\": \"CLIENT\",
            \"acceptTerms\": true,
            \"acceptPrivacy\": true
        }" \
        "$BASE_URL/api/auth/register")
    
    local http_code="${response: -3}"
    local body="${response%???}"
    
    if [[ "$http_code" == "201" ]]; then
        echo "$body" | jq -e '.success == true and .accessToken != null' > /dev/null
    else
        return 1
    fi
}

# Test de connexion utilisateur
test_user_login() {
    # Utiliser un utilisateur de test prédéfini
    local response=$(curl -s -w "%{http_code}" --max-time $TIMEOUT \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"test@ismail-platform.com\",
            \"password\": \"TestPassword123!\"
        }" \
        "$BASE_URL/api/auth/login")
    
    local http_code="${response: -3}"
    local body="${response%???}"
    
    if [[ "$http_code" == "200" ]]; then
        echo "$body" | jq -e '.success == true and .accessToken != null' > /dev/null
    else
        # Si l'utilisateur n'existe pas, ce n'est pas forcément une erreur en dev
        if [[ "$ENVIRONMENT" == "dev" && "$http_code" == "401" ]]; then
            log_warning "Test user not found in dev environment - this is expected"
            return 0
        fi
        return 1
    fi
}

# Test de consultation du solde portefeuille
test_wallet_balance() {
    # D'abord, créer un utilisateur et récupérer le token
    local timestamp=$(date +%s)
    local test_user_email="wallet-test-${timestamp}@ismail-platform.com"
    local test_user_phone="+225012345${timestamp: -4}"
    
    local auth_response=$(curl -s --max-time $TIMEOUT \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$test_user_email\",
            \"phone\": \"$test_user_phone\",
            \"password\": \"SmokeTest123!\",
            \"confirmPassword\": \"SmokeTest123!\",
            \"firstName\": \"Wallet\",
            \"lastName\": \"Test\",
            \"profileType\": \"CLIENT\",
            \"acceptTerms\": true,
            \"acceptPrivacy\": true
        }" \
        "$BASE_URL/api/auth/register")
    
    local token=$(echo "$auth_response" | jq -r '.accessToken // empty')
    
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    # Tester l'accès au portefeuille
    local wallet_response=$(curl -s -w "%{http_code}" --max-time $TIMEOUT \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        "$BASE_URL/api/wallet/balance")
    
    local http_code="${wallet_response: -3}"
    local body="${wallet_response%???}"
    
    if [[ "$http_code" == "200" ]]; then
        echo "$body" | jq -e '.balance != null and .currency != null' > /dev/null
    else
        return 1
    fi
}

# Test de métriques Prometheus
test_prometheus_metrics() {
    local service="$1"
    curl -s -f --max-time $TIMEOUT "$BASE_URL/api/$service/actuator/prometheus" | \
        grep -q "jvm_memory_used_bytes"
}

# Test de Kong API Gateway
test_kong_gateway() {
    # Tester l'accès via Kong (si configuré)
    if [[ "$ENVIRONMENT" != "dev" ]]; then
        curl -s -f --max-time $TIMEOUT "$BASE_URL/api/auth/actuator/health" > /dev/null
    else
        # En dev, Kong peut ne pas être configuré
        return 0
    fi
}

# Test de base de données
test_database_connectivity() {
    # Tester indirectement via un endpoint qui utilise la DB
    curl -s -f --max-time $TIMEOUT "$BASE_URL/api/auth/actuator/health" | \
        jq -e '.components.db.status == "UP"' > /dev/null
}

# Test de Redis
test_redis_connectivity() {
    # Tester indirectement via un endpoint qui utilise Redis
    curl -s -f --max-time $TIMEOUT "$BASE_URL/api/auth/actuator/health" | \
        jq -e '.components.redis.status == "UP"' > /dev/null
}

# Test de sécurité basique
test_security_headers() {
    local response=$(curl -s -I --max-time $TIMEOUT "$BASE_URL/api/auth/actuator/health")
    
    # Vérifier la présence de headers de sécurité
    echo "$response" | grep -qi "x-content-type-options" && \
    echo "$response" | grep -qi "x-frame-options"
}

# Test de rate limiting (si configuré)
test_rate_limiting() {
    local count=0
    local max_requests=20
    
    for i in $(seq 1 $max_requests); do
        local response=$(curl -s -w "%{http_code}" --max-time 5 \
            "$BASE_URL/api/auth/actuator/health" 2>/dev/null)
        local http_code="${response: -3}"
        
        if [[ "$http_code" == "429" ]]; then
            log_info "Rate limiting detected after $i requests"
            return 0
        fi
        
        count=$((count + 1))
        sleep 0.1
    done
    
    # Si pas de rate limiting détecté, ce n'est pas forcément une erreur
    log_warning "No rate limiting detected after $max_requests requests"
    return 0
}

# Fonction principale
main() {
    log_info "=== ISMAIL Smoke Tests ==="
    log_info "Environment: $ENVIRONMENT"
    log_info "Base URL: $BASE_URL"
    log_info "Timeout: ${TIMEOUT}s"
    echo
    
    # Vérifier les prérequis
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        exit 1
    fi
    
    # Tests de base
    run_test "Basic connectivity" "test_basic_connectivity"
    run_test "Kong API Gateway" "test_kong_gateway"
    
    # Tests des services
    run_test "Auth service health" "test_service_health auth"
    run_test "Wallet service health" "test_service_health wallet"
    run_test "Auth service info" "test_service_info auth"
    run_test "Wallet service info" "test_service_info wallet"
    
    # Tests fonctionnels
    run_test "User registration" "test_user_registration"
    run_test "User login" "test_user_login"
    run_test "Wallet balance access" "test_wallet_balance"
    
    # Tests d'infrastructure
    run_test "Database connectivity" "test_database_connectivity"
    run_test "Redis connectivity" "test_redis_connectivity"
    
    # Tests de métriques
    run_test "Auth service metrics" "test_prometheus_metrics auth"
    run_test "Wallet service metrics" "test_prometheus_metrics wallet"
    
    # Tests de sécurité
    run_test "Security headers" "test_security_headers"
    run_test "Rate limiting" "test_rate_limiting"
    
    # Résumé
    echo
    log_info "=== Test Summary ==="
    log_info "Total tests: $TOTAL_TESTS"
    log_success "Passed: $PASSED_TESTS"
    
    if [[ $FAILED_TESTS -gt 0 ]]; then
        log_error "Failed: $FAILED_TESTS"
        echo
        log_error "Some smoke tests failed. Check the logs above for details."
        exit 1
    else
        echo
        log_success "🎉 All smoke tests passed!"
        exit 0
    fi
}

# Vérification des arguments
if [[ $# -gt 1 ]]; then
    echo "Usage: $0 [environment]"
    echo "Environments: dev, staging, prod"
    echo
    echo "Environment variables:"
    echo "  BASE_URL - Base URL of the services (default: http://localhost:8080)"
    echo "  TIMEOUT  - Request timeout in seconds (default: 30)"
    echo
    echo "Example:"
    echo "  BASE_URL=https://api.ismail-platform.com $0 prod"
    exit 1
fi

# Exécution du script principal
main "$@"
