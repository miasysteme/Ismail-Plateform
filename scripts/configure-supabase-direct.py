#!/usr/bin/env python3
"""
Script Python pour configurer Supabase directement via API
Configure le schéma ISMAIL Platform avec vos credentials
"""

import requests
import json
import sys
import time
from urllib.parse import quote

# Configuration Supabase
SUPABASE_URL = "https://xfuehgxhcktleaofhxfy.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmdWVoZ3hoY2t0bGVhb2ZoeGZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MDQ0OTYsImV4cCI6MjA2NjA4MDQ5Nn0.GspiDxi10z_El1fT28SL8pS1ZDzCXeEiNcIDUDXDfJ0"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmdWVoZ3hoY2t0bGVhb2ZoeGZ5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDUwNDQ5NiwiZXhwIjoyMDY2MDgwNDk2fQ.rx0GQaABWjzmt83bD-DU0asaNxriSGsVX2WsxZytWMk"
PROJECT_ID = "xfuehgxhcktleaofhxfy"

def log_info(message):
    print(f"[INFO] {message}")

def log_success(message):
    print(f"[SUCCESS] ✓ {message}")

def log_error(message):
    print(f"[ERROR] ✗ {message}")

def log_warning(message):
    print(f"[WARNING] ⚠ {message}")

def test_api_connection():
    """Test la connexion à l'API Supabase"""
    log_info("Test de connexion à l'API Supabase...")
    
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}'
    }
    
    try:
        response = requests.get(f"{SUPABASE_URL}/rest/v1/", headers=headers, timeout=10)
        if response.status_code == 200:
            log_success("API REST accessible")
            return True
        else:
            log_error(f"API REST non accessible (HTTP {response.status_code})")
            return False
    except Exception as e:
        log_error(f"Erreur de connexion API: {e}")
        return False

def test_auth_api():
    """Test l'API d'authentification"""
    log_info("Test de l'API Auth...")
    
    headers = {
        'apikey': SUPABASE_ANON_KEY
    }
    
    try:
        response = requests.get(f"{SUPABASE_URL}/auth/v1/settings", headers=headers, timeout=10)
        if response.status_code == 200:
            log_success("API Auth accessible")
            return True
        else:
            log_error(f"API Auth non accessible (HTTP {response.status_code})")
            return False
    except Exception as e:
        log_error(f"Erreur de connexion Auth: {e}")
        return False

def execute_sql_via_api(sql_query, description=""):
    """Exécute une requête SQL via l'API Supabase"""
    if description:
        log_info(f"Exécution: {description}")
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Utiliser l'API RPC pour exécuter du SQL brut
    payload = {
        'query': sql_query
    }
    
    try:
        # Note: Supabase n'expose pas directement d'endpoint pour SQL brut via REST
        # Nous devrons utiliser une approche différente
        log_warning("L'API REST Supabase ne permet pas l'exécution directe de SQL")
        log_info("Utilisation recommandée: Interface web SQL Editor")
        return False
    except Exception as e:
        log_error(f"Erreur lors de l'exécution SQL: {e}")
        return False

def check_existing_schema():
    """Vérifie si le schéma ISMAIL existe déjà"""
    log_info("Vérification du schéma existant...")
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}'
    }
    
    try:
        # Essayer d'accéder à une table du schéma ismail
        response = requests.get(f"{SUPABASE_URL}/rest/v1/users?limit=1", headers=headers, timeout=10)
        
        if response.status_code == 200:
            log_success("Schéma ISMAIL déjà configuré")
            data = response.json()
            log_info(f"Nombre d'utilisateurs existants: {len(data)}")
            return True
        elif response.status_code == 404:
            log_info("Schéma ISMAIL pas encore configuré")
            return False
        else:
            log_warning(f"Statut inattendu: {response.status_code}")
            return False
    except Exception as e:
        log_info("Schéma ISMAIL pas encore configuré (normal)")
        return False

