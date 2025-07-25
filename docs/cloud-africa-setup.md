# 🌍 Configuration Cloud pour l'Afrique de l'Ouest - ISMAIL Platform

Guide complet pour déployer ISMAIL Platform avec des services cloud optimisés et accessibles en Afrique de l'Ouest.

## 🎯 Stack Cloud Recommandée

### **Pourquoi cette Stack ?**
- ✅ **Accessible** en Afrique de l'Ouest
- ✅ **Latence optimisée** avec CDN global
- ✅ **Coûts réduits** par rapport à AWS
- ✅ **Simplicité** de configuration
- ✅ **Scaling automatique**
- ✅ **Support communautaire** excellent

---

## 🚀 Architecture Cloud Afrique

```
┌─────────────────────────────────────────────────────────────┐
│                ISMAIL Platform - Stack Afrique              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │    Frontend     │ │    Backend      │ │   Base de       ││
│  │                 │ │                 │ │   Données       ││
│  │ • Netlify       │ │ • Railway       │ │ • Supabase      ││
│  │ • React/Next.js │ │ • Spring Boot   │ │ • PostgreSQL    ││
│  │ • PWA Support   │ │ • Docker        │ │ • Auth intégré  ││
│  │ • CDN Global    │ │ • Auto-scale    │ │ • Storage       ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
│                                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │     Cache       │ │   Monitoring    │ │   Services      ││
│  │                 │ │                 │ │                 ││
│  │ • Upstash       │ │ • Better Stack  │ │ • Resend        ││
│  │ • Redis         │ │ • Logs/Metrics  │ │ • Cloudinary    ││
│  │ • Serverless    │ │ • Alertes       │ │ • Discord       ││
│  │ • Edge Cache    │ │ • Dashboards    │ │ • Webhooks      ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Configuration Netlify

### **1. Setup Initial Netlify**

#### **Connexion GitHub**
```bash
# Installer Netlify CLI
npm install -g netlify-cli

# Se connecter à Netlify
netlify login

# Lier le repository
netlify init
```

#### **Configuration netlify.toml**
```toml
# netlify.toml
[build]
  base = "frontend/"
  publish = "frontend/dist"
  command = "npm run build"

[build.environment]
  NODE_VERSION = "20"
  NPM_VERSION = "10"

# Redirections pour SPA
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

# API Proxy vers Railway
[[redirects]]
  from = "/api/*"
  to = "https://ismail-backend.railway.app/api/:splat"
  status = 200
  force = true

# Headers de sécurité
[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-XSS-Protection = "1; mode=block"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"
    Content-Security-Policy = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"

# Cache statique
[[headers]]
  for = "/static/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

# Variables d'environnement
[context.production.environment]
  REACT_APP_API_URL = "https://ismail-backend.railway.app"
  REACT_APP_ENVIRONMENT = "production"

[context.deploy-preview.environment]
  REACT_APP_API_URL = "https://ismail-staging.railway.app"
  REACT_APP_ENVIRONMENT = "staging"

[context.branch-deploy.environment]
  REACT_APP_API_URL = "https://ismail-dev.railway.app"
  REACT_APP_ENVIRONMENT = "development"
```

### **2. Fonctions Netlify (Serverless)**

#### **Fonction d'authentification**
```javascript
// netlify/functions/auth-proxy.js
exports.handler = async (event, context) => {
  const { httpMethod, path, body, headers } = event;
  
  // Proxy vers Railway backend
  const backendUrl = process.env.RAILWAY_BACKEND_URL;
  
  try {
    const response = await fetch(`${backendUrl}${path}`, {
      method: httpMethod,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': headers.authorization || '',
      },
      body: httpMethod !== 'GET' ? body : undefined,
    });
    
    const data = await response.text();
    
    return {
      statusCode: response.status,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Content-Type': 'application/json',
      },
      body: data,
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Proxy error' }),
    };
  }
};
```

---

## 🗄️ Configuration Supabase

### **1. Setup Supabase**

#### **Création du Projet**
1. Aller sur https://supabase.com
2. Créer un nouveau projet
3. Choisir la région la plus proche (Europe West)
4. Noter les credentials

#### **Configuration Base de Données**
```sql
-- Schéma ISMAIL Platform
CREATE SCHEMA IF NOT EXISTS ismail;

-- Table utilisateurs
CREATE TABLE ismail.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ismail_id VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    profile_type VARCHAR(20) NOT NULL,
    kyc_status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table portefeuilles
