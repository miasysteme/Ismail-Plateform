# 🌍 Guide de Configuration Services Cloud Afrique - ISMAIL Platform

Guide détaillé pour configurer tous les services cloud optimisés pour l'Afrique de l'Ouest.

## 📋 Services à Configurer

### ✅ **Services Principaux**
1. **🚀 Netlify** - Hébergement frontend
2. **🚂 Railway** - Backend services
3. **🗄️ Supabase** - Base de données PostgreSQL
4. **📦 Upstash** - Redis serverless
5. **📧 Resend** - Service d'emails
6. **📁 Cloudinary** - Stockage images/fichiers

### ✅ **Services Complémentaires**
7. **🔔 Discord** - Notifications (alternative Slack)
8. **📊 Better Stack** - Monitoring et logs
9. **🐛 Sentry** - Error tracking
10. **🔍 SonarCloud** - Quality gates

---

## 🚀 Configuration Netlify

### **1. Création du Compte et Site**

#### **Étapes**
1. Aller sur https://netlify.com
2. Se connecter avec GitHub
3. Importer le repository `miasysteme/Ismail-Plateform`
4. Configurer le build

#### **Configuration Build**
```yaml
# Dans Netlify Dashboard > Site settings > Build & deploy
Build command: npm run build
Publish directory: frontend/dist
Base directory: frontend
```

#### **Variables d'Environnement Netlify**
```bash
# Dans Netlify Dashboard > Site settings > Environment variables
REACT_APP_SUPABASE_URL=https://your-project.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-anon-key
REACT_APP_CLOUDINARY_CLOUD_NAME=your-cloud-name
REACT_APP_ENVIRONMENT=production
```

#### **Récupérer les Secrets Netlify**
```bash
# Site ID (dans Site settings > General)
NETLIFY_SITE_ID=your-site-id

# Auth Token (dans User settings > Applications > Personal access tokens)
NETLIFY_AUTH_TOKEN=your-auth-token

# Build Hook (dans Site settings > Build & deploy > Build hooks)
NETLIFY_BUILD_HOOK=https://api.netlify.com/build_hooks/your-hook-id
```

### **2. Configuration Domaine Personnalisé**
```bash
# Dans Netlify Dashboard > Domain settings
# Ajouter votre domaine: ismail-platform.com
# Configurer les DNS selon les instructions Netlify
```

---

## 🚂 Configuration Railway

### **1. Création du Projet**

#### **Étapes**
1. Aller sur https://railway.app
2. Se connecter avec GitHub
3. Créer un nouveau projet
4. Connecter le repository

#### **Configuration Services**
```yaml
# Créer 2 services:
1. auth-service
   - Source: services/auth-service
   - Build Command: mvn clean package -DskipTests
   - Start Command: java -jar target/auth-service-*.jar

2. wallet-service
   - Source: services/wallet-service
   - Build Command: mvn clean package -DskipTests
   - Start Command: java -jar target/wallet-service-*.jar
```

#### **Variables d'Environnement Railway**
```bash
# Pour chaque service
SPRING_PROFILES_ACTIVE=production
SERVER_PORT=8080
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
JWT_SECRET=your-jwt-secret
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key
```

#### **Récupérer les Secrets Railway**
```bash
# Token Railway (dans Account Settings > Tokens)
RAILWAY_TOKEN=your-railway-token

# URLs des services (après déploiement)
RAILWAY_BACKEND_URL=https://auth-service.railway.app
```

---

## 🗄️ Configuration Supabase

### **1. Création du Projet**

