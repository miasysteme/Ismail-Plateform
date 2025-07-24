#!/bin/bash

# Script de déploiement du monitoring - Plateforme ISMAIL
# Déploie Prometheus, Grafana, AlertManager et tous les exporters

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MONITORING_DIR="${PROJECT_ROOT}/infrastructure/monitoring"

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
    local tools=("kubectl" "helm" "openssl")
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

# Créer les namespaces
create_namespaces() {
    log_info "Création des namespaces..."
    
    # Namespace monitoring
    kubectl create namespace ismail-monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Labels pour les namespaces
    kubectl label namespace ismail-monitoring name=ismail-monitoring --overwrite
    kubectl label namespace ismail-monitoring project=ismail --overwrite
    
    log_success "Namespaces créés"
}

# Générer les secrets
generate_secrets() {
    log_info "Génération des secrets..."
    
    # Secrets Grafana
    local grafana_admin_password=$(openssl rand -base64 32)
    local grafana_secret_key=$(openssl rand -base64 32)
    local grafana_db_password=$(openssl rand -base64 32)
    
    # Secret Grafana
    kubectl create secret generic grafana-secrets \
        --from-literal=admin-password="$grafana_admin_password" \
        --from-literal=secret-key="$grafana_secret_key" \
        --from-literal=db-password="$grafana_db_password" \
        --namespace=ismail-monitoring \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Secrets pour les exporters
    local postgres_exporter_password=$(openssl rand -base64 32)
    local mongodb_exporter_password=$(openssl rand -base64 32)
    
    kubectl create secret generic exporter-secrets \
        --from-literal=postgres-password="$postgres_exporter_password" \
        --from-literal=mongodb-password="$mongodb_exporter_password" \
        --namespace=ismail-monitoring \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Secrets pour AlertManager
    local sendgrid_api_key="${SENDGRID_API_KEY:-dummy-key}"
    local slack_webhook_url="${SLACK_WEBHOOK_URL:-https://hooks.slack.com/dummy}"
    
    kubectl create secret generic alertmanager-secrets \
        --from-literal=sendgrid-api-key="$sendgrid_api_key" \
        --from-literal=slack-webhook-url="$slack_webhook_url" \
        --namespace=ismail-monitoring \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Afficher les mots de passe générés
    log_success "Secrets générés:"
    echo "  Grafana Admin Password: $grafana_admin_password"
    echo "  Grafana Secret Key: $grafana_secret_key"
    echo "  Grafana DB Password: $grafana_db_password"
    echo ""
    echo "Sauvegardez ces mots de passe dans un gestionnaire de mots de passe sécurisé!"
}

# Déployer Prometheus
deploy_prometheus() {
    log_info "Déploiement de Prometheus..."
    
    # Ajouter le repository Helm
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Créer les ConfigMaps pour les règles d'alerte
    kubectl create configmap prometheus-rules \
        --from-file="${MONITORING_DIR}/prometheus/rules/" \
        --namespace=ismail-monitoring \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Déployer Prometheus avec Helm
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace ismail-monitoring \
        --values "${MONITORING_DIR}/prometheus/values.yaml" \
        --set prometheus.prometheusSpec.ruleSelector.matchLabels.app=prometheus \
        --set prometheus.prometheusSpec.ruleNamespaceSelector.matchLabels.name=ismail-monitoring \
        --wait --timeout=600s
    
    log_success "Prometheus déployé"
}

# Déployer Grafana
deploy_grafana() {
    log_info "Déploiement de Grafana..."
    
    # Ajouter le repository Helm Grafana
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Déployer Grafana
    helm upgrade --install grafana grafana/grafana \
        --namespace ismail-monitoring \
        --values "${MONITORING_DIR}/grafana/values.yaml" \
        --wait --timeout=600s
    
    log_success "Grafana déployé"
}

