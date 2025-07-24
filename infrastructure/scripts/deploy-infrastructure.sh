#!/bin/bash

# Script de déploiement infrastructure - Plateforme ISMAIL
# Déploie l'infrastructure complète sur AWS avec Terraform et Kubernetes

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/infrastructure/terraform"
KUBERNETES_DIR="${PROJECT_ROOT}/infrastructure/kubernetes"
HELM_DIR="${PROJECT_ROOT}/infrastructure/helm"

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
    local tools=("terraform" "kubectl" "helm" "aws")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool n'est pas installé"
            exit 1
        fi
    done
    
    # Vérifier la configuration AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Configuration AWS invalide. Exécutez 'aws configure'"
        exit 1
    fi
    
    # Vérifier les variables d'environnement
    local required_vars=("ENVIRONMENT" "AWS_REGION")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Variable d'environnement $var non définie"
            exit 1
        fi
    done
    
    log_success "Prérequis validés"
}

# Déploiement Terraform
deploy_terraform() {
    log_info "Déploiement de l'infrastructure Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialisation Terraform
    log_info "Initialisation Terraform..."
    terraform init -backend-config="bucket=ismail-terraform-state-${ENVIRONMENT}" \
                   -backend-config="key=infrastructure/${ENVIRONMENT}/terraform.tfstate" \
                   -backend-config="region=${AWS_REGION}"
    
    # Validation de la configuration
    log_info "Validation de la configuration..."
    terraform validate
    
    # Plan Terraform
    log_info "Génération du plan Terraform..."
    terraform plan -var="environment=${ENVIRONMENT}" \
                   -var="aws_region=${AWS_REGION}" \
                   -out="tfplan"
    
    # Application du plan (avec confirmation)
    if [[ "${AUTO_APPROVE:-false}" == "true" ]]; then
        log_info "Application automatique du plan..."
        terraform apply -auto-approve "tfplan"
    else
        log_warning "Voulez-vous appliquer ce plan? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            terraform apply "tfplan"
        else
            log_info "Déploiement annulé"
            exit 0
        fi
    fi
    
    # Récupération des outputs
    log_info "Récupération des informations de déploiement..."
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint)
    
    # Export des variables pour les étapes suivantes
    export CLUSTER_NAME CLUSTER_ENDPOINT
    
    log_success "Infrastructure Terraform déployée"
}

# Configuration kubectl
configure_kubectl() {
    log_info "Configuration de kubectl..."
    
    # Mise à jour du kubeconfig
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
    
    # Vérification de la connexion
    if kubectl cluster-info &> /dev/null; then
        log_success "kubectl configuré avec succès"
    else
        log_error "Impossible de se connecter au cluster"
        exit 1
    fi
    
    # Attendre que le cluster soit prêt
    log_info "Attente que le cluster soit prêt..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
}

# Déploiement des namespaces et RBAC
deploy_kubernetes_base() {
    log_info "Déploiement des ressources Kubernetes de base..."
    
    cd "$KUBERNETES_DIR"
    
    # Déploiement des namespaces
    kubectl apply -f namespaces.yaml
    
    # Attendre que les namespaces soient créés
    kubectl wait --for=condition=Active namespace/ismail-core --timeout=60s
    kubectl wait --for=condition=Active namespace/ismail-business --timeout=60s
    kubectl wait --for=condition=Active namespace/ismail-data --timeout=60s
    kubectl wait --for=condition=Active namespace/ismail-monitoring --timeout=60s
    
    log_success "Ressources Kubernetes de base déployées"
}

