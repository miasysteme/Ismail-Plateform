# Script PowerShell de test de connexion Supabase pour ISMAIL Platform
# Teste la connectivité API et base de données

param(
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\scripts\test-supabase-connection.ps1"
    Write-Host ""
    Write-Host "Teste la connexion à Supabase pour ISMAIL Platform."
    Write-Host ""
    Write-Host "Ce script teste:"
    Write-Host "  - Connexion API REST"
    Write-Host "  - Connexion API Auth"
    Write-Host "  - Configuration Supabase"
    Write-Host ""
    Write-Host "Prérequis:"
    Write-Host "  - Credentials Supabase dans .secrets/africa-secrets.env"
    Write-Host "  - PowerShell 5.1+"
    exit 0
}

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SecretsFile = Join-Path $ProjectRoot ".secrets\africa-secrets.env"

# Fonctions utilitaires
function Write-Info {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param($Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Charger les secrets depuis le fichier .env
function Load-Secrets {
    Write-Info "Chargement des secrets..."
    
    if (-not (Test-Path $SecretsFile)) {
        Write-Error "Fichier secrets non trouvé: $SecretsFile"
        exit 1
    }
    
    $secrets = @{}
    Get-Content $SecretsFile | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $secrets[$key] = $value
        }
    }
    
    # Variables globales
    $global:SUPABASE_URL = $secrets['SUPABASE_URL']
    $global:SUPABASE_ANON_KEY = $secrets['SUPABASE_ANON_KEY']
    $global:SUPABASE_SERVICE_KEY = $secrets['SUPABASE_SERVICE_KEY']
    $global:DATABASE_URL = $secrets['DATABASE_URL']
    $global:SUPABASE_PROJECT_ID = $secrets['SUPABASE_PROJECT_ID']
    
    if (-not $global:SUPABASE_URL) {
        Write-Error "SUPABASE_URL non trouvé dans les secrets"
        exit 1
    }
    
    Write-Success "Secrets chargés avec succès"
}

# Tester la connexion API Supabase
function Test-ApiConnection {
    Write-Info "=== Test Connexion API Supabase ==="
    
    # Test API REST
    Write-Info "Test de l'API REST..."
    
    try {
        $headers = @{
            'apikey' = $global:SUPABASE_ANON_KEY
            'Authorization' = "Bearer $($global:SUPABASE_ANON_KEY)"
        }
        
        $response = Invoke-RestMethod -Uri "$($global:SUPABASE_URL)/rest/v1/" -Headers $headers -Method Get -TimeoutSec 10
        Write-Success "✓ API REST accessible"
        Write-Info "Réponse: $($response | ConvertTo-Json -Compress | Substring(0, [Math]::Min(100, $_.Length)))..."
    }
    catch {
        Write-Error "✗ API REST non accessible: $($_.Exception.Message)"
        return $false
    }
    
    # Test API Auth
    Write-Info "Test de l'API Auth..."
    
    try {
        $authHeaders = @{
            'apikey' = $global:SUPABASE_ANON_KEY
        }
        
        $authResponse = Invoke-RestMethod -Uri "$($global:SUPABASE_URL)/auth/v1/settings" -Headers $authHeaders -Method Get -TimeoutSec 10
        Write-Success "✓ API Auth accessible"
    }
    catch {
        Write-Error "✗ API Auth non accessible: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

# Afficher les informations de configuration
function Show-Configuration {
    Write-Info "=== Configuration Supabase ==="
    
    Write-Host ""
    Write-Host "🔗 URLs:" -ForegroundColor Cyan
    Write-Host "  - Projet: $($global:SUPABASE_URL)"
    Write-Host "  - Dashboard: https://supabase.com/dashboard/project/$($global:SUPABASE_PROJECT_ID)"
    Write-Host "  - SQL Editor: https://supabase.com/dashboard/project/$($global:SUPABASE_PROJECT_ID)/sql"
    Write-Host ""
    Write-Host "🔑 Credentials:" -ForegroundColor Cyan
    Write-Host "  - Project ID: $($global:SUPABASE_PROJECT_ID)"
    Write-Host "  - Anon Key: $($global:SUPABASE_ANON_KEY.Substring(0, 20))..."
    Write-Host "  - Service Key: $($global:SUPABASE_SERVICE_KEY.Substring(0, 20))..."
    Write-Host ""
}

# Tester la création d'un utilisateur via API
function Test-UserCreation {
    Write-Info "=== Test Création Utilisateur (API) ==="
    
    try {
        $headers = @{
            'apikey' = $global:SUPABASE_SERVICE_KEY
            'Authorization' = "Bearer $($global:SUPABASE_SERVICE_KEY)"
            'Content-Type' = 'application/json'
        }
        
        $testEmail = "test-$(Get-Date -Format 'yyyyMMddHHmmss')@ismail-platform.com"
        $userData = @{
            email = $testEmail
            password = "TestPassword123!"
            email_confirm = $true
        } | ConvertTo-Json
        
        Write-Info "Tentative de création d'utilisateur test: $testEmail"
        
        $response = Invoke-RestMethod -Uri "$($global:SUPABASE_URL)/auth/v1/admin/users" -Headers $headers -Method Post -Body $userData -TimeoutSec 10
        
        if ($response.id) {
            Write-Success "✓ Utilisateur test créé avec succès"
            Write-Info "ID utilisateur: $($response.id)"
            
            # Supprimer l'utilisateur test
            try {
                Invoke-RestMethod -Uri "$($global:SUPABASE_URL)/auth/v1/admin/users/$($response.id)" -Headers $headers -Method Delete -TimeoutSec 10
                Write-Info "Utilisateur test supprimé"
            }
            catch {
                Write-Warning "Impossible de supprimer l'utilisateur test: $($_.Exception.Message)"
            }
        }
        else {
            Write-Warning "Utilisateur créé mais pas d'ID retourné"
        }
    }
    catch {
        Write-Error "✗ Erreur lors de la création d'utilisateur: $($_.Exception.Message)"
        return $false
    }
    
    return $true
}

# Fonction principale
function Main {
    Write-Host "🧪 Test Connexion Supabase - ISMAIL Platform" -ForegroundColor Magenta
    Write-Host "===========================================" -ForegroundColor Magenta
    Write-Host ""
    
    Load-Secrets
    Show-Configuration
    
    $apiSuccess = Test-ApiConnection
    $userSuccess = Test-UserCreation
    
    Write-Host ""
    if ($apiSuccess -and $userSuccess) {
        Write-Success "🎉 Tous les tests de connexion Supabase réussis !"
        Write-Host ""
        Write-Host "📋 Prochaines étapes:" -ForegroundColor Cyan
        Write-Host "  1. Configurer le schéma de base de données via l'interface Supabase"
        Write-Host "  2. Ou utiliser les scripts SQL dans database/supabase/"
        Write-Host "  3. Puis configurer Railway backend"
        Write-Host "  4. Enfin déployer sur Netlify"
    }
    else {
        Write-Error "❌ Certains tests ont échoué"
        Write-Host ""
        Write-Host "🔧 Actions recommandées:" -ForegroundColor Yellow
        Write-Host "  1. Vérifier les credentials Supabase"
        Write-Host "  2. Vérifier la connectivité internet"
        Write-Host "  3. Consulter la documentation Supabase"
    }
    
    Write-Host ""
}

# Exécuter le script
Main
