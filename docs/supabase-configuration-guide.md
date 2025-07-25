# 🗄️ Guide de Configuration Supabase - ISMAIL Platform

Guide détaillé pour configurer Supabase comme base de données principale pour la plateforme ISMAIL.

## 📋 Étapes de Configuration

### **1. Création du Projet Supabase**

#### **Accès à Supabase**
1. Aller sur https://supabase.com
2. Se connecter avec GitHub
3. Cliquer sur "New Project"

#### **Configuration du Projet**
```yaml
Nom du projet: ismail-platform
Organisation: Votre organisation
Région: Europe West (eu-west-1) # Plus proche de l'Afrique
Plan: Free (pour commencer)
```

#### **Configuration Base de Données**
```yaml
Nom de la base: postgres
Mot de passe: [Générer un mot de passe fort]
Version PostgreSQL: 15.x (dernière stable)
```

### **2. Récupération des Credentials**

#### **Dans Project Settings > API**
```bash
# URL du projet
SUPABASE_URL=https://your-project-id.supabase.co

# Clé publique (anon key)
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Clé de service (service_role key) - SENSIBLE !
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### **Dans Project Settings > Database**
```bash
# URL de connexion directe
DATABASE_URL=postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres

# Informations de connexion
Host: db.your-project-id.supabase.co
Port: 5432
Database: postgres
Username: postgres
Password: [votre mot de passe]
```

### **3. Exécution des Scripts SQL**

#### **Ordre d'Exécution**
```bash
1. database/supabase/01-schema.sql      # Schéma principal
2. database/supabase/02-functions.sql   # Fonctions et triggers
3. database/supabase/03-seed-data.sql   # Données de test
```

#### **Via l'Interface Supabase**
1. Aller dans **SQL Editor**
2. Créer un nouveau query
3. Copier-coller le contenu de `01-schema.sql`
4. Cliquer sur **Run**
5. Répéter pour les autres fichiers

#### **Via Supabase CLI (Recommandé)**
```bash
# Installer Supabase CLI
npm install -g @supabase/cli

# Se connecter
supabase login

# Lier le projet
supabase link --project-ref your-project-id

# Exécuter les migrations
supabase db push

# Ou exécuter manuellement
psql "postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres" \
  -f database/supabase/01-schema.sql

psql "postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres" \
  -f database/supabase/02-functions.sql

psql "postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres" \
  -f database/supabase/03-seed-data.sql
```

### **4. Configuration de l'Authentification**

#### **Dans Authentication > Settings**
```yaml
Site URL: https://ismail-platform.netlify.app
Redirect URLs:
  - https://ismail-platform.netlify.app/auth/callback
  - https://dev--ismail-platform.netlify.app/auth/callback
  - http://localhost:3000/auth/callback

JWT Expiry: 3600 (1 heure)
Refresh Token Expiry: 604800 (7 jours)

Email Confirmation: Enabled
Phone Confirmation: Enabled
```

#### **Configuration des Providers**
```yaml
Email Provider:
  - Enable Email Provider: ✓
  - Confirm Email: ✓
  - Secure Email Change: ✓

Phone Provider:
  - Enable Phone Provider: ✓
  - Confirm Phone: ✓
  - SMS Provider: Twilio (ou autre)
```

#### **Templates d'Emails**
```html
<!-- Confirmation Email -->
<h2>Bienvenue sur ISMAIL Platform</h2>
<p>Cliquez sur le lien ci-dessous pour confirmer votre email :</p>
<a href="{{ .ConfirmationURL }}">Confirmer mon email</a>

<!-- Reset Password -->
<h2>Réinitialisation de mot de passe</h2>
<p>Cliquez sur le lien ci-dessous pour réinitialiser votre mot de passe :</p>
<a href="{{ .ConfirmationURL }}">Réinitialiser mon mot de passe</a>
```

### **5. Configuration du Storage**

#### **Création des Buckets**
```sql
-- Dans SQL Editor
INSERT INTO storage.buckets (id, name, public) VALUES 
('avatars', 'avatars', true),
('documents', 'documents', false),
('professional-cards', 'professional-cards', false);
```

#### **Politiques de Storage**
```sql
-- Politique pour les avatars (public)
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'avatars' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Politique pour les documents (privé)
CREATE POLICY "Users can view own documents" ON storage.objects
FOR SELECT USING (
  bucket_id = 'documents' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can upload own documents" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'documents' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);
```

### **6. Configuration des Edge Functions**

#### **Fonction de Notification**
```typescript
// supabase/functions/send-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { type, recipient, data } = await req.json()
  
  // Logique d'envoi de notification
  // (Email via Resend, SMS, Push notification)
  
  return new Response(
    JSON.stringify({ success: true }),
    { headers: { "Content-Type": "application/json" } },
  )
})
```

#### **Fonction de Paiement**
```typescript
// supabase/functions/process-payment/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { amount, currency, method, user_id } = await req.json()
  
  // Intégration avec CinetPay, Wave, Orange Money
  
  return new Response(
    JSON.stringify({ transaction_id: "...", status: "pending" }),
    { headers: { "Content-Type": "application/json" } },
  )
})
```

### **7. Configuration des Webhooks**

#### **Webhook pour les Événements Auth**
```yaml
URL: https://ismail-backend.railway.app/webhooks/supabase/auth
Events:
  - user.created
  - user.updated
  - user.deleted
