#!/bin/bash

# Script pour exécuter tous les tests de la plateforme ISMAIL
# Tests unitaires, d'intégration et de performance

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TESTS_DIR="${PROJECT_ROOT}/tests"

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
ENVIRONMENT="${ENVIRONMENT:-dev}"
BASE_URL="${BASE_URL:-http://localhost:8080}"
SKIP_UNIT_TESTS="${SKIP_UNIT_TESTS:-false}"
SKIP_INTEGRATION_TESTS="${SKIP_INTEGRATION_TESTS:-false}"
SKIP_PERFORMANCE_TESTS="${SKIP_PERFORMANCE_TESTS:-false}"
PERFORMANCE_DURATION="${PERFORMANCE_DURATION:-5m}"

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help                  Afficher cette aide
    -e, --environment ENV       Environnement (dev, staging, prod) [default: dev]
    -u, --base-url URL         URL de base des services [default: http://localhost:8080]
    -d, --duration DURATION    Durée des tests de performance [default: 5m]
    --skip-unit                Ignorer les tests unitaires
    --skip-integration         Ignorer les tests d'intégration
    --skip-performance         Ignorer les tests de performance

Variables d'environnement:
    ENVIRONMENT               Environnement de test
    BASE_URL                  URL de base des services
    SKIP_UNIT_TESTS          Ignorer les tests unitaires (true/false)
    SKIP_INTEGRATION_TESTS   Ignorer les tests d'intégration (true/false)
    SKIP_PERFORMANCE_TESTS   Ignorer les tests de performance (true/false)
    PERFORMANCE_DURATION     Durée des tests de performance

Exemples:
    $0                                    # Tous les tests en local
    $0 -e staging -u https://staging.ismail-platform.com
    $0 --skip-performance                 # Sans tests de performance
    $0 -d 10m                            # Tests de performance de 10 minutes

EOF
}

# Analyser les arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -u|--base-url)
                BASE_URL="$2"
                shift 2
                ;;
            -d|--duration)
                PERFORMANCE_DURATION="$2"
                shift 2
                ;;
            --skip-unit)
                SKIP_UNIT_TESTS="true"
                shift
                ;;
            --skip-integration)
                SKIP_INTEGRATION_TESTS="true"
                shift
                ;;
            --skip-performance)
                SKIP_PERFORMANCE_TESTS="true"
                shift
                ;;
            *)
                log_error "Option inconnue: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier Java pour les tests unitaires et d'intégration
    if [[ "$SKIP_UNIT_TESTS" != "true" || "$SKIP_INTEGRATION_TESTS" != "true" ]]; then
        if ! command -v java &> /dev/null; then
            log_error "Java n'est pas installé"
            exit 1
        fi
        
        if ! command -v mvn &> /dev/null; then
            log_error "Maven n'est pas installé"
            exit 1
        fi
    fi
    
    # Vérifier K6 pour les tests de performance
    if [[ "$SKIP_PERFORMANCE_TESTS" != "true" ]]; then
        if ! command -v k6 &> /dev/null; then
            log_error "K6 n'est pas installé"
            log_info "Installation: https://k6.io/docs/getting-started/installation/"
            exit 1
        fi
    fi
    
    # Vérifier curl pour les tests de connectivité
    if ! command -v curl &> /dev/null; then
        log_error "curl n'est pas installé"
        exit 1
    fi
    
    log_success "Prérequis validés"
}