# Déploiement des secrets
deploy_secrets() {
    log_info "Déploiement des secrets..."
    
    # Secret pour PostgreSQL Kong
    kubectl create secret generic kong-postgres-secret \
        --from-literal=password="$(openssl rand -base64 32)" \
        --namespace=ismail-ingress \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Secret pour Redis
    kubectl create secret generic redis-auth \
        --from-literal=password="$(terraform output -raw redis_auth_token)" \
        --namespace=ismail-core \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Secret pour base de données principale
    kubectl create secret generic postgres-auth \
        --from-literal=username="postgres" \
        --from-literal=password="$(terraform output -raw postgres_password)" \
        --from-literal=host="$(terraform output -raw postgres_endpoint)" \
        --namespace=ismail-core \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Certificats SSL (auto-signés pour dev, Let's Encrypt pour prod)
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        # TODO: Intégrer cert-manager pour Let's Encrypt
        log_warning "Configuration SSL production à implémenter"
    else
        # Certificat auto-signé pour développement
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /tmp/tls.key -out /tmp/tls.crt \
            -subj "/CN=*.ismail-platform.com/O=ISMAIL"
        
        kubectl create secret tls kong-ssl-cert \
            --cert=/tmp/tls.crt --key=/tmp/tls.key \
            --namespace=ismail-ingress \
            --dry-run=client -o yaml | kubectl apply -f -
        
        rm -f /tmp/tls.key /tmp/tls.crt
    fi
    
    log_success "Secrets déployés"
}

# Installation Helm charts
install_helm_charts() {
    log_info "Installation des charts Helm..."
    
    # Ajout des repositories Helm
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add kong https://charts.konghq.com
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    # Installation du monitoring stack
    log_info "Installation du stack de monitoring..."
    helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
        --namespace ismail-monitoring \
        --values "${HELM_DIR}/monitoring/values-prometheus.yaml" \
        --wait --timeout=600s
    
    # Installation de Kong API Gateway
    log_info "Installation de Kong API Gateway..."
    helm upgrade --install kong kong/kong \
        --namespace ismail-ingress \
        --values "${HELM_DIR}/kong/values.yaml" \
        --wait --timeout=300s
    
    # Installation de MongoDB (pour développement)
    if [[ "$ENVIRONMENT" != "prod" ]]; then
        log_info "Installation de MongoDB..."
        helm upgrade --install mongodb bitnami/mongodb \
            --namespace ismail-data \
            --set auth.rootPassword="$(openssl rand -base64 32)" \
            --set persistence.size=20Gi \
            --set resources.requests.memory=512Mi \
            --set resources.requests.cpu=250m \
            --wait --timeout=300s
    fi
    
    log_success "Charts Helm installés"
}

# Vérification du déploiement
verify_deployment() {
    log_info "Vérification du déploiement..."
    
    # Vérifier que tous les pods sont prêts
    local namespaces=("ismail-core" "ismail-business" "ismail-data" "ismail-monitoring" "ismail-ingress")
    
    for ns in "${namespaces[@]}"; do
        log_info "Vérification du namespace $ns..."
        kubectl wait --for=condition=Ready pods --all -n "$ns" --timeout=300s || true
    done
    
    # Vérifier les services critiques
    log_info "Vérification des services..."
    
    # Kong API Gateway
    if kubectl get service kong-kong-proxy -n ismail-ingress &> /dev/null; then
        KONG_IP=$(kubectl get service kong-kong-proxy -n ismail-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        log_info "Kong API Gateway disponible sur: $KONG_IP"
    fi
    
    # Grafana
    if kubectl get service prometheus-stack-grafana -n ismail-monitoring &> /dev/null; then
        log_info "Grafana disponible via port-forward: kubectl port-forward -n ismail-monitoring svc/prometheus-stack-grafana 3000:80"
    fi
    
    # Afficher l'état général
    log_info "État des pods par namespace:"
    for ns in "${namespaces[@]}"; do
        echo "=== $ns ==="
        kubectl get pods -n "$ns" 2>/dev/null || echo "Aucun pod dans $ns"
        echo
    done
    
    log_success "Vérification terminée"
}

# Nettoyage en cas d'erreur
cleanup_on_error() {
    log_error "Erreur détectée. Nettoyage en cours..."
    
    # Supprimer les ressources temporaires
    rm -f /tmp/tls.key /tmp/tls.crt
    
    # Afficher les logs d'erreur
    log_error "Consultez les logs pour plus de détails"
}

# Configuration du trap pour le nettoyage
trap cleanup_on_error ERR

# Fonction principale
main() {
    log_info "=== Déploiement Infrastructure ISMAIL ==="
    log_info "Environnement: $ENVIRONMENT"
    log_info "Région AWS: $AWS_REGION"
    echo
    
    check_prerequisites
    deploy_terraform
    configure_kubectl
    deploy_kubernetes_base
    deploy_secrets
    install_helm_charts
    verify_deployment
    
    log_success "=== Déploiement terminé avec succès ==="
    log_info "Prochaines étapes:"
    log_info "1. Configurer les DNS pour pointer vers Kong"
    log_info "2. Déployer les services applicatifs"
    log_info "3. Configurer les certificats SSL pour la production"
}

# Vérification des arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <environment>"
    echo "Environments: dev, staging, prod"
    echo
    echo "Variables d'environnement requises:"
    echo "  ENVIRONMENT - Environnement de déploiement"
    echo "  AWS_REGION - Région AWS (défaut: af-south-1)"
    echo
    echo "Variables optionnelles:"
    echo "  AUTO_APPROVE - Approbation automatique Terraform (défaut: false)"
    exit 1
fi

# Configuration des variables
export ENVIRONMENT="$1"
export AWS_REGION="${AWS_REGION:-af-south-1}"

# Validation de l'environnement
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Environnement invalide: $ENVIRONMENT"
    exit 1
fi

# Exécution du script principal
main "$@"