Secret: your-webhook-secret
```

#### **Webhook pour les Événements Database**
```yaml
URL: https://ismail-backend.railway.app/webhooks/supabase/database
Events:
  - INSERT on ismail.transactions
  - UPDATE on ismail.users
Secret: your-webhook-secret
```

### **8. Configuration des Extensions**

#### **Extensions Recommandées**
```sql
-- Dans SQL Editor
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";      -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";       -- Cryptographie
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements"; -- Statistiques
CREATE EXTENSION IF NOT EXISTS "pg_trgm";        -- Recherche floue
CREATE EXTENSION IF NOT EXISTS "unaccent";       -- Suppression accents
```

### **9. Monitoring et Performance**

#### **Configuration des Métriques**
```yaml
Dans Database > Logs:
- Activer Query Performance Insights
- Configurer les alertes de performance
- Monitorer les requêtes lentes

Dans Database > Extensions:
- Activer pg_stat_statements
- Configurer les métriques personnalisées
```

#### **Index de Performance**
```sql
-- Index composites pour les requêtes fréquentes
CREATE INDEX CONCURRENTLY idx_users_country_status 
ON ismail.users(country, status) WHERE status = 'ACTIVE';

CREATE INDEX CONCURRENTLY idx_transactions_user_date 
ON ismail.transactions(wallet_id, created_at DESC);

CREATE INDEX CONCURRENTLY idx_wallets_user_currency 
ON ismail.wallets(user_id, currency) WHERE status = 'ACTIVE';
```

### **10. Backup et Sécurité**

#### **Configuration des Backups**
```yaml
Dans Database > Backups:
- Backup automatique: Daily
- Rétention: 7 jours (Free plan)
- Point-in-time recovery: Activé
```

#### **Sécurité**
```yaml
Dans Database > Settings:
- SSL Mode: Require
- Connection Pooling: Transaction
- Max Connections: 60 (Free plan)

Dans Project Settings > General:
- Pause after inactivity: 1 week
- Custom domain: db.ismail-platform.com
```

### **11. Variables d'Environnement**

#### **Pour l'Application Frontend**
```bash
REACT_APP_SUPABASE_URL=https://your-project-id.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### **Pour l'Application Backend**
```bash
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
DATABASE_URL=postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres
```

### **12. Tests de Validation**

#### **Test de Connexion**
```bash
# Test avec psql
psql "postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres" \
  -c "SELECT version();"

# Test avec curl (API)
curl -X GET "https://your-project-id.supabase.co/rest/v1/users" \
  -H "apikey: your-anon-key" \
  -H "Authorization: Bearer your-anon-key"
```

#### **Test des Fonctions**
```sql
-- Test de génération d'ID ISMAIL
SELECT ismail.generate_ismail_id('CI', 'CLIENT');

-- Test d'inscription utilisateur
SELECT ismail.register_user(
  'test@example.com',
  '+2250123456789',
  'TestPassword123!',
  'Test',
  'User',
  'CLIENT',
  'CI'
);
```

### **13. Mise en Production**

#### **Checklist Pré-Production**
- [ ] ✅ Tous les scripts SQL exécutés
- [ ] ✅ RLS activé sur toutes les tables
- [ ] ✅ Politiques de sécurité configurées
- [ ] ✅ Backups automatiques activés
- [ ] ✅ Monitoring configuré
- [ ] ✅ Variables d'environnement sécurisées
- [ ] ✅ Tests de charge effectués

#### **Migration vers Plan Payant**
```yaml
Quand migrer:
- > 500MB de données
- > 2GB de bande passante/mois
- Besoin de plus de 60 connexions simultanées
- Backup avec rétention > 7 jours

Plan Pro ($25/mois):
- 8GB de base de données
- 250GB de bande passante
- 200 connexions simultanées
- Backup 30 jours
```

---

## ✅ **Résumé Configuration**

### **Credentials à Récupérer**
```bash
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_KEY=eyJ...
DATABASE_URL=postgresql://postgres:password@db.your-project-id.supabase.co:5432/postgres
```

### **Prochaines Étapes**
1. ✅ Exécuter les scripts SQL
2. ✅ Configurer l'authentification
3. ✅ Tester les fonctions
4. ✅ Configurer les webhooks
5. ✅ Intégrer avec Railway backend

**🗄️ Supabase configuré pour l'Afrique de l'Ouest !**

*Base de données PostgreSQL managée avec authentification intégrée.*
