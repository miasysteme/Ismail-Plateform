# Infrastructure ISMAIL - Guide de Déploiement

## 🚀 Déploiement Rapide

### Prérequis

1. **Outils requis**
   ```bash
   # AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip && sudo ./aws/install
   
   # Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/
   
   # kubectl
   curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
   chmod +x kubectl && sudo mv kubectl /usr/local/bin/
   
   # Helm
   curl https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz | tar xz
   sudo mv linux-amd64/helm /usr/local/bin/
   ```

2. **Configuration AWS**
   ```bash
   aws configure
   # AWS Access Key ID: [Votre clé]
   # AWS Secret Access Key: [Votre secret]
   # Default region name: af-south-1
   # Default output format: json
   ```

3. **Variables d'environnement**
   ```bash
   export ENVIRONMENT=dev  # ou staging, prod
   export AWS_REGION=af-south-1
   ```

### Déploiement Automatique

```bash
# Cloner le repository
git clone https://github.com/votre-org/ismail-platform.git
cd ismail-platform

# Rendre le script exécutable
chmod +x infrastructure/scripts/deploy-infrastructure.sh

# Déployer l'infrastructure
./infrastructure/scripts/deploy-infrastructure.sh dev
```

### Déploiement Manuel

1. **Terraform**
   ```bash
   cd infrastructure/terraform
   
   # Copier et adapter les variables
   cp terraform.tfvars.example terraform.tfvars
   
   # Initialiser Terraform
   terraform init
   
   # Planifier le déploiement
   terraform plan -var="environment=dev"
   
   # Appliquer les changements
   terraform apply -var="environment=dev"
   ```

2. **Kubernetes**
   ```bash
   # Configurer kubectl
   aws eks update-kubeconfig --region af-south-1 --name ismail-cluster
   
   # Déployer les namespaces
   kubectl apply -f infrastructure/kubernetes/namespaces.yaml
   ```

3. **Helm Charts**
   ```bash
   # Ajouter les repositories
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo add kong https://charts.konghq.com
   helm repo update
   
   # Installer le monitoring
   helm install prometheus-stack prometheus-community/kube-prometheus-stack \
     --namespace ismail-monitoring \
     --values infrastructure/helm/monitoring/values-prometheus.yaml
   
   # Installer Kong
   helm install kong kong/kong \
     --namespace ismail-ingress \
     --values infrastructure/helm/kong/values.yaml
   ```

## 🏗️ Architecture

### Vue d'Ensemble
```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 AWS Load Balancer                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 Kong API Gateway                            │
│              (ismail-ingress namespace)                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
┌───────▼──────┐ ┌────▼────┐ ┌──────▼──────┐
│ Core Services│ │Business │ │ Monitoring  │
│   (Auth,     │ │Modules  │ │(Prometheus, │
│  Wallet,     │ │(Services│ │ Grafana)    │
│Notification) │ │ Shop,   │ │             │
│              │ │Booking) │ │             │
└──────────────┘ └─────────┘ └─────────────┘
        │             │             │
┌───────▼─────────────▼─────────────▼─────────────┐
│              Data Layer                         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐│
│  │ PostgreSQL  │ │   MongoDB   │ │    Redis    ││
│  │    (RDS)    │ │  (EKS Pod)  │ │(ElastiCache)││
│  └─────────────┘ └─────────────┘ └─────────────┘│
└─────────────────────────────────────────────────┘
```

### Composants

#### Infrastructure AWS
- **EKS Cluster** : Kubernetes managé avec 3 groupes de nœuds
- **RDS PostgreSQL** : Base de données principale avec réplication
- **ElastiCache Redis** : Cache et sessions utilisateur
- **S3** : Stockage d'objets et backups
- **VPC** : Réseau privé avec subnets publics/privés

#### Services Kubernetes
- **Kong API Gateway** : Point d'entrée unique avec rate limiting
- **Prometheus Stack** : Monitoring complet avec Grafana
- **Namespaces** : Isolation logique des services
- **Network Policies** : Sécurisation des communications

## 🔧 Configuration

### Environnements

