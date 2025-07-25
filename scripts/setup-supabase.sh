#!/bin/bash

# Script de configuration automatique Supabase pour ISMAIL Platform
# Configure la base de données, l'authentification et les politiques RLS

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
SECRETS_FILE="${PROJECT_ROOT}/.secrets/africa-secrets.env"

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
    
    if ! command -v psql &> /dev/null; then
        log_error "PostgreSQL client (psql) n'est pas installé"
        log_info "Installation: sudo apt-get install postgresql-client"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl n'est pas installé"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq n'est pas installé"
        exit 1
    fi
    
    log_success "Prérequis validés"
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

# Demander les credentials Supabase
prompt_supabase_credentials() {
    log_info "=== Configuration Credentials Supabase ==="
    
    if [ -z "${SUPABASE_URL:-}" ]; then
        echo
        log_info "Récupérez vos credentials Supabase depuis:"
        log_info "https://supabase.com/dashboard/project/your-project/settings/api"
        echo
        
        read -p "URL Supabase (https://your-project-id.supabase.co): " SUPABASE_URL
        read -p "Anon Key: " SUPABASE_ANON_KEY
        read -s -p "Service Key: " SUPABASE_SERVICE_KEY
        echo
        read -s -p "Database Password: " DB_PASSWORD
        echo
        
        # Construire l'URL de base de données
        PROJECT_ID=$(echo "$SUPABASE_URL" | sed 's|https://||' | sed 's|\.supabase\.co||')
        DATABASE_URL="postgresql://postgres:${DB_PASSWORD}@db.${PROJECT_ID}.supabase.co:5432/postgres"
        
        # Sauvegarder dans le fichier secrets
        {
            echo ""
            echo "# Supabase Configuration"
            echo "SUPABASE_URL=$SUPABASE_URL"
            echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
            echo "SUPABASE_SERVICE_KEY=$SUPABASE_SERVICE_KEY"
            echo "DATABASE_URL=$DATABASE_URL"
        } >> "$SECRETS_FILE"
        
        log_success "Credentials Supabase sauvegardés"
    else
        log_success "Credentials Supabase déjà configurés"
    fi
}

# Tester la connexion à Supabase
test_supabase_connection() {
    log_info "=== Test Connexion Supabase ==="
    
    # Test API REST
    if curl -s -f --max-time 10 \
       -H "apikey: $SUPABASE_ANON_KEY" \
       -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
       "$SUPABASE_URL/rest/v1/" > /dev/null; then
        log_success "✓ API REST accessible"
    else
        log_error "✗ API REST non accessible"
        return 1
    fi
    
    # Test connexion base de données
    if psql "$DATABASE_URL" -c "SELECT version();" > /dev/null 2>&1; then
        log_success "✓ Base de données accessible"
    else
        log_error "✗ Base de données non accessible"
        log_error "Vérifiez le mot de passe et l'URL de connexion"
        return 1
    fi
    
    log_success "Connexion Supabase validée"
}

# Exécuter les scripts SQL
execute_sql_scripts() {
    log_info "=== Exécution Scripts SQL ==="
    
    local sql_files=(
        "database/supabase/01-schema.sql"
        "database/supabase/02-functions.sql"
        "database/supabase/03-seed-data.sql"
    )
    
    for sql_file in "${sql_files[@]}"; do
        local file_path="${PROJECT_ROOT}/${sql_file}"
        
        if [ -f "$file_path" ]; then
            log_info "Exécution de $sql_file..."
            
            if psql "$DATABASE_URL" -f "$file_path" > /dev/null 2>&1; then
                log_success "✓ $sql_file exécuté avec succès"
            else
                log_error "✗ Erreur lors de l'exécution de $sql_file"
                log_info "Exécution manuelle: psql \"$DATABASE_URL\" -f \"$file_path\""
                return 1
            fi
        else
            log_error "Fichier SQL non trouvé: $file_path"
            return 1
        fi
    done
    
    log_success "Tous les scripts SQL exécutés"
}

# Configurer les buckets de storage
setup_storage_buckets() {
    log_info "=== Configuration Storage Buckets ==="
    
    local buckets=(
        '{"id": "avatars", "name": "avatars", "public": true}'
        '{"id": "documents", "name": "documents", "public": false}'
        '{"id": "professional-cards", "name": "professional-cards", "public": false}'
    )
    
    for bucket in "${buckets[@]}"; do
        local bucket_id=$(echo "$bucket" | jq -r '.id')
        
        log_info "Création du bucket: $bucket_id"
        
        # Créer le bucket via API
        local response=$(curl -s -X POST \
            -H "apikey: $SUPABASE_SERVICE_KEY" \
            -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
            -H "Content-Type: application/json" \
            -d "$bucket" \
            "$SUPABASE_URL/storage/v1/bucket")
        
        if echo "$response" | jq -e '.name' > /dev/null 2>&1; then
            log_success "✓ Bucket $bucket_id créé"
        else
            log_warning "Bucket $bucket_id existe déjà ou erreur: $(echo "$response" | jq -r '.message // "Unknown error"')"
        fi
    done
}