def create_test_user():
    """Crée un utilisateur de test via l'API Auth"""
    log_info("Création d'un utilisateur de test...")
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json'
    }
    
    test_email = f"test-{int(time.time())}@ismail-platform.com"
    user_data = {
        'email': test_email,
        'password': 'TestPassword123!',
        'email_confirm': True
    }
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/auth/v1/admin/users",
            headers=headers,
            json=user_data,
            timeout=10
        )
        
        if response.status_code == 200 or response.status_code == 201:
            user = response.json()
            log_success(f"Utilisateur test créé: {test_email}")
            log_info(f"ID utilisateur: {user.get('id', 'N/A')}")
            
            # Supprimer l'utilisateur test
            if 'id' in user:
                delete_response = requests.delete(
                    f"{SUPABASE_URL}/auth/v1/admin/users/{user['id']}",
                    headers=headers,
                    timeout=10
                )
                if delete_response.status_code == 200:
                    log_info("Utilisateur test supprimé")
                else:
                    log_warning("Impossible de supprimer l'utilisateur test")
            
            return True
        else:
            log_error(f"Erreur création utilisateur: {response.status_code}")
            log_error(f"Réponse: {response.text}")
            return False
    except Exception as e:
        log_error(f"Erreur lors de la création d'utilisateur: {e}")
        return False

def setup_storage_buckets():
    """Configure les buckets de storage"""
    log_info("Configuration des buckets de storage...")
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json'
    }
    
    buckets = [
        {'id': 'avatars', 'name': 'avatars', 'public': True},
        {'id': 'documents', 'name': 'documents', 'public': False},
        {'id': 'professional-cards', 'name': 'professional-cards', 'public': False}
    ]
    
    for bucket in buckets:
        try:
            response = requests.post(
                f"{SUPABASE_URL}/storage/v1/bucket",
                headers=headers,
                json=bucket,
                timeout=10
            )
            
            if response.status_code == 200 or response.status_code == 201:
                log_success(f"Bucket '{bucket['id']}' créé")
            elif response.status_code == 409:
                log_info(f"Bucket '{bucket['id']}' existe déjà")
            else:
                log_warning(f"Erreur bucket '{bucket['id']}': {response.status_code}")
        except Exception as e:
            log_error(f"Erreur création bucket '{bucket['id']}': {e}")

def display_configuration_guide():
    """Affiche le guide de configuration manuelle"""
    print("\n" + "="*60)
    print("📋 GUIDE DE CONFIGURATION MANUELLE SUPABASE")
    print("="*60)
    
    print(f"""
🔗 URLs importantes:
  - Dashboard: https://supabase.com/dashboard/project/{PROJECT_ID}
  - SQL Editor: https://supabase.com/dashboard/project/{PROJECT_ID}/sql
  - Table Editor: https://supabase.com/dashboard/project/{PROJECT_ID}/editor
  - Auth Settings: https://supabase.com/dashboard/project/{PROJECT_ID}/auth/settings

📝 Étapes de configuration:

1. SCHÉMA DE BASE DE DONNÉES:
   - Aller sur: https://supabase.com/dashboard/project/{PROJECT_ID}/sql
   - Créer une nouvelle requête
   - Copier le contenu de: database/supabase/01-schema.sql
   - Exécuter la requête
   - Répéter pour: 02-functions.sql et 03-seed-data.sql

2. AUTHENTIFICATION:
   - Aller sur: https://supabase.com/dashboard/project/{PROJECT_ID}/auth/settings
   - Site URL: https://ismail-platform.netlify.app
   - Redirect URLs: https://ismail-platform.netlify.app/auth/callback
   - Activer Email confirmation

3. STORAGE:
   - Les buckets seront créés automatiquement si possible
   - Sinon, créer manuellement: avatars, documents, professional-cards

4. VÉRIFICATION:
   - Aller sur: https://supabase.com/dashboard/project/{PROJECT_ID}/editor
   - Vérifier que le schéma 'ismail' existe avec 6 tables
   - Tester l'authentification
""")

def main():
    """Fonction principale"""
    print("🗄️ Configuration Supabase - ISMAIL Platform")
    print("=" * 50)
    print()
    
    # Tests de connectivité
    api_ok = test_api_connection()
    auth_ok = test_auth_api()
    
    if not (api_ok and auth_ok):
        log_error("Problème de connectivité Supabase")
        return False
    
    # Vérification du schéma existant
    schema_exists = check_existing_schema()
    
    # Test de création d'utilisateur
    user_test_ok = create_test_user()
    
    # Configuration des buckets
    setup_storage_buckets()
    
    # Affichage du guide
    display_configuration_guide()
    
    print("\n" + "="*50)
    if api_ok and auth_ok and user_test_ok:
        log_success("🎉 Supabase opérationnel et prêt pour la configuration !")
        print("\n📋 Actions recommandées:")
        print("  1. Configurer le schéma via l'interface web (voir guide ci-dessus)")
        print("  2. Configurer Railway backend")
        print("  3. Déployer sur Netlify")
    else:
        log_error("❌ Problèmes détectés avec Supabase")
    
    return True

if __name__ == "__main__":
    main()
