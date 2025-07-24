#!/bin/bash

# Script de configuration Kong API Gateway - Plateforme ISMAIL
# Déploie et configure Kong avec tous les plugins et routes

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
KONG_CONFIG_DIR="${PROJECT_ROOT}/infrastructure/kong"

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
    local tools=("kubectl" "helm" "curl" "jq")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool n'est pas installé"
            exit 1
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

# Installation Kong avec Helm
install_kong() {
    log_info "Installation de Kong API Gateway..."
    
    # Créer le namespace si nécessaire
    kubectl create namespace ismail-ingress --dry-run=client -o yaml | kubectl apply -f -
    
    # Ajouter le repository Helm Kong
    helm repo add kong https://charts.konghq.com
    helm repo update
    
    # Créer les secrets nécessaires
    create_kong_secrets
    
    # Installer Kong avec Helm
    log_info "Déploiement Kong via Helm..."
    
    helm upgrade --install kong kong/kong \
        --namespace ismail-ingress \
        --values "${PROJECT_ROOT}/infrastructure/helm/kong/values.yaml" \
        --wait --timeout=600s
    
    # Attendre que Kong soit prêt
    log_info "Attente que Kong soit prêt..."
    kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=kong -n ismail-ingress --timeout=300s
    
    log_success "Kong installé avec succès"
}

# Créer les secrets Kong
create_kong_secrets() {
    log_info "Création des secrets Kong..."
    
    # Secret pour la base de données Kong
    if ! kubectl get secret kong-postgres-secret -n ismail-ingress &> /dev/null; then
        # Récupérer les informations PostgreSQL depuis Terraform
        cd "${PROJECT_ROOT}/infrastructure/terraform"
        POSTGRES_HOST=$(terraform output -raw postgres_endpoint 2>/dev/null || echo "localhost")
        POSTGRES_PASSWORD=$(terraform output -raw postgres_password 2>/dev/null || openssl rand -base64 32)
        
        kubectl create secret generic kong-postgres-secret \
            --from-literal=host="$POSTGRES_HOST" \
            --from-literal=username="kong_user" \
            --from-literal=password="Kong2024!Secure#Gateway" \
            --from-literal=database="kong" \
            --namespace=ismail-ingress
        
        log_success "Secret PostgreSQL Kong créé"
    else
        log_info "Secret PostgreSQL Kong existe déjà"
    fi
    
    # Secret pour Redis
    if ! kubectl get secret kong-redis-secret -n ismail-ingress &> /dev/null; then
        cd "${PROJECT_ROOT}/infrastructure/terraform"
        REDIS_HOST=$(terraform output -raw redis_endpoint 2>/dev/null || echo "localhost")
        REDIS_PASSWORD=$(terraform output -raw redis_auth_token 2>/dev/null || openssl rand -base64 32)
        
        kubectl create secret generic kong-redis-secret \
            --from-literal=host="$REDIS_HOST" \
            --from-literal=port="6379" \
            --from-literal=password="$REDIS_PASSWORD" \
            --namespace=ismail-ingress
        
        log_success "Secret Redis Kong créé"
    else
        log_info "Secret Redis Kong existe déjà"
    fi
    
    # Certificat SSL auto-signé pour développement
    if [[ "$ENVIRONMENT" != "prod" ]] && ! kubectl get secret kong-ssl-cert -n ismail-ingress &> /dev/null; then
        log_info "Génération du certificat SSL auto-signé..."
        
        # Générer le certificat auto-signé
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /tmp/kong-tls.key -out /tmp/kong-tls.crt \
            -subj "/CN=*.ismail-platform.com/O=ISMAIL/C=CI" \
            -addext "subjectAltName=DNS:*.ismail-platform.com,DNS:ismail-platform.com,DNS:api.ismail-platform.com"
        
        kubectl create secret tls kong-ssl-cert \
            --cert=/tmp/kong-tls.crt --key=/tmp/kong-tls.key \
            --namespace=ismail-ingress
        
        rm -f /tmp/kong-tls.key /tmp/kong-tls.crt
        
        log_success "Certificat SSL auto-signé créé"
    fi
}

# Configuration Kong via Admin API
configure_kong() {
    log_info "Configuration de Kong via Admin API..."
    
    # Attendre que Kong Admin API soit disponible
    wait_for_kong_admin
    
    # Appliquer la configuration déclarative
    apply_kong_config
    
    # Configurer les plugins spécifiques
    configure_kong_plugins
    
    # Créer les consumers et clés JWT
    create_kong_consumers
    
    log_success "Kong configuré avec succès"
}