CREATE TABLE ismail.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES ismail.users(id),
    balance DECIMAL(15,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'XOF',
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table transactions
CREATE TABLE ismail.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID REFERENCES ismail.wallets(id),
    type VARCHAR(20) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    reference VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX idx_users_ismail_id ON ismail.users(ismail_id);
CREATE INDEX idx_users_email ON ismail.users(email);
CREATE INDEX idx_transactions_wallet_id ON ismail.transactions(wallet_id);
CREATE INDEX idx_transactions_created_at ON ismail.transactions(created_at);
```

#### **Row Level Security (RLS)**
```sql
-- Activer RLS
ALTER TABLE ismail.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ismail.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ismail.transactions ENABLE ROW LEVEL SECURITY;

-- Policies utilisateurs
CREATE POLICY "Users can view own data" ON ismail.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON ismail.users
    FOR UPDATE USING (auth.uid() = id);

-- Policies portefeuilles
CREATE POLICY "Users can view own wallet" ON ismail.wallets
    FOR SELECT USING (user_id = auth.uid());

-- Policies transactions
CREATE POLICY "Users can view own transactions" ON ismail.transactions
    FOR SELECT USING (
        wallet_id IN (
            SELECT id FROM ismail.wallets WHERE user_id = auth.uid()
        )
    );
```

### **2. Configuration Auth Supabase**
```javascript
// supabase-config.js
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
})
```

---

## 🚂 Configuration Railway

### **1. Setup Railway Backend**

#### **Déploiement Spring Boot**
```yaml
# railway.toml
[build]
  builder = "DOCKERFILE"
  buildCommand = "mvn clean package -DskipTests"

[deploy]
  startCommand = "java -jar target/auth-service-*.jar"
  healthcheckPath = "/actuator/health"
  healthcheckTimeout = 300
  restartPolicyType = "ON_FAILURE"
  restartPolicyMaxRetries = 3

[environments.production]
  [environments.production.variables]
    SPRING_PROFILES_ACTIVE = "production"
    SERVER_PORT = "8080"

[environments.staging]
  [environments.staging.variables]
    SPRING_PROFILES_ACTIVE = "staging"
    SERVER_PORT = "8080"
```

#### **Dockerfile Optimisé**
```dockerfile
# Dockerfile
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copier le JAR
COPY target/auth-service-*.jar app.jar

# Utilisateur non-root
RUN addgroup -g 1000 ismail && \
    adduser -D -s /bin/sh -u 1000 -G ismail ismail
USER ismail

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

### **2. Variables d'Environnement Railway**
```bash
# Base de données (Supabase)
DATABASE_URL=postgresql://user:pass@host:5432/db
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key

# Redis (Upstash)
REDIS_URL=redis://user:pass@host:port

# JWT
JWT_SECRET=your-jwt-secret

# Services externes
RESEND_API_KEY=your-resend-key
DISCORD_WEBHOOK_URL=your-discord-webhook

# Cloudinary
CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name
```

---

## 📧 Services Alternatifs

### **1. Resend (Alternative SendGrid)**

#### **Configuration**
```javascript
// resend-config.js
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export const sendEmail = async (to, subject, html) => {
  try {
    const data = await resend.emails.send({
      from: 'ISMAIL Platform <noreply@ismail-platform.com>',
      to: [to],
      subject: subject,
      html: html,
    });
    
    return { success: true, data };
  } catch (error) {
    return { success: false, error };
  }
};
```

### **2. Upstash Redis**

#### **Configuration**
```javascript
// upstash-config.js
import { Redis } from '@upstash/redis'

export const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
})

// Utilisation
await redis.set('key', 'value', { ex: 3600 }); // Expire en 1h
const value = await redis.get('key');
```

### **3. Cloudinary Storage**

#### **Configuration**
```javascript
// cloudinary-config.js
import { v2 as cloudinary } from 'cloudinary';

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export const uploadImage = async (file, folder = 'ismail') => {
  try {
    const result = await cloudinary.uploader.upload(file, {
      folder: folder,
      resource_type: 'auto',
      quality: 'auto',
      fetch_format: 'auto',
    });
    
    return { success: true, url: result.secure_url };
  } catch (error) {
    return { success: false, error };
  }
};
```

---

## 📊 Monitoring avec Better Stack

### **Configuration Logs**
```javascript
// better-stack-config.js
import { createLogger, format, transports } from 'winston';
import { Logtail } from '@logtail/node';

const logtail = new Logtail(process.env.BETTER_STACK_TOKEN);

export const logger = createLogger({
  level: 'info',
  format: format.combine(
    format.timestamp(),
    format.errors({ stack: true }),
    format.json()
  ),
  transports: [
    new transports.Console(),
    logtail.getWinstonTransport(),
  ],
});
```

---

## 💰 Estimation des Coûts

### **Stack Afrique vs AWS**
```yaml
Netlify:
  - Starter: Gratuit (100GB/mois)
  - Pro: $19/mois (1TB/mois)

Railway:
  - Hobby: $5/mois par service
  - Pro: $20/mois par service

Supabase:
  - Free: Gratuit (500MB DB, 50MB storage)
  - Pro: $25/mois (8GB DB, 100GB storage)

Upstash:
  - Free: 10,000 requêtes/jour
  - Pay-as-you-go: $0.2/100k requêtes

Total mensuel estimé:
  - Développement: $0-30/mois
  - Production: $50-100/mois

VS AWS:
  - Développement: $50-150/mois
  - Production: $200-500/mois
```

---

**🌍 Stack cloud optimisée pour l'Afrique de l'Ouest !**

*Accessible, performant et économique pour la région CEDEAO.*
