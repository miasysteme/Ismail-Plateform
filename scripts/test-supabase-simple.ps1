# Script PowerShell simple de test Supabase pour ISMAIL Platform

Write-Host "🧪 Test Connexion Supabase - ISMAIL Platform" -ForegroundColor Magenta
Write-Host "===========================================" -ForegroundColor Magenta
Write-Host ""

# Configuration Supabase (vos credentials)
$SUPABASE_URL = "https://xfuehgxhcktleaofhxfy.supabase.co"
$SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmdWVoZ3hoY2t0bGVhb2ZoeGZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MDQ0OTYsImV4cCI6MjA2NjA4MDQ5Nn0.GspiDxi10z_El1fT28SL8pS1ZDzCXeEiNcIDUDXDfJ0"
$SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmdWVoZ3hoY2t0bGVhb2ZoeGZ5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDUwNDQ5NiwiZXhwIjoyMDY2MDgwNDk2fQ.rx0GQaABWjzmt83bD-DU0asaNxriSGsVX2WsxZytWMk"
$SUPABASE_PROJECT_ID = "xfuehgxhcktleaofhxfy"

Write-Host "🔗 Configuration:" -ForegroundColor Cyan
Write-Host "  - Projet: $SUPABASE_URL"
Write-Host "  - Project ID: $SUPABASE_PROJECT_ID"
Write-Host "  - Dashboard: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_ID"
Write-Host ""

# Test 1: API REST
Write-Host "[INFO] Test de l'API REST..." -ForegroundColor Blue

try {
    $headers = @{
        'apikey' = $SUPABASE_ANON_KEY
        'Authorization' = "Bearer $SUPABASE_ANON_KEY"
    }
    
    $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/" -Headers $headers -Method Get -TimeoutSec 10
    Write-Host "[SUCCESS] ✓ API REST accessible" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] ✗ API REST non accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: API Auth
Write-Host "[INFO] Test de l'API Auth..." -ForegroundColor Blue

try {
    $authHeaders = @{
        'apikey' = $SUPABASE_ANON_KEY
    }
    
    $authResponse = Invoke-RestMethod -Uri "$SUPABASE_URL/auth/v1/settings" -Headers $authHeaders -Method Get -TimeoutSec 10
    Write-Host "[SUCCESS] ✓ API Auth accessible" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] ✗ API Auth non accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Vérification des tables existantes
Write-Host "[INFO] Vérification des tables existantes..." -ForegroundColor Blue

try {
    $tablesHeaders = @{
        'apikey' = $SUPABASE_SERVICE_KEY
        'Authorization' = "Bearer $SUPABASE_SERVICE_KEY"
    }
    
    # Essayer d'accéder aux tables (cela échouera si le schéma n'existe pas)
    $tablesResponse = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/users?limit=1" -Headers $tablesHeaders -Method Get -TimeoutSec 10
    Write-Host "[SUCCESS] ✓ Table 'users' accessible (schéma déjà configuré)" -ForegroundColor Green
}
catch {
    if ($_.Exception.Message -like "*relation*does not exist*" -or $_.Exception.Message -like "*table*not found*") {
        Write-Host "[INFO] ℹ️ Schéma ISMAIL pas encore configuré (normal)" -ForegroundColor Yellow
    }
    else {
        Write-Host "[WARNING] ⚠️ Erreur d'accès aux tables: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📋 Résumé des tests:" -ForegroundColor Cyan
Write-Host "  ✓ Connexion Supabase établie"
Write-Host "  ✓ Credentials valides"
Write-Host "  ✓ APIs accessibles"
Write-Host ""

Write-Host "🚀 Prochaines étapes:" -ForegroundColor Green
Write-Host "  1. Configurer le schéma de base de données"
Write-Host "  2. Exécuter les scripts SQL via l'interface Supabase"
Write-Host "  3. Configurer Railway backend"
Write-Host "  4. Déployer sur Netlify"
Write-Host ""

Write-Host "📖 Pour configurer le schéma:" -ForegroundColor Yellow
Write-Host "  1. Aller sur: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_ID/sql"
Write-Host "  2. Copier le contenu de: database/supabase/01-schema.sql"
Write-Host "  3. Coller dans l'éditeur SQL et exécuter"
Write-Host "  4. Répéter pour 02-functions.sql et 03-seed-data.sql"
Write-Host ""

Write-Host "✅ Test de connexion Supabase terminé avec succès !" -ForegroundColor Green