# Attendre que Kong Admin API soit disponible
wait_for_kong_admin() {
    log_info "Attente de l'API Admin Kong..."
    
    # Port-forward vers Kong Admin API
    kubectl port-forward -n ismail-ingress svc/kong-kong-admin 8001:8001 &
    KONG_PORT_FORWARD_PID=$!
    
    # Attendre que le port-forward soit actif
    sleep 10
    
    # Tester la connexion à l'API Admin
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s http://localhost:8001/status &> /dev/null; then
            log_success "Kong Admin API disponible"
            return 0
        fi
        
        log_info "Tentative $attempt/$max_attempts - Kong Admin API non disponible"
        sleep 10
        ((attempt++))
    done
    
    log_error "Kong Admin API non disponible après $max_attempts tentatives"
    kill $KONG_PORT_FORWARD_PID 2>/dev/null || true
    exit 1
}

# Appliquer la configuration déclarative Kong
apply_kong_config() {
    log_info "Application de la configuration déclarative..."
    
    # Vérifier que le fichier de configuration existe
    if [[ ! -f "${KONG_CONFIG_DIR}/kong-config.yaml" ]]; then
        log_error "Fichier de configuration Kong non trouvé: ${KONG_CONFIG_DIR}/kong-config.yaml"
        return 1
    fi
    
    # Appliquer la configuration via l'API Admin
    if curl -s -X POST http://localhost:8001/config \
        -F config=@"${KONG_CONFIG_DIR}/kong-config.yaml" | jq -r '.message' | grep -q "success"; then
        log_success "Configuration déclarative appliquée"
    else
        log_error "Erreur lors de l'application de la configuration"
        return 1
    fi
}

# Configurer les plugins spécifiques
configure_kong_plugins() {
    log_info "Configuration des plugins Kong..."
    
    # Plugin de transformation des headers
    curl -s -X POST http://localhost:8001/plugins \
        -d "name=request-transformer" \
        -d "config.add.headers=X-Forwarded-Proto:https" \
        -d "config.add.headers=X-Real-IP:\$remote_addr" \
        -d "config.add.headers=X-Request-ID:\$request_id" > /dev/null
    
    # Plugin de réponse personnalisée pour les erreurs
    curl -s -X POST http://localhost:8001/plugins \
        -d "name=response-transformer" \
        -d "config.add.headers=X-Kong-Response-Latency:\$upstream_response_time" \
        -d "config.add.headers=X-Kong-Proxy-Latency:\$kong_proxy_latency" > /dev/null
    
    # Plugin de limitation IP pour sécurité
    curl -s -X POST http://localhost:8001/plugins \
        -d "name=ip-restriction" \
        -d "config.deny=192.168.1.0/24" > /dev/null
    
    log_success "Plugins Kong configurés"
}

# Créer les consumers et clés JWT
create_kong_consumers() {
    log_info "Création des consumers Kong..."
    
    # Consumer pour l'application mobile
    curl -s -X POST http://localhost:8001/consumers \
        -d "username=ismail-mobile-app" \
        -d "custom_id=mobile-app-v1" > /dev/null
    
    # Consumer pour l'application web
    curl -s -X POST http://localhost:8001/consumers \
        -d "username=ismail-web-app" \
        -d "custom_id=web-app-v1" > /dev/null
    
    # Consumer pour l'administration
    curl -s -X POST http://localhost:8001/consumers \
        -d "username=ismail-admin-app" \
        -d "custom_id=admin-app-v1" > /dev/null
    
    # Générer les clés JWT pour chaque consumer
    generate_jwt_keys
    
    log_success "Consumers Kong créés"
}

# Générer les clés JWT
generate_jwt_keys() {
    log_info "Génération des clés JWT..."
    
    # Clé JWT pour l'application mobile
    MOBILE_JWT_SECRET=$(openssl rand -base64 32)
    curl -s -X POST http://localhost:8001/consumers/ismail-mobile-app/jwt \
        -d "key=ismail-mobile-app" \
        -d "secret=$MOBILE_JWT_SECRET" > /dev/null
    
    # Clé JWT pour l'application web
    WEB_JWT_SECRET=$(openssl rand -base64 32)
    curl -s -X POST http://localhost:8001/consumers/ismail-web-app/jwt \
        -d "key=ismail-web-app" \
        -d "secret=$WEB_JWT_SECRET" > /dev/null
    
    # Clé JWT pour l'administration
    ADMIN_JWT_SECRET=$(openssl rand -base64 32)
    curl -s -X POST http://localhost:8001/consumers/ismail-admin-app/jwt \
        -d "key=ismail-admin-app" \
        -d "secret=$ADMIN_JWT_SECRET" > /dev/null
    
    # Sauvegarder les secrets JWT dans Kubernetes
    kubectl create secret generic kong-jwt-secrets \
        --from-literal=mobile-secret="$MOBILE_JWT_SECRET" \
        --from-literal=web-secret="$WEB_JWT_SECRET" \
        --from-literal=admin-secret="$ADMIN_JWT_SECRET" \
        --namespace=ismail-core \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Clés JWT générées et sauvegardées"
}