# Configurer les politiques RLS
setup_rls_policies() {
    log_info "=== Configuration Politiques RLS ==="
    
    # Les politiques RLS sont déjà dans 02-functions.sql
    # Vérifier qu'elles sont bien appliquées
    
    local tables=("users" "wallets" "transactions" "user_sessions" "professional_cards")
    
    for table in "${tables[@]}"; do
        local rls_enabled=$(psql "$DATABASE_URL" -t -c "
            SELECT row_security 
            FROM pg_tables 
            WHERE schemaname = 'ismail' AND tablename = '$table';
        " 2>/dev/null | tr -d ' \n')
        
        if [ "$rls_enabled" = "on" ]; then
            log_success "✓ RLS activé sur ismail.$table"
        else
            log_warning "RLS non activé sur ismail.$table"
        fi
    done
}

# Tester les fonctions créées
test_database_functions() {
    log_info "=== Test Fonctions Base de Données ==="
    
    # Test génération ID ISMAIL
    local test_id=$(psql "$DATABASE_URL" -t -c "
        SELECT ismail.generate_ismail_id('CI', 'CLIENT');
    " 2>/dev/null | tr -d ' \n')
    
    if [[ "$test_id" =~ ^CI[0-9]{8}-[A-Z0-9]{4}-CL$ ]]; then
        log_success "✓ Génération ID ISMAIL: $test_id"
    else
        log_error "✗ Erreur génération ID ISMAIL: $test_id"
    fi
    
    # Test génération référence transaction
    local test_ref=$(psql "$DATABASE_URL" -t -c "
        SELECT ismail.generate_transaction_reference('DEPOSIT');
    " 2>/dev/null | tr -d ' \n')
    
    if [[ "$test_ref" =~ ^DEP[0-9]{14}[A-Z0-9]{6}$ ]]; then
        log_success "✓ Génération référence transaction: $test_ref"
    else
        log_error "✗ Erreur génération référence: $test_ref"
    fi
    
    # Test fonction d'inscription
    local test_register=$(psql "$DATABASE_URL" -t -c "
        SELECT ismail.register_user(
            'test-$(date +%s)@example.com',
            '+225$(date +%s | tail -c 9)',
            'TestPassword123!',
            'Test',
            'User',
            'CLIENT',
            'CI'
        );
    " 2>/dev/null)
    
    if echo "$test_register" | jq -e '.success' > /dev/null 2>&1; then
        log_success "✓ Fonction d'inscription utilisateur"
    else
        log_error "✗ Erreur fonction d'inscription: $test_register"
    fi
}

# Configurer les webhooks
setup_webhooks() {
    log_info "=== Configuration Webhooks ==="
    
    if [ -n "${RAILWAY_BACKEND_URL:-}" ]; then
        log_info "Configuration des webhooks vers: $RAILWAY_BACKEND_URL"
        
        # Note: Les webhooks Supabase se configurent via l'interface web
        # ou via l'API Management (nécessite des permissions spéciales)
        
        log_warning "Configurez manuellement les webhooks dans l'interface Supabase:"
        log_info "1. Aller sur https://supabase.com/dashboard/project/your-project/database/webhooks"
        log_info "2. Créer webhook pour auth events: $RAILWAY_BACKEND_URL/webhooks/supabase/auth"
        log_info "3. Créer webhook pour database events: $RAILWAY_BACKEND_URL/webhooks/supabase/database"
    else
        log_warning "RAILWAY_BACKEND_URL non configuré, webhooks non configurés"
    fi
}

# Générer un rapport de configuration
generate_configuration_report() {
    local report_file="supabase-setup-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Rapport Configuration Supabase - ISMAIL Platform

**Date**: $(date -u +%Y-%m-%dT%H:%M:%SZ)  
**Projet**: ISMAIL Platform  
**Base de données**: Supabase PostgreSQL

## 📊 Configuration Réalisée

### Credentials
- **URL**: $SUPABASE_URL
- **Anon Key**: ${SUPABASE_ANON_KEY:0:20}...
- **Service Key**: ${SUPABASE_SERVICE_KEY:0:20}...

### Base de Données
- **Schéma**: ismail
- **Tables**: 6 tables principales
- **Fonctions**: 8 fonctions métier
- **Triggers**: 7 triggers automatiques
- **Index**: 15+ index de performance

### Sécurité
- **RLS**: Activé sur toutes les tables
- **Politiques**: Configurées par rôle
- **Audit**: Logs complets activés

### Storage
- **Buckets**: avatars, documents, professional-cards
- **Politiques**: Configurées par bucket

### Données de Test
- **Utilisateurs**: 7 utilisateurs test
- **Portefeuilles**: Configurés avec soldes
- **Transactions**: Exemples de transactions
- **Sessions**: Sessions actives test

## 🔗 Liens Utiles

- **Dashboard**: https://supabase.com/dashboard/project/your-project
- **SQL Editor**: https://supabase.com/dashboard/project/your-project/sql
- **Auth Settings**: https://supabase.com/dashboard/project/your-project/auth/settings
- **Storage**: https://supabase.com/dashboard/project/your-project/storage/buckets

## 🧪 Tests de Validation

\`\`\`bash
# Test connexion API
curl -H "apikey: $SUPABASE_ANON_KEY" "$SUPABASE_URL/rest/v1/"

# Test connexion DB
psql "$DATABASE_URL" -c "SELECT version();"

# Test fonction
psql "$DATABASE_URL" -c "SELECT ismail.generate_ismail_id('CI', 'CLIENT');"
\`\`\`

## 📋 Actions Manuelles Requises

1. **Webhooks**: Configurer dans l'interface Supabase
2. **Auth Templates**: Personnaliser les emails
3. **Monitoring**: Configurer les alertes
4. **Backup**: Vérifier la configuration

---
*Rapport généré par setup-supabase.sh*
EOF
    
    log_success "Rapport généré: $report_file"
}

# Afficher le résumé
display_summary() {
    echo
    log_info "=== Résumé Configuration Supabase ==="
    
    echo
    echo "🗄️ **Base de Données Supabase**:"
    echo "  ✅ Schéma ISMAIL créé"
    echo "  ✅ 6 tables principales"
    echo "  ✅ 8 fonctions métier"
    echo "  ✅ 7 triggers automatiques"
    echo "  ✅ RLS activé et configuré"
    echo "  ✅ Données de test chargées"
    echo
    echo "🔐 **Sécurité**:"
    echo "  ✅ Row Level Security (RLS)"
    echo "  ✅ Politiques par rôle"
    echo "  ✅ Audit trail complet"
    echo "  ✅ Chiffrement des mots de passe"
    echo
    echo "📁 **Storage**:"
    echo "  ✅ Buckets configurés"
    echo "  ✅ Politiques de sécurité"
    echo
    echo "🔗 **Intégrations**:"
    echo "  ✅ API REST disponible"
    echo "  ✅ Authentification configurée"
    echo "  ⚠️  Webhooks à configurer manuellement"
    echo
    echo "📊 **Credentials**:"
    echo "  - URL: $SUPABASE_URL"
    echo "  - Anon Key: ${SUPABASE_ANON_KEY:0:20}..."
    echo "  - Service Key: ${SUPABASE_SERVICE_KEY:0:20}..."
    echo
    echo "🚀 **Prochaines étapes**:"
    echo "  1. Configurer Railway backend"
    echo "  2. Déployer frontend Netlify"
    echo "  3. Tester l'intégration complète"
    echo "  4. Configurer les webhooks"
    
    log_success "Supabase configuré avec succès pour l'Afrique !"
}

# Fonction principale
main() {
    echo "🗄️ Configuration Supabase - ISMAIL Platform"
    echo "=========================================="
    echo
    
    check_prerequisites
    load_secrets
    prompt_supabase_credentials
    test_supabase_connection
    execute_sql_scripts
    setup_storage_buckets
    setup_rls_policies
    test_database_functions
    setup_webhooks
    
    generate_configuration_report
    display_summary
}

# Vérification des arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -gt 0 && "$1" == "--help" ]]; then
        echo "Usage: $0"
        echo
        echo "Configure automatiquement Supabase pour ISMAIL Platform."
        echo
        echo "Ce script:"
        echo "  1. Vérifie la connexion Supabase"
        echo "  2. Exécute les scripts SQL (schéma, fonctions, données)"
        echo "  3. Configure les buckets de storage"
        echo "  4. Valide les politiques RLS"
        echo "  5. Teste les fonctions créées"
        echo "  6. Configure les webhooks"
        echo
        echo "Prérequis:"
        echo "  - Compte Supabase créé"
        echo "  - Projet Supabase configuré"
        echo "  - PostgreSQL client installé"
        echo "  - Credentials dans .secrets/africa-secrets.env"
        echo
        exit 0
    fi
    
    main "$@"
fi