# Déployer les exporters
deploy_exporters() {
    log_info "Déploiement des exporters..."
    
    # PostgreSQL Exporter
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-exporter
  namespace: ismail-monitoring
  labels:
    app: postgres-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-exporter
  template:
    metadata:
      labels:
        app: postgres-exporter
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9187"
    spec:
      containers:
      - name: postgres-exporter
        image: quay.io/prometheuscommunity/postgres-exporter:v0.15.0
        ports:
        - containerPort: 9187
        env:
        - name: DATA_SOURCE_NAME
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: connection-string
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-exporter
  namespace: ismail-monitoring
  labels:
    app: postgres-exporter
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9187"
spec:
  ports:
  - port: 9187
    targetPort: 9187
    name: metrics
  selector:
    app: postgres-exporter
EOF

    # Redis Exporter
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-exporter
  namespace: ismail-monitoring
  labels:
    app: redis-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-exporter
  template:
    metadata:
      labels:
        app: redis-exporter
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9121"
    spec:
      containers:
      - name: redis-exporter
        image: oliver006/redis_exporter:v1.55.0
        ports:
        - containerPort: 9121
        env:
        - name: REDIS_ADDR
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: host
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: password
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: redis-exporter
  namespace: ismail-monitoring
  labels:
    app: redis-exporter
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9121"
spec:
  ports:
  - port: 9121
    targetPort: 9121
    name: metrics
  selector:
    app: redis-exporter
EOF

    log_success "Exporters déployés"
}

# Configurer les ServiceMonitors
configure_service_monitors() {
    log_info "Configuration des ServiceMonitors..."
    
    # ServiceMonitor pour Kong
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kong-metrics
  namespace: ismail-monitoring
  labels:
    app: kong
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: kong
  namespaceSelector:
    matchNames:
    - ismail-ingress
  endpoints:
  - port: kong-admin
    path: /metrics
    interval: 30s
EOF

    # ServiceMonitor pour les services ISMAIL
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ismail-services-metrics
  namespace: ismail-monitoring
  labels:
    app: ismail-services
spec:
  selector:
    matchLabels:
      prometheus.io/scrape: "true"
  namespaceSelector:
    matchNames:
    - ismail-core
    - ismail-business
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 15s
EOF

    log_success "ServiceMonitors configurés"
}

# Attendre que les services soient prêts
wait_for_services() {
    log_info "Attente que les services soient prêts..."
    
    # Attendre Prometheus
    kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=prometheus -n ismail-monitoring --timeout=300s
    
    # Attendre Grafana
    kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=grafana -n ismail-monitoring --timeout=300s
    
    # Attendre AlertManager
    kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=alertmanager -n ismail-monitoring --timeout=300s
    
    log_success "Tous les services sont prêts"
}

# Configurer les dashboards Grafana
configure_dashboards() {
    log_info "Configuration des dashboards Grafana..."
    
    # Port-forward vers Grafana pour configuration
    kubectl port-forward -n ismail-monitoring svc/grafana 3000:3000 &
    GRAFANA_PORT_FORWARD_PID=$!
    
    # Attendre que le port-forward soit actif
    sleep 10
    
    # Récupérer le mot de passe admin
    local grafana_password=$(kubectl get secret grafana-secrets -n ismail-monitoring -o jsonpath='{.data.admin-password}' | base64 -d)
    
    # Importer les dashboards (via API ou ConfigMaps)
    log_info "Dashboards seront importés via ConfigMaps au redémarrage de Grafana"
    
    # Arrêter le port-forward
    kill $GRAFANA_PORT_FORWARD_PID 2>/dev/null || true
    
    log_success "Configuration des dashboards terminée"
}

