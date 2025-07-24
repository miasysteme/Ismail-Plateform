#!/bin/bash

# Script de déploiement des bases de données - Plateforme ISMAIL
# Déploie PostgreSQL, MongoDB et Redis avec configuration complète

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DATABASE_DIR="${PROJECT_ROOT}/database"

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

# Vérification des prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier les outils requis
    local tools=("kubectl" "helm" "psql" "mongosh")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_warning "$tool n'est pas installé (optionnel selon la base)"
        fi
    done
    
    # Vérifier la connexion Kubernetes
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Impossible de se connecter au cluster Kubernetes"
        exit 1
    fi
    
    # Vérifier les variables d'environnement
    local required_vars=("ENVIRONMENT")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Variable d'environnement $var non définie"
            exit 1
        fi
    done
    
    log_success "Prérequis validés"
}

# Déploiement PostgreSQL (RDS déjà créé par Terraform)
setup_postgresql() {
    log_info "Configuration PostgreSQL..."
    
    # Récupérer les informations RDS depuis Terraform
    cd "${PROJECT_ROOT}/infrastructure/terraform"
    
    if ! terraform output postgres_endpoint &> /dev/null; then
        log_error "Endpoint PostgreSQL non trouvé. Exécutez d'abord le déploiement Terraform."
        exit 1
    fi
    
    POSTGRES_HOST=$(terraform output -raw postgres_endpoint)
    POSTGRES_PASSWORD=$(terraform output -raw postgres_password)
    
    log_info "Endpoint PostgreSQL: $POSTGRES_HOST"
    
    # Créer le secret Kubernetes pour PostgreSQL
    kubectl create secret generic postgres-credentials \
        --from-literal=host="$POSTGRES_HOST" \
        --from-literal=username="postgres" \
        --from-literal=password="$POSTGRES_PASSWORD" \
        --namespace=ismail-core \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Exécuter le script d'initialisation
    log_info "Exécution du script d'initialisation PostgreSQL..."
    
    export PGPASSWORD="$POSTGRES_PASSWORD"
    
    if psql -h "$POSTGRES_HOST" -U postgres -d postgres -f "${DATABASE_DIR}/postgresql/init-database.sql"; then
        log_success "Base PostgreSQL initialisée"
    else
        log_error "Erreur lors de l'initialisation PostgreSQL"
        return 1
    fi
    
    # Exécuter les migrations
    log_info "Exécution des migrations PostgreSQL..."
    
    for migration in "${DATABASE_DIR}/postgresql/migrations"/*.sql; do
        if [[ -f "$migration" ]]; then
            log_info "Exécution de $(basename "$migration")..."
            if psql -h "$POSTGRES_HOST" -U postgres -d ismail_main -f "$migration"; then
                log_success "Migration $(basename "$migration") terminée"
            else
                log_error "Erreur dans la migration $(basename "$migration")"
                return 1
            fi
        fi
    done
    
    unset PGPASSWORD
    log_success "PostgreSQL configuré avec succès"
}

# Déploiement MongoDB
setup_mongodb() {
    log_info "Déploiement MongoDB..."
    
    # Ajouter le repository Helm Bitnami
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    # Créer le namespace si nécessaire
    kubectl create namespace ismail-data --dry-run=client -o yaml | kubectl apply -f -
    
    # Déployer MongoDB avec Helm
    log_info "Installation MongoDB via Helm..."
    
    helm upgrade --install mongodb bitnami/mongodb \
        --namespace ismail-data \
        --values "${PROJECT_ROOT}/infrastructure/helm/mongodb/values.yaml" \
        --wait --timeout=600s
    
    # Attendre que MongoDB soit prêt
    log_info "Attente que MongoDB soit prêt..."
    kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=mongodb -n ismail-data --timeout=300s
    
    # Récupérer le mot de passe root
    MONGODB_ROOT_PASSWORD=$(kubectl get secret mongodb -n ismail-data -o jsonpath="{.data.mongodb-root-password}" | base64 -d)
    
    # Exécuter le script d'initialisation
    log_info "Initialisation des collections MongoDB..."
    
    # Port-forward temporaire pour l'initialisation
    kubectl port-forward -n ismail-data svc/mongodb 27017:27017 &
    PORT_FORWARD_PID=$!
    
    # Attendre que le port-forward soit actif
    sleep 10
    
    # Exécuter le script d'initialisation
    if mongosh "mongodb://admin:${MONGODB_ROOT_PASSWORD}@localhost:27017/admin" \
        --file "${DATABASE_DIR}/mongodb/init-collections.js"; then
        log_success "MongoDB initialisé avec succès"
    else
        log_error "Erreur lors de l'initialisation MongoDB"
        kill $PORT_FORWARD_PID 2>/dev/null || true
        return 1
    fi
    
    # Arrêter le port-forward
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
    # Créer le secret pour l'application
    kubectl create secret generic mongodb-credentials \
        --from-literal=host="mongodb.ismail-data.svc.cluster.local" \
        --from-literal=port="27017" \
        --from-literal=username="ismail_app" \
        --from-literal=password="IsmaIl2024!App#MongoDB" \
        --from-literal=database="ismail_main" \
        --namespace=ismail-core \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "MongoDB déployé avec succès"
}

# Configuration Redis (ElastiCache déjà créé par Terraform)
setup_redis() {
    log_info "Configuration Redis..."
    
    # Récupérer les informations Redis depuis Terraform
    cd "${PROJECT_ROOT}/infrastructure/terraform"
    
    if ! terraform output redis_endpoint &> /dev/null; then
        log_error "Endpoint Redis non trouvé. Exécutez d'abord le déploiement Terraform."
        exit 1
    fi
    
    REDIS_HOST=$(terraform output -raw redis_endpoint)
    REDIS_PASSWORD=$(terraform output -raw redis_auth_token)
    
    log_info "Endpoint Redis: $REDIS_HOST"
    
    # Créer le secret Kubernetes pour Redis
    kubectl create secret generic redis-credentials \
        --from-literal=host="$REDIS_HOST" \
        --from-literal=port="6379" \
        --from-literal=password="$REDIS_PASSWORD" \
        --namespace=ismail-core \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Tester la connexion Redis
    log_info "Test de connexion Redis..."
    
    # Créer un pod temporaire pour tester Redis
    kubectl run redis-test --image=redis:7-alpine --rm -i --restart=Never \
        --namespace=ismail-core \
        --command -- redis-cli -h "$REDIS_HOST" -p 6379 -a "$REDIS_PASSWORD" ping
    
    if [[ $? -eq 0 ]]; then
        log_success "Connexion Redis validée"
    else
        log_error "Impossible de se connecter à Redis"
        return 1
    fi
    
    log_success "Redis configuré avec succès"
}

# Initialisation des données de test
seed_test_data() {
    if [[ "$ENVIRONMENT" != "prod" ]]; then
        log_info "Insertion des données de test..."
        
        # Données de test PostgreSQL
        cd "${PROJECT_ROOT}/infrastructure/terraform"
        POSTGRES_HOST=$(terraform output -raw postgres_endpoint)
        POSTGRES_PASSWORD=$(terraform output -raw postgres_password)
        
        export PGPASSWORD="$POSTGRES_PASSWORD"
        
        # Insérer des utilisateurs de test
        psql -h "$POSTGRES_HOST" -U postgres -d ismail_main -c "
        INSERT INTO core.users (email, phone, password_hash, first_name, last_name, profile_type, status, kyc_status) VALUES
        ('admin@ismail-platform.com', '+2250123456789', '\$2a\$12\$dummy.hash.for.testing', 'Admin', 'ISMAIL', 'ADMIN', 'ACTIVE', 'VERIFIED'),
        ('commercial@ismail-platform.com', '+2250123456790', '\$2a\$12\$dummy.hash.for.testing', 'Commercial', 'Manager', 'COMMERCIAL', 'ACTIVE', 'VERIFIED'),
        ('partner@ismail-platform.com', '+2250123456791', '\$2a\$12\$dummy.hash.for.testing', 'Partner', 'Test', 'PARTNER', 'ACTIVE', 'VERIFIED'),
        ('client@ismail-platform.com', '+2250123456792', '\$2a\$12\$dummy.hash.for.testing', 'Client', 'Test', 'CLIENT', 'ACTIVE', 'VERIFIED')
        ON CONFLICT (email) DO NOTHING;
        "
        
        # Créer des portefeuilles pour les utilisateurs de test
        psql -h "$POSTGRES_HOST" -U postgres -d ismail_main -c "
        INSERT INTO core.wallets (user_id, balance) 
        SELECT id, 1000.00 FROM core.users WHERE email LIKE '%@ismail-platform.com'
        ON CONFLICT (user_id, currency) DO NOTHING;
        "
        
        unset PGPASSWORD
        
        log_success "Données de test insérées"
    else
        log_info "Environnement de production - pas de données de test"
    fi
}

# Vérification du déploiement
verify_deployment() {
    log_info "Vérification du déploiement des bases de données..."
    
    # Vérifier PostgreSQL
    log_info "Vérification PostgreSQL..."
    if kubectl get secret postgres-credentials -n ismail-core &> /dev/null; then
        log_success "✓ Secret PostgreSQL créé"
    else
        log_error "✗ Secret PostgreSQL manquant"
    fi
    
    # Vérifier MongoDB
    log_info "Vérification MongoDB..."
    if kubectl get pods -n ismail-data -l app.kubernetes.io/name=mongodb | grep -q Running; then
        log_success "✓ MongoDB en cours d'exécution"
    else
        log_error "✗ MongoDB non disponible"
    fi
    
    if kubectl get secret mongodb-credentials -n ismail-core &> /dev/null; then
        log_success "✓ Secret MongoDB créé"
    else
        log_error "✗ Secret MongoDB manquant"
    fi
    
    # Vérifier Redis
    log_info "Vérification Redis..."
    if kubectl get secret redis-credentials -n ismail-core &> /dev/null; then
        log_success "✓ Secret Redis créé"
    else
        log_error "✗ Secret Redis manquant"
    fi
    
    # Afficher les informations de connexion
    log_info "=== Informations de connexion ==="
    echo "PostgreSQL:"
    echo "  Host: $(kubectl get secret postgres-credentials -n ismail-core -o jsonpath='{.data.host}' | base64 -d)"
    echo "  Database: ismail_main"
    echo
    echo "MongoDB:"
    echo "  Host: mongodb.ismail-data.svc.cluster.local:27017"
    echo "  Database: ismail_main"
    echo
    echo "Redis:"
    echo "  Host: $(kubectl get secret redis-credentials -n ismail-core -o jsonpath='{.data.host}' | base64 -d):6379"
    echo
    
    log_success "Vérification terminée"
}

# Nettoyage en cas d'erreur
cleanup_on_error() {
    log_error "Erreur détectée. Nettoyage en cours..."
    
    # Arrêter les port-forwards en cours
    pkill -f "kubectl port-forward" 2>/dev/null || true
    
    # Supprimer les pods temporaires
    kubectl delete pod redis-test -n ismail-core 2>/dev/null || true
    
    log_error "Consultez les logs pour plus de détails"
}

# Configuration du trap pour le nettoyage
trap cleanup_on_error ERR

# Fonction principale
main() {
    log_info "=== Déploiement Bases de Données ISMAIL ==="
    log_info "Environnement: $ENVIRONMENT"
    echo
    
    check_prerequisites
    setup_postgresql
    setup_mongodb
    setup_redis
    seed_test_data
    verify_deployment
    
    log_success "=== Déploiement des bases de données terminé ==="
    log_info "Toutes les bases de données sont prêtes pour les services ISMAIL"
}

# Vérification des arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <environment>"
    echo "Environments: dev, staging, prod"
    echo
    echo "Variables d'environnement requises:"
    echo "  ENVIRONMENT - Environnement de déploiement"
    echo
    echo "Exemple:"
    echo "  export ENVIRONMENT=dev"
    echo "  $0 dev"
    exit 1
fi

# Configuration des variables
export ENVIRONMENT="$1"

# Validation de l'environnement
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Environnement invalide: $ENVIRONMENT"
    exit 1
fi

# Exécution du script principal
main "$@"
