#!/bin/bash

# Script de test de connexion Supabase pour ISMAIL Platform
# Teste la connectivité API et base de données

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="${SCRIPT_DIR}/../.secrets/africa-secrets.env"

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

# Charger les secrets
load_secrets() {
    if [ -f "$SECRETS_FILE" ]; then
        source "$SECRETS_FILE"
        log_success "Secrets chargés depuis $SECRETS_FILE"
    else
        log_error "Fichier secrets non trouvé: $SECRETS_FILE"
        exit 1
    fi
}

# Tester la connexion API Supabase
test_api_connection() {
    log_info "=== Test Connexion API Supabase ==="
    
    # Test API REST
    log_info "Test de l'API REST..."
    
    local response=$(curl -s -w "%{http_code}" \
        -H "apikey: $SUPABASE_ANON_KEY" \
        -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
        "$SUPABASE_URL/rest/v1/" \
        -o /tmp/supabase_test.json)
    
    if [ "$response" = "200" ]; then
        log_success "✓ API REST accessible"
        log_info "Réponse: $(cat /tmp/supabase_test.json | head -c 100)..."
    else
        log_error "✗ API REST non accessible (HTTP $response)"
        return 1
    fi
    
    # Test Auth API
    log_info "Test de l'API Auth..."
    
    local auth_response=$(curl -s -w "%{http_code}" \
        -H "apikey: $SUPABASE_ANON_KEY" \
        "$SUPABASE_URL/auth/v1/settings" \
        -o /tmp/supabase_auth.json)
    
    if [ "$auth_response" = "200" ]; then
        log_success "✓ API Auth accessible"
    else
        log_error "✗ API Auth non accessible (HTTP $auth_response)"
        return 1
    fi
    
    rm -f /tmp/supabase_test.json /tmp/supabase_auth.json
}

# Tester la connexion base de données
test_database_connection() {
    log_info "=== Test Connexion Base de Données ==="
    
    # Vérifier si psql est installé
    if ! command -v psql &> /dev/null; then
        log_warning "PostgreSQL client (psql) non installé"
        log_info "Installation: sudo apt-get install postgresql-client"
        return 1
    fi
    
    # Test de connexion
    log_info "Test de connexion à la base de données..."
    
    if psql "$DATABASE_URL" -c "SELECT version();" > /tmp/db_version.txt 2>&1; then
        log_success "✓ Base de données accessible"
        local version=$(cat /tmp/db_version.txt | grep PostgreSQL | head -1)
        log_info "Version: $version"
    else
        log_error "✗ Base de données non accessible"
        log_error "Erreur: $(cat /tmp/db_version.txt)"
        return 1
    fi
    
    # Test des permissions
    log_info "Test des permissions..."
    
    if psql "$DATABASE_URL" -c "SELECT current_user, current_database();" > /tmp/db_perms.txt 2>&1; then
        log_success "✓ Permissions OK"
        log_info "Utilisateur: $(cat /tmp/db_perms.txt | grep postgres | awk '{print $1}')"
    else
        log_error "✗ Problème de permissions"
        return 1
    fi
    
    rm -f /tmp/db_version.txt /tmp/db_perms.txt
}

# Tester les schémas existants
test_existing_schemas() {
    log_info "=== Vérification Schémas Existants ==="
    
    # Lister les schémas
    local schemas=$(psql "$DATABASE_URL" -t -c "
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
        ORDER BY schema_name;
    " 2>/dev/null | tr -d ' ')
    
    log_info "Schémas existants:"
    echo "$schemas" | while read schema; do
        if [ -n "$schema" ]; then
            echo "  - $schema"
        fi
    done
    
    # Vérifier si le schéma ismail existe
    if echo "$schemas" | grep -q "ismail"; then
        log_success "✓ Schéma 'ismail' existe déjà"
        
        # Lister les tables du schéma ismail
        local tables=$(psql "$DATABASE_URL" -t -c "
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'ismail'
            ORDER BY table_name;
        " 2>/dev/null | tr -d ' ')
        
        if [ -n "$tables" ]; then
            log_info "Tables dans le schéma ismail:"
            echo "$tables" | while read table; do
                if [ -n "$table" ]; then
                    echo "  - $table"
                fi
            done
        else
            log_warning "Schéma 'ismail' existe mais aucune table trouvée"
        fi
    else
        log_info "Schéma 'ismail' n'existe pas encore"
    fi
}

# Afficher les informations de configuration
display_configuration() {
    log_info "=== Configuration Supabase ==="
    
    echo
    echo "🔗 **URLs**:"
    echo "  - Projet: $SUPABASE_URL"
    echo "  - Dashboard: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_ID"
    echo "  - SQL Editor: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_ID/sql"
    echo
    echo "🔑 **Credentials**:"
    echo "  - Project ID: $SUPABASE_PROJECT_ID"
    echo "  - Anon Key: ${SUPABASE_ANON_KEY:0:20}..."
    echo "  - Service Key: ${SUPABASE_SERVICE_KEY:0:20}..."
    echo
    echo "🗄️ **Base de Données**:"
    echo "  - Host: db.$SUPABASE_PROJECT_ID.supabase.co"
    echo "  - Port: 5432"
    echo "  - Database: postgres"
    echo "  - User: postgres"
    echo
}

# Fonction principale
main() {
    echo "🧪 Test Connexion Supabase - ISMAIL Platform"
    echo "==========================================="
    echo
    
    load_secrets
    display_configuration
    test_api_connection
    test_database_connection
    test_existing_schemas
    
    echo
    log_success "🎉 Tests de connexion Supabase terminés !"
    echo
    echo "📋 **Prochaines étapes**:"
    echo "  1. Si les tests sont OK, exécuter: ./scripts/setup-supabase.sh"
    echo "  2. Ou configurer manuellement via l'interface Supabase"
    echo "  3. Puis configurer Railway backend"
    echo
}

# Vérification des arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -gt 0 && "$1" == "--help" ]]; then
        echo "Usage: $0"
        echo
        echo "Teste la connexion à Supabase pour ISMAIL Platform."
        echo
        echo "Ce script teste:"
        echo "  - Connexion API REST"
        echo "  - Connexion API Auth"
        echo "  - Connexion base de données PostgreSQL"
        echo "  - Schémas existants"
        echo
        echo "Prérequis:"
        echo "  - Credentials Supabase dans .secrets/africa-secrets.env"
        echo "  - curl installé"
        echo "  - psql installé (optionnel)"
        echo
        exit 0
    fi
    
    main "$@"
fi