# Tester la configuration Kong
test_kong_configuration() {
    log_info "Test de la configuration Kong..."
    
    # Tester l'endpoint de santé
    if curl -s http://localhost:8001/status | jq -r '.database.reachable' | grep -q "true"; then
        log_success "✓ Base de données Kong accessible"
    else
        log_error "✗ Base de données Kong non accessible"
    fi
    
    # Tester les services configurés
    local services=$(curl -s http://localhost:8001/services | jq -r '.data[].name')
    if [[ -n "$services" ]]; then
        log_success "✓ Services Kong configurés: $(echo $services | tr '\n' ' ')"
    else
        log_warning "⚠ Aucun service Kong configuré"
    fi
    
    # Tester les routes configurées
    local routes=$(curl -s http://localhost:8001/routes | jq -r '.data[].name')
    if [[ -n "$routes" ]]; then
        log_success "✓ Routes Kong configurées: $(echo $routes | tr '\n' ' ')"
    else
        log_warning "⚠ Aucune route Kong configurée"
    fi
    
    # Tester les plugins activés
    local plugins=$(curl -s http://localhost:8001/plugins | jq -r '.data[].name')
    if [[ -n "$plugins" ]]; then
        log_success "✓ Plugins Kong activés: $(echo $plugins | tr '\n' ' ')"
    else
        log_warning "⚠ Aucun plugin Kong activé"
    fi
    
    log_success "Tests Kong terminés"
}

# Afficher les informations de connexion
display_kong_info() {
    log_info "=== Informations Kong API Gateway ==="
    
    # Récupérer l'IP du Load Balancer
    local kong_ip=$(kubectl get service kong-kong-proxy -n ismail-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    
    echo "Kong Proxy (API Gateway):"
    echo "  External IP: $kong_ip"
    echo "  HTTP Port: 80"
    echo "  HTTPS Port: 443"
    echo
    echo "Kong Admin API:"
    echo "  Internal: kong-kong-admin.ismail-ingress.svc.cluster.local:8001"
    echo "  Port-forward: kubectl port-forward -n ismail-ingress svc/kong-kong-admin 8001:8001"
    echo
    echo "Kong Manager (GUI):"
    echo "  Internal: kong-kong-manager.ismail-ingress.svc.cluster.local:8002"
    echo "  Port-forward: kubectl port-forward -n ismail-ingress svc/kong-kong-manager 8002:8002"
    echo
    echo "Endpoints configurés:"
    echo "  - /api/auth/* (Service d'authentification)"
    echo "  - /api/wallet/* (Service portefeuille)"
    echo "  - /api/users/* (Service utilisateurs)"
    echo "  - /api/notifications/* (Service notifications)"
    echo "  - /api/services/* (Module Services)"
    echo "  - /api/shop/* (Module Shop)"
    echo "  - /api/booking/* (Module Booking)"
    echo "  - /api/realestate/* (Module Immobilier)"
    echo "  - /api/recovery/* (Module Recouvrement)"
    echo
    echo "Consumers JWT créés:"
    echo "  - ismail-mobile-app"
    echo "  - ismail-web-app"
    echo "  - ismail-admin-app"
    echo
}

# Nettoyage en cas d'erreur
cleanup_on_error() {
    log_error "Erreur détectée. Nettoyage en cours..."
    
    # Arrêter les port-forwards en cours
    pkill -f "kubectl port-forward.*kong" 2>/dev/null || true
    
    # Supprimer les fichiers temporaires
    rm -f /tmp/kong-tls.key /tmp/kong-tls.crt
    
    log_error "Consultez les logs pour plus de détails"
}

# Configuration du trap pour le nettoyage
trap cleanup_on_error ERR

# Fonction principale
main() {
    log_info "=== Configuration Kong API Gateway ISMAIL ==="
    log_info "Environnement: $ENVIRONMENT"
    echo
    
    check_prerequisites
    install_kong
    configure_kong
    test_kong_configuration
    display_kong_info
    
    # Arrêter le port-forward
    kill $KONG_PORT_FORWARD_PID 2>/dev/null || true
    
    log_success "=== Configuration Kong terminée ==="
    log_info "Kong est prêt à recevoir le trafic des services ISMAIL"
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