# Tester la connectivité aux services
test_connectivity() {
    log_info "Test de connectivité aux services..."
    
    local services=("auth" "wallet")
    local all_healthy=true
    
    for service in "${services[@]}"; do
        local url="${BASE_URL}/api/${service}/actuator/health"
        
        if curl -s -f "$url" > /dev/null; then
            log_success "✓ Service $service accessible"
        else
            log_warning "⚠ Service $service non accessible: $url"
            all_healthy=false
        fi
    done
    
    if [[ "$all_healthy" != "true" ]]; then
        log_warning "Certains services ne sont pas accessibles"
        log_info "Les tests peuvent échouer si les services ne sont pas démarrés"
        
        read -p "Continuer quand même ? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Exécuter les tests unitaires
run_unit_tests() {
    if [[ "$SKIP_UNIT_TESTS" == "true" ]]; then
        log_info "Tests unitaires ignorés"
        return 0
    fi
    
    log_info "=== Exécution des tests unitaires ==="
    
    local services=("auth-service" "wallet-service")
    local overall_success=true
    
    for service in "${services[@]}"; do
        log_info "Tests unitaires pour $service..."
        
        cd "${PROJECT_ROOT}/services/$service"
        
        if mvn clean test -Dspring.profiles.active=test; then
            log_success "✓ Tests unitaires $service réussis"
        else
            log_error "✗ Tests unitaires $service échoués"
            overall_success=false
        fi
        
        # Générer le rapport de couverture
        if mvn jacoco:report; then
            log_info "Rapport de couverture généré: target/site/jacoco/index.html"
        fi
        
        cd - > /dev/null
    done
    
    if [[ "$overall_success" == "true" ]]; then
        log_success "Tous les tests unitaires ont réussi"
    else
        log_error "Certains tests unitaires ont échoué"
        return 1
    fi
}

# Exécuter les tests d'intégration
run_integration_tests() {
    if [[ "$SKIP_INTEGRATION_TESTS" == "true" ]]; then
        log_info "Tests d'intégration ignorés"
        return 0
    fi
    
    log_info "=== Exécution des tests d'intégration ==="
    
    cd "${TESTS_DIR}/integration"
    
    # Configurer les variables d'environnement pour les tests
    export BASE_URL="$BASE_URL"
    export SPRING_PROFILES_ACTIVE="test"
    
    if mvn clean verify -Dspring.profiles.active=test; then
        log_success "✓ Tests d'intégration réussis"
    else
        log_error "✗ Tests d'intégration échoués"
        cd - > /dev/null
        return 1
    fi
    
    cd - > /dev/null
}

# Exécuter les tests de performance
run_performance_tests() {
    if [[ "$SKIP_PERFORMANCE_TESTS" == "true" ]]; then
        log_info "Tests de performance ignorés"
        return 0
    fi
    
    log_info "=== Exécution des tests de performance ==="
    
    cd "${TESTS_DIR}/performance"
    
    # Créer le répertoire de résultats
    local results_dir="results/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$results_dir"
    
    # Variables d'environnement pour K6
    export BASE_URL="$BASE_URL"
    export ENVIRONMENT="$ENVIRONMENT"
    
    # Test de performance du service d'authentification
    log_info "Test de performance - Service d'authentification..."
    if k6 run --duration "$PERFORMANCE_DURATION" \
             --out json="${results_dir}/auth-results.json" \
             --out influxdb=http://localhost:8086/k6 \
             auth-load-test.js; then
        log_success "✓ Test de performance auth réussi"
    else
        log_error "✗ Test de performance auth échoué"
    fi
    
    # Pause entre les tests
    sleep 30
    
    # Test de performance du service portefeuille
    log_info "Test de performance - Service portefeuille..."
    if k6 run --duration "$PERFORMANCE_DURATION" \
             --out json="${results_dir}/wallet-results.json" \
             --out influxdb=http://localhost:8086/k6 \
             wallet-load-test.js; then
        log_success "✓ Test de performance wallet réussi"
    else
        log_error "✗ Test de performance wallet échoué"
    fi
    
    # Générer un rapport de synthèse
    generate_performance_report "$results_dir"
    
    cd - > /dev/null
}

# Générer un rapport de performance
generate_performance_report() {
    local results_dir="$1"
    local report_file="${results_dir}/performance-report.html"
    
    log_info "Génération du rapport de performance..."
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Performance ISMAIL - $(date)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; }
        .metric { background: #e8f5e8; padding: 10px; margin: 5px 0; border-radius: 3px; }
        .error { background: #ffe8e8; }
        .warning { background: #fff8e8; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Rapport de Performance ISMAIL</h1>
        <p>Date: $(date)</p>
        <p>Environnement: $ENVIRONMENT</p>
        <p>URL de base: $BASE_URL</p>
        <p>Durée des tests: $PERFORMANCE_DURATION</p>
    </div>
    
    <div class="section">
        <h2>Résultats des Tests</h2>
        <div class="metric">
            <strong>Service d'Authentification:</strong>
            <ul>
                <li>Fichier de résultats: auth-results.json</li>
                <li>Métriques disponibles dans Grafana</li>
            </ul>
        </div>
        <div class="metric">
            <strong>Service Portefeuille:</strong>
            <ul>
                <li>Fichier de résultats: wallet-results.json</li>
                <li>Métriques disponibles dans Grafana</li>
            </ul>
        </div>
    </div>
    
    <div class="section">
        <h2>Analyse des Résultats</h2>
        <p>Pour analyser les résultats détaillés :</p>
        <ol>
            <li>Consultez les fichiers JSON dans ce répertoire</li>
            <li>Visualisez les métriques dans Grafana</li>
            <li>Vérifiez les seuils de performance définis</li>
        </ol>
    </div>
</body>
</html>
EOF
    
    log_success "Rapport généré: $report_file"
}

# Générer un rapport de synthèse global
generate_summary_report() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="${TESTS_DIR}/reports/test-summary-${timestamp}.md"
    
    mkdir -p "${TESTS_DIR}/reports"
    
    cat > "$report_file" << EOF
# Rapport de Tests ISMAIL - $(date)

## Configuration
- **Environnement**: $ENVIRONMENT
- **URL de base**: $BASE_URL
- **Durée tests de performance**: $PERFORMANCE_DURATION

## Résultats

### Tests Unitaires
$(if [[ "$SKIP_UNIT_TESTS" == "true" ]]; then echo "- ⏭️ Ignorés"; else echo "- ✅ Exécutés"; fi)

### Tests d'Intégration
$(if [[ "$SKIP_INTEGRATION_TESTS" == "true" ]]; then echo "- ⏭️ Ignorés"; else echo "- ✅ Exécutés"; fi)

### Tests de Performance
$(if [[ "$SKIP_PERFORMANCE_TESTS" == "true" ]]; then echo "- ⏭️ Ignorés"; else echo "- ✅ Exécutés"; fi)

## Recommandations

1. Consultez les rapports détaillés dans chaque répertoire de test
2. Vérifiez les métriques dans Grafana pour les tests de performance
3. Analysez la couverture de code avec JaCoCo
4. Surveillez les alertes dans AlertManager

## Fichiers Générés

- Rapports JaCoCo: \`services/*/target/site/jacoco/\`
- Résultats K6: \`tests/performance/results/\`
- Logs détaillés: \`tests/logs/\`

EOF
    
    log_success "Rapport de synthèse généré: $report_file"
}

# Fonction principale
main() {
    log_info "=== Exécution des Tests ISMAIL ==="
    log_info "Environnement: $ENVIRONMENT"
    log_info "URL de base: $BASE_URL"
    echo
    
    check_prerequisites
    test_connectivity
    
    local start_time=$(date +%s)
    local overall_success=true
    
    # Exécuter les différents types de tests
    if ! run_unit_tests; then
        overall_success=false
    fi
    
    if ! run_integration_tests; then
        overall_success=false
    fi
    
    if ! run_performance_tests; then
        overall_success=false
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Générer le rapport de synthèse
    generate_summary_report
    
    # Résumé final
    echo
    log_info "=== Résumé de l'Exécution ==="
    log_info "Durée totale: ${duration}s"
    
    if [[ "$overall_success" == "true" ]]; then
        log_success "🎉 Tous les tests ont réussi !"
        exit 0
    else
        log_error "❌ Certains tests ont échoué"
        exit 1
    fi
}

# Point d'entrée
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_arguments "$@"
    main
fi