| Environnement | Cluster | Base de Données | Cache | Monitoring |
|---------------|---------|-----------------|-------|------------|
| **dev** | 3 nœuds t3.medium | db.t3.medium | cache.t3.micro | Basique |
| **staging** | 5 nœuds t3.large | db.r5.large | cache.r6g.medium | Complet |
| **prod** | 10+ nœuds r5.xlarge | db.r5.xlarge + replica | cache.r6g.large HA | Avancé |

### Secrets Requis

```bash
# GitHub Secrets pour CI/CD
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
SENDGRID_API_KEY=SG...
SLACK_WEBHOOK_URL=https://hooks.slack.com/...

# Kubernetes Secrets (créés automatiquement)
kong-postgres-secret    # Mot de passe Kong DB
redis-auth             # Token Redis
postgres-auth          # Credentials PostgreSQL
kong-ssl-cert          # Certificats SSL
```

### Variables d'Environnement

```bash
# Obligatoires
ENVIRONMENT=dev|staging|prod
AWS_REGION=af-south-1

# Optionnelles
AUTO_APPROVE=true|false
SENDGRID_API_KEY=...
SLACK_WEBHOOK_URL=...
```

## 📊 Monitoring

### Accès aux Services

```bash
# Grafana (monitoring)
kubectl port-forward -n ismail-monitoring svc/prometheus-stack-grafana 3000:80
# http://localhost:3000 (admin/IsmaIl2024!Secure)

# Kong Manager (API Gateway)
kubectl port-forward -n ismail-ingress svc/kong-kong-manager 8002:8002
# http://localhost:8002

# Prometheus
kubectl port-forward -n ismail-monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
# http://localhost:9090
```

### Dashboards Grafana

- **Platform Overview** : Vue d'ensemble du cluster
- **Application Metrics** : Métriques des services ISMAIL
- **Database Metrics** : Performance PostgreSQL/Redis
- **Kong Metrics** : Statistiques API Gateway

### Alertes Configurées

- **Taux d'erreur élevé** (>10% sur 5min)
- **Latence élevée** (P95 >2s sur 5min)
- **Utilisation CPU** (>80% sur 10min)
- **Utilisation mémoire** (>85% sur 10min)
- **Pods qui redémarrent** (>0 restart/heure)

## 🔒 Sécurité

### Network Policies
- Isolation par namespace
- Communication contrôlée entre services
- Accès externe limité

### Chiffrement
- **En transit** : TLS 1.3 obligatoire
- **Au repos** : AES-256 pour toutes les données
- **Secrets** : Kubernetes secrets chiffrés

### Conformité
- **RGPD** : Chiffrement, audit, rétention
- **UEMOA** : Résidence des données en Afrique

## 🚨 Dépannage

### Problèmes Courants

1. **Terraform init échoue**
   ```bash
   # Vérifier les credentials AWS
   aws sts get-caller-identity
   
   # Créer le bucket S3 pour l'état
   aws s3 mb s3://ismail-terraform-state-dev --region af-south-1
   ```

2. **Pods en état Pending**
   ```bash
   # Vérifier les ressources
   kubectl describe nodes
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

3. **Kong ne démarre pas**
   ```bash
   # Vérifier les logs
   kubectl logs -n ismail-ingress -l app=kong-kong
   
   # Vérifier la base de données
   kubectl get secret kong-postgres-secret -n ismail-ingress -o yaml
   ```

### Commandes Utiles

```bash
# État général du cluster
kubectl get pods --all-namespaces
kubectl top nodes
kubectl top pods --all-namespaces

# Logs des services
kubectl logs -n ismail-core -l app=auth-service
kubectl logs -n ismail-ingress -l app=kong-kong

# Redémarrer un déploiement
kubectl rollout restart deployment/kong-kong -n ismail-ingress

# Nettoyer les ressources
terraform destroy -var="environment=dev"
```

## 📞 Support

- **Documentation** : [docs.ismail-platform.com](https://docs.ismail-platform.com)
- **Issues** : [GitHub Issues](https://github.com/votre-org/ismail-platform/issues)
- **Slack** : #infrastructure-support
- **Email** : devops@ismail-platform.com

---

**🎯 Infrastructure prête pour le développement des services ISMAIL !**