# Tester le monitoring
test_monitoring() {
    log_info "Test du monitoring..."
    
    # Tester Prometheus
    local prometheus_ip=$(kubectl get service prometheus-kube-prometheus-prometheus -n ismail-monitoring -o jsonpath='{.spec.clusterIP}')
    if kubectl run test-prometheus --image=curlimages/curl --rm -i --restart=Never -- curl -s "http://$prometheus_ip:9090/api/v1/query?query=up" | grep -q "success"; then
        log_success "✓ Prometheus accessible"
    else
        log_error "✗ Prometheus non accessible"
    fi
    
    # Tester Grafana
    local grafana_ip=$(kubectl get service grafana -n ismail-monitoring -o jsonpath='{.spec.clusterIP}')
    if kubectl run test-grafana --image=curlimages/curl --rm -i --restart=Never -- curl -s "http://$grafana_ip:3000/api/health" | grep -q "ok"; then
        log_success "✓ Grafana accessible"
    else
        log_error "✗ Grafana non accessible"
    fi
    
    # Tester AlertManager
    local alertmanager_ip=$(kubectl get service prometheus-kube-prometheus-alertmanager -n ismail-monitoring -o jsonpath='{.spec.clusterIP}')
    if kubectl run test-alertmanager --image=curlimages/curl --rm -i --restart=Never -- curl -s "http://$alertmanager_ip:9093/api/v1/status" | grep -q "success"; then
        log_success "✓ AlertManager accessible"
    else
        log_error "✗ AlertManager non accessible"
    fi
    
    log_success "Tests de monitoring terminés"
}

# Afficher les informations d'accès
display_access_info() {
    log_info "=== Informations d'accès au monitoring ==="
    
    # Récupérer les IPs des services
    local prometheus_ip=$(kubectl get service prometheus-kube-prometheus-prometheus -n ismail-monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    local grafana_ip=$(kubectl get service grafana -n ismail-monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    local alertmanager_ip=$(kubectl get service prometheus-kube-prometheus-alertmanager -n ismail-monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    
    echo "Prometheus:"
    echo "  External: http://$prometheus_ip:9090"
    echo "  Port-forward: kubectl port-forward -n ismail-monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
    echo
    echo "Grafana:"
    echo "  External: http://$grafana_ip:3000"
    echo "  Port-forward: kubectl port-forward -n ismail-monitoring svc/grafana 3000:3000"
    echo "  Username: admin"
    echo "  Password: $(kubectl get secret grafana-secrets -n ismail-monitoring -o jsonpath='{.data.admin-password}' | base64 -d)"
    echo
    echo "AlertManager:"
    echo "  External: http://$alertmanager_ip:9093"
    echo "  Port-forward: kubectl port-forward -n ismail-monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093"
    echo
    echo "Dashboards disponibles:"
    echo "  - Kong API Gateway"
    echo "  - Services ISMAIL Core"
    echo "  - Bases de données"
    echo "  - Infrastructure Kubernetes"
    echo "  - Business Metrics"
    echo
}

# Nettoyage en cas d'erreur
cleanup_on_error() {
    log_error "Erreur détectée. Nettoyage en cours..."
    
    # Arrêter les port-forwards en cours
    pkill -f "kubectl port-forward.*grafana" 2>/dev/null || true
    
    log_error "Consultez les logs pour plus de détails"
}

# Configuration du trap pour le nettoyage
trap cleanup_on_error ERR

# Fonction principale
main() {
    log_info "=== Déploiement Monitoring ISMAIL ==="
    log_info "Environnement: $ENVIRONMENT"
    echo
    
    check_prerequisites
    create_namespaces
    generate_secrets
    deploy_prometheus
    deploy_grafana
    deploy_exporters
    configure_service_monitors
    wait_for_services
    configure_dashboards
    test_monitoring
    display_access_info
    
    log_success "=== Déploiement monitoring terminé ==="
    log_info "Stack de monitoring prête pour la plateforme ISMAIL"
}

# Vérification des arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <environment>"
    echo "Environments: dev, staging, prod"
    echo
    echo "Variables d'environnement optionnelles:"
    echo "  SENDGRID_API_KEY - Clé API SendGrid pour les alertes email"
    echo "  SLACK_WEBHOOK_URL - URL webhook Slack pour les alertes"
    echo
    echo "Exemple:"
    echo "  export ENVIRONMENT=dev"
    echo "  export SENDGRID_API_KEY=your-api-key"
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