#### **Étapes**
1. Aller sur https://supabase.com
2. Créer un nouveau projet
3. Choisir la région Europe West (plus proche de l'Afrique)
4. Configurer le mot de passe de la base

#### **Récupérer les Credentials**
```bash
# Dans Project Settings > API
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key

# Dans Project Settings > Database
DATABASE_URL=postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres
```

### **2. Configuration Base de Données**

#### **Schéma ISMAIL**
```sql
-- Exécuter dans SQL Editor de Supabase
CREATE SCHEMA IF NOT EXISTS ismail;

-- Tables principales (voir docs/cloud-africa-setup.md pour le schéma complet)
```

#### **Row Level Security**
```sql
-- Activer RLS pour toutes les tables
ALTER TABLE ismail.users ENABLE ROW LEVEL SECURITY;
-- Policies détaillées dans le guide principal
```

### **3. Configuration Auth**
```bash
# Dans Authentication > Settings
# Configurer les providers (Email, Phone)
# Activer la confirmation par email
# Configurer les templates d'emails
```

---

## 📦 Configuration Upstash

### **1. Création de la Base Redis**

#### **Étapes**
1. Aller sur https://upstash.com
2. Créer un compte
3. Créer une nouvelle base Redis
4. Choisir la région Europe (eu-west-1)

#### **Récupérer les Credentials**
```bash
# Dans Database Details
UPSTASH_REDIS_REST_URL=https://your-redis-id.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-token
REDIS_URL=redis://default:password@your-redis-id.upstash.io:6379
```

---

## 📧 Configuration Resend

### **1. Création du Compte**

#### **Étapes**
1. Aller sur https://resend.com
2. Créer un compte
3. Vérifier le domaine d'envoi
4. Créer une API key

#### **Configuration Domaine**
```bash
# Ajouter les enregistrements DNS pour votre domaine
# Suivre les instructions Resend pour la vérification
```

#### **Récupérer l'API Key**
```bash
# Dans API Keys
RESEND_API_KEY=re_your_api_key
```

---

## 📁 Configuration Cloudinary

### **1. Création du Compte**

#### **Étapes**
1. Aller sur https://cloudinary.com
2. Créer un compte gratuit
3. Configurer les paramètres de sécurité

#### **Récupérer les Credentials**
```bash
# Dans Dashboard
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name
```

---

## 🔔 Configuration Discord

### **1. Création du Webhook**

#### **Étapes**
1. Créer un serveur Discord pour ISMAIL
2. Créer un canal #deployments
3. Aller dans Paramètres du canal > Intégrations > Webhooks
4. Créer un nouveau webhook

#### **Récupérer l'URL**
```bash
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/your-webhook-id/your-webhook-token
```

---

## 📊 Configuration Better Stack

### **1. Création du Compte**

#### **Étapes**
1. Aller sur https://betterstack.com
2. Créer un compte
3. Créer un nouveau projet
4. Configurer les sources de logs

#### **Récupérer le Token**
```bash
# Dans Sources
BETTER_STACK_TOKEN=your-token
LOGTAIL_TOKEN=your-logtail-token
```

---

## 🐛 Configuration Sentry

### **1. Création du Projet**

#### **Étapes**
1. Aller sur https://sentry.io
2. Créer un compte
3. Créer un projet React et un projet Java
4. Configurer les alertes

#### **Récupérer le DSN**
```bash
# Dans Project Settings
SENTRY_DSN=https://your-dsn@sentry.io/project-id
```

---

## 💰 Configuration Mobile Money

### **1. Orange Money API**

#### **Étapes**
1. Aller sur https://developer.orange.com
2. Créer un compte développeur
3. Souscrire à l'API Orange Money
4. Obtenir les credentials

#### **Credentials**
```bash
ORANGE_MONEY_CLIENT_ID=your-client-id
ORANGE_MONEY_CLIENT_SECRET=your-client-secret
ORANGE_MONEY_API_URL=https://api.orange.com/orange-money-webpay/dev/v1
```

### **2. MTN Mobile Money API**

#### **Étapes**
1. Aller sur https://momodeveloper.mtn.com
2. Créer un compte développeur
3. Souscrire aux APIs Collections et Disbursements
4. Obtenir les credentials

#### **Credentials**
```bash
MTN_MOMO_API_KEY=your-api-key
MTN_MOMO_API_SECRET=your-api-secret
MTN_MOMO_SUBSCRIPTION_KEY=your-subscription-key
```

---

## 🔧 Script de Configuration Automatique

### **Exécution**
```bash
# 1. Générer les secrets
chmod +x scripts/generate-secrets-africa.sh
./scripts/generate-secrets-africa.sh

# 2. Configurer les services (suivre ce guide)
# 3. Mettre à jour le fichier .secrets/africa-secrets.env

# 4. Uploader vers GitHub
./.secrets/upload-africa-secrets.sh

# 5. Tester la configuration
./scripts/validate-africa-stack.sh
```

---

## ✅ Checklist de Validation

### **Services Configurés**
- [ ] ✅ Netlify - Site créé et connecté
- [ ] ✅ Railway - Services déployés
- [ ] ✅ Supabase - Base de données configurée
- [ ] ✅ Upstash - Redis opérationnel
- [ ] ✅ Resend - Domaine vérifié
- [ ] ✅ Cloudinary - Compte configuré
- [ ] ✅ Discord - Webhook créé
- [ ] ✅ Better Stack - Logs configurés
- [ ] ✅ Sentry - Error tracking actif
- [ ] ✅ Mobile Money - APIs configurées

### **Secrets GitHub**
- [ ] ✅ Tous les secrets repository uploadés
- [ ] ✅ Secrets environment production configurés
- [ ] ✅ Workflows GitHub Actions fonctionnels

### **Tests**
- [ ] ✅ Frontend déployé sur Netlify
- [ ] ✅ Backend déployé sur Railway
- [ ] ✅ Base de données accessible
- [ ] ✅ Redis fonctionnel
- [ ] ✅ Emails envoyés via Resend
- [ ] ✅ Images uploadées sur Cloudinary
- [ ] ✅ Notifications Discord reçues

---

## 💡 Conseils pour l'Afrique

### **Optimisations Réseau**
- Utiliser les CDN de Netlify et Cloudinary
- Configurer le cache agressif pour les assets statiques
- Optimiser les images avec Cloudinary

### **Gestion des Coûts**
- Commencer avec les plans gratuits
- Monitorer l'usage régulièrement
- Utiliser les alertes de facturation

### **Support Local**
- Configurer les fuseaux horaires africains
- Adapter les formats de dates et devises
- Intégrer les moyens de paiement locaux

---

**🌍 Stack cloud optimisée pour l'Afrique de l'Ouest configurée !**

*Accessible, performant et économique pour la région CEDEAO.*
